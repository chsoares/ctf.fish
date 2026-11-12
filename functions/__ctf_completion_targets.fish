# Shared target completion helper: IP descriptions come from /etc/hosts.

function __ctf_completion_ip_description --argument-names ip
    set -l names (awk -v ip="$ip" '
        /^[[:space:]]*#/ { next }
        $1 == ip {
            for (i = 2; i <= NF; i++) {
                if ($i ~ /^#/) break
                print $i
            }
        }
    ' /etc/hosts 2>/dev/null)

    if test (count $names) -eq 0
        echo unknown
        return
    end

    set -l best $names[1]
    for name in $names
        if test (string length -- $name) -lt (string length -- $best)
            set best $name
        end
    end
    echo $best
end

function __ctf_completion_targets
    set -l hosts_only 0
    if contains -- --hosts $argv
        set hosts_only 1
    end

    if test $hosts_only -eq 1
        for ip in (awk '
            /^[[:space:]]*#/ { next }
            $1 ~ /^127\./ || $1 == "::1" || $1 == "0.0.0.0" { next }
            $1 ~ /^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/ { print $1 }
        ' /etc/hosts 2>/dev/null | sort -u)
            printf '%s\t%s\n' "$ip" (__ctf_completion_ip_description $ip)
        end
        return
    end

    for file in (find . -maxdepth 1 -name "*_ips.txt" -type f 2>/dev/null)
        while read -l line
            set line (string trim -- $line)
            string match -qr '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' -- $line; or continue
            printf '%s\t%s\n' "$line" (__ctf_completion_ip_description $line)
        end < "$file"
    end
end
