# Helper: IPs from /etc/hosts (excluding localhost)
function __ctf_ips
    __ctf_completion_targets --hosts
end

# Helper: box names from $CTF_LAB/boxes, stripping the active 0_ prefix
function __ctf_boxes
    set -l dir $CTF_LAB/boxes
    test -d "$dir"; or return
    for entry in $dir/*
        test -d "$entry"; or continue
        set -l name (basename $entry)
        string replace -r '^0_' '' -- $name
    end
end

# Complete the first positional argument of `ctf start` with existing boxes.
function __ctf_start_arg
    set -l tokens (commandline -opc)
    if test (count $tokens) -le 2
        __ctf_boxes
    end
end

# Complete the first positional argument of `ctf addhost` with known IPs.
function __ctf_addhost_arg
    set -l tokens (commandline -opc)
    if test (count $tokens) -le 2
        __ctf_ips
    end
end

# Variables from the box env.fish, with their current values.
function __ctf_env_vars
    set -l file $CTF_LAB/env.fish
    test -f "$file"; or return

    while read -l line
        string match -q 'set -gx *' -- $line; or continue
        set -l parts (string split ' ' -- $line)
        test (count $parts) -ge 4; or continue
        set -l var $parts[3]
        set -l value (string join ' ' $parts[4..-1])
        if string match -qi '*pass*' -- $var; or string match -qi '*secret*' -- $var; or string match -qi '*token*' -- $var; or string match -qi '*key*' -- $var; or string match -qi '*hash*' -- $var
            set value '***'
        else if test -z "$value"; or test "$value" = "''"
            set value '(empty)'
        end
        printf '%s\t%s\n' "$var" "$value"
    end < "$file"
end

function __ctf_env_set_var_arg
    set -l tokens (commandline -opc)
    if test (count $tokens) -eq 3; and test "$tokens[2]" = env; and test "$tokens[3]" = set
        __ctf_env_vars
    end
end

# Domains and local pseudo-domains already present in the box creds file.
function __ctf_creds_domains
    set -l file creds.txt
    if set -q boxpwd; and test -d "$boxpwd"
        set file "$boxpwd/creds.txt"
    end

    set -l counts (mktemp)
    if test -f "$file"
        while read -l line
            set line (string trim -- $line)
            test -z "$line"; and continue
            string match -q '#*' -- $line; and continue
            set -l identity (string split -m1 ':' -- $line)[1]
            set -l domain ""
            if string match -q '*@*' -- $identity
                set domain (string split -m1 '@' -- $identity)[2]
            else if string match -rq '\\\\' -- $identity
                set domain (string split -m1 '\\' -- $identity)[1]
            end
            test -n "$domain"; or continue
            if not string match -q 'local*' -- $domain; and not string match -q '*.*' -- $domain
                continue
            end
            echo $domain >> $counts
            if string match -q 'local.*' -- $domain
                echo local >> $counts
            end
        end < "$file"
    end

    set -l seen
    for entry in (sort $counts | uniq -c | awk '{ print $1 "\t" $2 }')
        set -l parts (string split \t -- $entry)
        set -l count $parts[1]
        set -l domain $parts[2]
        set -l desc "$count entry"
        if test "$count" -ne 1
            set desc "$count entries"
        end
        printf '%s\t%s\n' "$domain" "$desc"
        set -a seen $domain
    end
    rm -f $counts

    for domain in (__ctf_completion_domains 2>/dev/null)
        contains -- $domain $seen; and continue
        printf '%s\t%s\n' "$domain" "0 entries"
    end
end

# ctf does not take file arguments
complete -c ctf -f

# Main subcommands
complete -c ctf -f -n '__fish_use_subcommand' -a "start"    -d "Start a new CTF box environment"
complete -c ctf -f -n '__fish_use_subcommand' -a "cleanup"  -d "Cleanup and reset environment"
complete -c ctf -f -n '__fish_use_subcommand' -a "addhost"  -d "Add or update /etc/hosts entry"
complete -c ctf -f -n '__fish_use_subcommand' -a "env"      -d "Manage box environment variables"
complete -c ctf -f -n '__fish_use_subcommand' -a "creds"    -d "Add credentials to creds.txt"
complete -c ctf -f -n '__fish_use_subcommand' -a "sync"     -d "Sync time with target box or public NTP"

# ctf creds takes values, not files
complete -c ctf -f -n '__fish_seen_subcommand_from creds'

# ctf env subcommands
complete -c ctf -n '__fish_seen_subcommand_from env; and not __fish_seen_subcommand_from set edit' -f -a "set"  -d "Set or update a variable"
complete -c ctf -n '__fish_seen_subcommand_from env; and not __fish_seen_subcommand_from set edit' -f -a "edit" -d "Edit the box environment file"
complete -c ctf -f -n '__fish_seen_subcommand_from env' -a '(__ctf_env_set_var_arg)'

# Dynamic positional arguments
complete -c ctf -n '__fish_seen_subcommand_from addhost' -f -a '(__ctf_addhost_arg)'
complete -c ctf -n '__fish_seen_subcommand_from start'   -f -a '(__ctf_start_arg)'
complete -c ctf -n '__fish_seen_subcommand_from sync'    -f -a '(__ctf_ips)'
complete -c ctf -n '__fish_seen_subcommand_from sync'    -f -a "--off"               -d "Unsync and use public NTP"

# ctf creds domain completion
complete -c ctf -f -n '__fish_seen_subcommand_from creds' -s d -l domain -r -a '(__ctf_creds_domains)' -d "Domain or local.<host>"

# Help for all subcommands
complete -c ctf -n '__fish_seen_subcommand_from start cleanup addhost env creds sync' -s h -l help -d "Show help message"
