# Helper: IPs from /etc/hosts (excluding localhost)
function __ctf_ips
    awk '{print $1}' /etc/hosts 2>/dev/null \
        | string match -rv '^(#|127\.|::1|0\.0\.0\.0)' \
        | sort -u
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

# Main subcommands
complete -c ctf -f -n '__fish_use_subcommand' -a "start"    -d "Start a new CTF box environment"
complete -c ctf -f -n '__fish_use_subcommand' -a "cleanup"  -d "Cleanup and reset environment"
complete -c ctf -f -n '__fish_use_subcommand' -a "addhost"  -d "Add or update /etc/hosts entry"
complete -c ctf -f -n '__fish_use_subcommand' -a "env"      -d "Manage box environment variables"
complete -c ctf -f -n '__fish_use_subcommand' -a "creds"    -d "Add credentials to creds.txt"
complete -c ctf -f -n '__fish_use_subcommand' -a "sync"     -d "Sync time with target box or public NTP"

# ctf env subcommands
complete -c ctf -n '__fish_seen_subcommand_from env' -f -a "set"  -d "Set or update a variable"
complete -c ctf -n '__fish_seen_subcommand_from env' -f -a "edit" -d "Edit the box environment file"

# Dynamic positional arguments
complete -c ctf -n '__fish_seen_subcommand_from addhost' -f -a '(__ctf_addhost_arg)' -d "Target IP address"
complete -c ctf -n '__fish_seen_subcommand_from start'   -f -a '(__ctf_start_arg)'   -d "Existing box name"
complete -c ctf -n '__fish_seen_subcommand_from sync'    -f -a '(__ctf_ips)'         -d "Target IP address to sync with"
complete -c ctf -n '__fish_seen_subcommand_from sync'    -f -a "--off"               -d "Unsync and use public NTP"

# Help for all subcommands
complete -c ctf -n '__fish_seen_subcommand_from start cleanup addhost env creds sync' -s h -l help -d "Show help message"
