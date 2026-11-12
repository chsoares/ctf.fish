function __ctf_creds_parse --argument-names line
    # Print user<TAB>domain<TAB>secret. Domain is empty for legacy entries.
    set -l parts (string split -m1 ':' -- $line)
    test (count $parts) -ge 1; or return
    set -l identity $parts[1]
    set -l secret ""
    if test (count $parts) -gt 1
        set secret $parts[2]
    end

    set -l user $identity
    set -l domain ""
    if string match -q '*@*' -- $identity
        set user (string split -m1 '@' -- $identity)[1]
        set domain (string split -m1 '@' -- $identity)[2]
    else if string match -rq '\\\\' -- $identity
        set domain (string split -m1 '\\' -- $identity)[1]
        set user (string split -m1 '\\' -- $identity)[2]
    end

    if test -n "$user"
        printf '%s\t%s\t%s\n' "$user" "$domain" "$secret"
    end
end

function __ctf_creds_show --argument-names file filter
    if not test -f "$file"
        if test -n "$filter"
            ctf_info "No known credentials for $filter."
        else
            ctf_info "No known credentials."
        end
        return
    end

    set -l tmp (mktemp)
    while read -l line
        set line (string trim -- $line)
        test -z "$line"; and continue
        string match -q '#*' -- $line; and continue

        set -l parsed (__ctf_creds_parse $line)
        test -n "$parsed"; or continue
        set -l parts (string split \t -- $parsed)
        set -l user $parts[1]
        set -l domain $parts[2]
        set -l secret $parts[3]

        set -l group $domain
        set -l host ""
        if test "$domain" = local
            set group local
        else if string match -q 'local.*' -- $domain
            set group local
            set host (string replace -- 'local.' '' $domain)
        else if test -z "$domain"
            set group "(no domain)"
        end

        if test -n "$filter"
            if test "$filter" = local
                test "$group" = local; or continue
            else if string match -q 'local.*' -- $filter
                test "$domain" = "$filter"; or continue
            else
                test "$domain" = "$filter"; or continue
            end
        end

        printf '%s\t%s\t%s\t%s\n' "$group" "$user" "$secret" "$host" >> $tmp
    end < $file

    if not test -s $tmp
        if test -n "$filter"
            ctf_info "No known credentials for $filter."
        else
            ctf_info "No known credentials."
        end
        rm -f $tmp
        return
    end

    ctf_header "Current known credentials:"
    sort $tmp | while read -l entry
        set -l fields (string split \t -- $entry)
        set -l group $fields[1]
        set -l user $fields[2]
        set -l secret $fields[3]
        set -l host $fields[4]

        if test "$group" != "$last_group"
            ctf_info "$group"
            set last_group $group
        end

        if test -n "$host"
            printf '  %s : %s (%s)\n' "$user" "$secret" "$host"
        else
            printf '  %s : %s\n' "$user" "$secret"
        end
    end
    rm -f $tmp
end

function _ctf_creds
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    set -l usage "Usage: ctf creds [<user> <password> | <user:password>] [-d <domain>]

  -d, --domain    Store a domain-qualified credential. Use a domain FQDN
                  (north.sevenkingdoms.local) or local.<host> for local accounts.
                  Use 'local' for a local credential without a host."

    argparse 'd/domain=' 'h/help' -- $argv
    or begin
        ctf_error "Invalid arguments."
        echo $usage
        return 1
    end

    if set -q _flag_help
        echo $usage
        return 0
    end

    if not set -q boxpwd; or not test -d "$boxpwd"
        ctf_error "Not in a CTF box environment. Run 'ctf start <boxname> <ip>' first."
        return 1
    end

    set -l creds_file "$boxpwd/creds.txt"
    set -l filter ""
    if set -q _flag_domain
        set filter $_flag_domain
    end

    if test (count $argv) -eq 0
        __ctf_creds_show $creds_file $filter
        return 0
    end

    set -l user_pass
    if test (count $argv) -eq 1
        set user_pass $argv[1]
        if not string match -q '*:*' -- $user_pass
            ctf_error "Single argument must be in format 'user:password'"
            return 1
        end
    else if test (count $argv) -eq 2
        set user_pass "$argv[1]:$argv[2]"
    else
        ctf_error "Too many arguments."
        echo $usage
        return 1
    end

    set -l identity (string split -m1 ':' -- $user_pass)[1]
    set -l secret (string split -m1 ':' -- $user_pass)[2]
    set -l user $identity
    set -l domain ""

    if string match -q '*@*' -- $identity
        set user (string split -m1 '@' -- $identity)[1]
        set domain (string split -m1 '@' -- $identity)[2]
    else if string match -rq '\\\\' -- $identity
        set domain (string split -m1 '\\' -- $identity)[1]
        set user (string split -m1 '\\' -- $identity)[2]
    end

    if test -z "$user"
        ctf_error "Username is required"
        return 1
    end

    if string match -q 'local.' -- $domain
        set domain (string replace -r '^local\\.$' 'local' -- $domain)
    end

    if test -n "$domain"; and not string match -q 'local*' -- $domain; and not string match -q '*.*' -- $domain
        ctf_warn "Domain '$domain' looks like a NetBIOS name; prefer a FQDN such as north.sevenkingdoms.local."
    end

    if set -q _flag_domain
        if not string match -q 'local*' -- $_flag_domain; and not string match -q '*.*' -- $_flag_domain
            ctf_error "Domain '$_flag_domain' is not an FQDN. Use a name like north.sevenkingdoms.local, or local/local.<host> for local accounts."
            return 1
        end
        if test -n "$domain"; and test "$domain" != "$_flag_domain"
            if not string match -q 'local*' -- $domain; and not string match -q '*.*' -- $domain
                set domain $_flag_domain
            else
                ctf_warn "Keeping existing domain '$domain' instead of '$_flag_domain'."
            end
        else if test -z "$domain"
            set domain $_flag_domain
        end
    end

    if test -n "$domain"
        set user_pass "$user@$domain:$secret"
    else
        set user_pass "$user:$secret"
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

    __ctf_creds_show $creds_file $filter
end
