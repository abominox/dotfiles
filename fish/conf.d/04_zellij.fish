# Auto-rename Zellij tabs to the running process (tmux automatic-rename style).
if set -q ZELLIJ
    function __zellij_tab_preexec --on-event fish_preexec
        set -l raw $argv
        set -l cmd (string split -f1 ' ' -- $raw)
        # Strip env assignments: FOO=bar vim → vim
        while string match -qr '^[A-Za-z_][A-Za-z0-9_]*=' -- $cmd
            set raw (string split -m1 ' ' -- $raw)[2]
            set cmd (string split -f1 ' ' -- $raw)
        end
        set -l name (basename -- $cmd)
        command zellij action rename-tab "$name" 2>/dev/null
    end

    function __zellij_tab_postexec --on-event fish_postexec
        command zellij action rename-tab fish 2>/dev/null
    end

    function __zellij_tab_prompt --on-event fish_prompt
        # Ensure new tabs get a real name instead of "Tab #N"
        command zellij action rename-tab fish 2>/dev/null
    end
end

# Numbered sessions (tmux-style): find next available number, create session with it.
if not set -q ZELLIJ
    function zellij --wraps=zellij
        set -l next (command zellij list-sessions -ns 2>/dev/null | grep -E '^[0-9]+$' | sort -n | tail -1)
        if test -z "$next"
            set next 0
        else
            set next (math $next + 1)
        end
        command zellij --session $next $argv
    end
end
