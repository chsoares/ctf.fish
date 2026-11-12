function __ctf_creds_completion_users
    set -l filter (__ctf_creds_completion_domain)
    for entry in (__ctf_creds_completion_entries)
        set -l fields (string split \t -- $entry)
        set -l user $fields[1]
        set -l domain $fields[2]
        __ctf_creds_completion_matches $domain $filter; or continue
        set -l desc (__ctf_creds_completion_description $domain)
        string match -q 'local.*' -- $domain; and set desc local
        printf '%s\t%s\n' "$user" "$desc"
    end
end
