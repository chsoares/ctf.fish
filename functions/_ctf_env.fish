function _ctf_env
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    if contains -- -h $argv; or contains -- --help $argv
        ctf_info "Usage: ctf env [set <var> <value> | edit]"
        return 0
    end

    if not set -q CTF_LAB; or test -z "$CTF_LAB"
        ctf_error "CTF_LAB is not set."
        return 1
    end

    # 0. Load global env if not already loaded
    if test -f $CTF_LAB/env.fish
        source $CTF_LAB/env.fish
    else
        ctf_error "No global env.fish found. Are you in a CTF session?"
        return 1
    end

    if not set -q boxpwd; or not test -f $boxpwd/env.fish
        ctf_error "Box env.fish not found."
        return 1
    end
    set -l boxenv $boxpwd/env.fish

    # ctf env
    if test (count $argv) -eq 0
        ctf_info "Current env variables:"
        cat $CTF_LAB/env.fish | while read -l line
            if test -n "$line"; and string match -q "set -gx *" $line
                set -l parts (string split " " $line)
                if test (count $parts) -ge 4
                    set -l var $parts[3]
                    set -l value $parts[4..-1]
                    echo "$var -> $value"
                end
            end
        end
        return 0
    end

    switch $argv[1]

        # ctf env set
        case set
            if test (count $argv) -ne 3
                ctf_error "Usage: ctf env set <var> <value>"
                return 1
            end
            set -l var $argv[2]
            set -l value $argv[3]

            if not string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $var
                ctf_error "Invalid variable name: $var"
                return 1
            end

            set -l line
            if test -n "$value"
                set line "set -gx $var "(string escape -- "$value")
            else
                set line "set -gx $var ''"
            end

            # Rewrite the box env line-by-line to avoid sed delimiter issues.
            set -l tmp (mktemp)
            set -l found 0
            while read -l l
                if string match -q "set -gx $var *" -- $l
                    printf '%s\n' $line >> $tmp
                    set found 1
                else
                    printf '%s\n' $l >> $tmp
                end
            end < $boxenv
            if test $found -eq 0
                printf '%s\n' $line >> $tmp
            end
            mv $tmp $boxenv

            if test $found -eq 1
                ctf_info "Updated $var in $boxenv"
            else
                ctf_info "Added $var to $boxenv"
            end

            if not cp $boxenv $CTF_LAB/env.fish
                ctf_error "Failed to update $CTF_LAB/env.fish"
                return 1
            end
            source $CTF_LAB/env.fish
            ctf_info "Updated global env.fish"

        # ctf env edit
        case edit
            if not command -v gnome-text-editor >/dev/null 2>&1
                ctf_error "gnome-text-editor not found."
                return 1
            end

            if test -f $boxenv
                gnome-text-editor $boxenv
                if test $status -ne 0
                    ctf_error "Editor exited with an error."
                    return 1
                end
                if not cp $boxenv $CTF_LAB/env.fish
                    ctf_error "Failed to update $CTF_LAB/env.fish"
                    return 1
                end
                source $CTF_LAB/env.fish
                ctf_info "Edited $boxenv and updated global env."
            else
                ctf_error "$boxenv not found."
                return 1
            end
        case '*'
            ctf_error "Invalid command. Use 'set', 'edit', or no arguments to print current env."
            return 1
    end
end
