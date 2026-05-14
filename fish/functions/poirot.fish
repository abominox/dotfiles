function poirot --description "Quick AI help from the terminal, streaming to stdout"
    set -l api_key
    if set -q OPENROUTER_API_KEY
        set api_key $OPENROUTER_API_KEY
    else if test -f ~/.pi/agent/auth.json
        set api_key (jq -r '.openrouter.key // empty' ~/.pi/agent/auth.json)
    end

    if test -z "$api_key"
        echo "Error: No OpenRouter API key found. Set OPENROUTER_API_KEY or login via Pi." >&2
        return 1
    end

    # Parse flags
    set -l history_count 50
    set -l render_mode 0
    set -l prompt_args

    for arg in $argv
        switch "$arg"
            case '--render'
                set render_mode 1
            case '--no-history'
                set history_count 0
            case '--history=*'
                set history_count (string replace -r '^--history=' '' -- "$arg")
            case '-h' '--help'
                echo "Usage: poirot [--history=N] [--no-history] [--render] <prompt>"
                echo ""
                echo "Options:"
                echo "  --history=N    Include last N commands from terminal history (default: 50)"
                echo "  --no-history   Disable history context"
                echo "  --render       Buffer full response and render via glow"
                echo "  -h, --help     Show this help"
                return 0
            case '*'
                set -a prompt_args "$arg"
        end
    end

    set -l prompt (string join " " $prompt_args)
    if test -z "$prompt"
        echo "Usage: poirot [--history=N] [--no-history] [--render] <prompt>" >&2
        return 1
    end

    # Build messages array
    set -l messages

    # Add history as context (default: 50, disable with --no-history)
    if test "$history_count" -gt 0
        set -l history_lines (history --max=$history_count --null 2>/dev/null | string split0)
        if set -q history_lines[1]
            set -l history_text ""
            for line in $history_lines
                if test -n "$line"
                    set history_text "$history_text$line\n"
                end
            end
            set -l escaped_history (echo -n "$history_text" | jq -Rs .)
            set -a messages '{"role":"system","content":"Here is the users recent shell history. Only use this as context if it is relevant to the question. Ignore it otherwise.\nHistory:\n'"$escaped_history"'"}'
        end
    end

    # Add user message
    set -l escaped_prompt (echo "$prompt" | jq -Rs .)
    set -a messages '{"role":"user","content":'"$escaped_prompt"'}'

    # Build messages JSON array
    set -l messages_json "["
    set -l first 1
    for msg in $messages
        if test "$first" -eq 1
            set first 0
        else
            set messages_json "$messages_json,"
        end
        set messages_json "$messages_json$msg"
    end
    set messages_json "$messages_json]"

    set -l payload '{"model":"google/gemini-2.5-flash","messages":'"$messages_json"',"stream":true}'

    if test "$render_mode" -eq 1
        # Buffer mode: collect all output, then render with glow
        if not type -q glow
            echo "Warning: glow not installed. Falling back to raw output." >&2
            set render_mode 0
        else
            set -l buffer ""
            curl -s --no-buffer \
                -H "Authorization: Bearer $api_key" \
                -H "Content-Type: application/json" \
                -H "HTTP-Referer: https://github.com/abominox/dotfiles" \
                -d "$payload" \
                https://openrouter.ai/api/v1/chat/completions \
            | while read -l line
                if string match -q "data: *" -- "$line"
                    set -l data (string replace -r '^data: ' '' -- "$line")
                    if test "$data" != "[DONE]"
                        set -l token (echo "$data" | jq -j --unbuffered -r '
                            select(.choices[0].delta.content != null)
                            | .choices[0].delta.content
                        ' 2>/dev/null)
                        set buffer "$buffer$token"
                    end
                end
            end
            echo "$buffer" | glow -s dark -
            return 0
        end
    end

    # Streaming mode (default)
    curl -s --no-buffer \
        -H "Authorization: Bearer $api_key" \
        -H "Content-Type: application/json" \
        -H "HTTP-Referer: https://github.com/abominox/dotfiles" \
        -d "$payload" \
        https://openrouter.ai/api/v1/chat/completions \
    | while read -l line
        if string match -q "data: *" -- "$line"
            set -l data (string replace -r '^data: ' '' -- "$line")
            if test "$data" != "[DONE]"
                echo "$data" | jq -j --unbuffered -r '
                    select(.choices[0].delta.content != null)
                    | .choices[0].delta.content
                ' 2>/dev/null
            end
        end
    end

    echo
end
