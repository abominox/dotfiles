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

    set -l prompt (string join " " $argv)
    if test -z "$prompt"
        echo "Usage: poirot <prompt>" >&2
        return 1
    end

    set -l escaped_prompt (echo "$prompt" | jq -Rs .)
    set -l payload '{"model":"google/gemini-2.5-flash","messages":[{"role":"user","content":'"$escaped_prompt"'}],"stream":true}'

    # Stream SSE events line by line
    # For each line, extract content and print directly (no variable capture = no newline splitting)
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
                # Pipe raw JSON through jq to stdout (avoids Fish variable splitting on newlines)
                echo "$data" | jq -j --unbuffered -r '
                    select(.choices[0].delta.content != null)
                    | .choices[0].delta.content
                ' 2>/dev/null
            end
        end
    end

    echo
end