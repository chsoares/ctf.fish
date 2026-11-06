function _ctf_addhost
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    set -l usage "Usage: addhost <ip> <hostname> [hostname2] [hostname3] ..."
    if contains -- -h $argv; or contains -- --help $argv
        ctf_info $usage
        return 0
    end

    if test (count $argv) -lt 2
        ctf_error $usage
        return 1
    end

    set -l ip $argv[1]
    set -l hosts $argv[2..]

    if not ctf_valid_ip $ip
        ctf_error "Invalid IP address: $ip"
        return 1
    end

    for host in $hosts
        if not string match -rq '^[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?$' -- $host
            ctf_error "Invalid hostname: $host"
            return 1
        end
        if string match -q '*..*' -- $host
            ctf_error "Invalid hostname: $host"
            return 1
        end
    end

    ctf_hosts_add $ip $hosts
    or return 1
end
