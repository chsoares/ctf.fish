function _ctf_creds
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    if contains -- -h $argv; or contains -- --help $argv
        ctf_info "Usage: ctf creds <user> <password> | ctf creds <user:password>"
        return 0
    end

    # Check if we're in a box environment
    if not set -q boxpwd; or not test -d "$boxpwd"
        ctf_error "Not in a CTF box environment. Run 'ctf start <boxname> <ip>' first."
        return 1
    end

    set -l creds_file "$boxpwd/creds.txt"

    # Show credentials if no arguments provided
    if test (count $argv) -eq 0
        if test -f "$creds_file"
            ctf_info "Current credentials:"
            cat "$creds_file" | while read -l line
                if test -n "$line"
                    set -l display_user (string split -m 1 ":" $line)[1]
                    set -l display_pass (string split -m 1 ":" $line)[2]
                    echo "$display_user : $display_pass"
                end
            end
        else
            ctf_info "No credentials file found at $creds_file"
        end
        return 0
    end

    set -l user_pass

    # Handle different input formats
    if test (count $argv) -eq 1
        # Single argument format: user:password
        set user_pass $argv[1]
        if not string match -q "*:*" $user_pass
            ctf_error "Single argument must be in format 'user:password'"
            return 1
        end
    else if test (count $argv) -eq 2
        # Two argument format: user password (empty password is allowed)
        set user_pass "$argv[1]:$argv[2]"
    else
        ctf_error "Too many arguments. Usage: ctf creds <user> <password> OR ctf creds <user:password>"
        return 1
    end

    set -l user (string split -m 1 ":" $user_pass)[1]
    if test -z "$user"
        ctf_error "Username is required"
        return 1
    end

    if test -f "$creds_file"; and grep -qxF -- "$user_pass" "$creds_file"
        ctf_warn "Credentials for '$user' already present in $creds_file"
    else
        if not printf '%s\n' "$user_pass" >> "$creds_file"
            ctf_error "Failed to write to $creds_file"
            return 1
        end
        chmod 600 "$creds_file" 2>/dev/null
        ctf_success "Added credentials for user '$user' to $creds_file"
    end

    # Show current contents
    ctf_info "Current credentials:"
    cat "$creds_file" | while read -l line
        if test -n "$line"
            set -l display_user (string split -m 1 ":" $line)[1]
            set -l display_pass (string split -m 1 ":" $line)[2]
            echo "$display_user : $display_pass"
        end
    end
end
