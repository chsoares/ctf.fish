# Return the VPN interface IP, preferring tun0 and falling back to wg0.
function ctf_arch_ip
    for iface in tun0 wg0
        set -l ip (ip -4 -o addr show dev $iface 2>/dev/null | awk '{ print $4 }' | cut -d/ -f1 | head -n1)
        if test -n "$ip"
            echo $ip
            return
        end
    end
end
