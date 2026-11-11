# special symbols

function ctf_header
    echo (set_color yellow --bold)"  "$argv(set_color normal)
end
function ctf_info
    echo (set_color cyan)"  "$argv(set_color normal)
end
function ctf_cmd
    echo (set_color blue)"  "$argv(set_color normal)
end
function ctf_error
    echo (set_color red --bold)"  "$argv(set_color normal)
end
function ctf_warn
    echo (set_color magenta)"  "$argv(set_color normal)
end
function ctf_success
    echo (set_color magenta --bold)"  "$argv(set_color normal)
end
function ctf_question
    echo (set_color cyan)"  "$argv(set_color normal)
end
function ctf_title
    echo (set_color magenta --bold)"  "$argv(set_color normal)
end


function ctf_banner
    gum style --foreground 5 --border-foreground 6 --border rounded --padding "0 4" '󰆧 ctf.fish - ctf environment helper'
end
function ctf_input
    gum input --prompt "❯  " --placeholder "$argv" --prompt.foreground 5 --cursor.foreground 6
end
function ctf_choose_one
    gum choose --limit=1 --cursor.foreground 6 --selected.foreground 5 --cursor "❯ " --header "" $argv
end
function ctf_choose_many
    gum choose --no-limit --cursor.foreground 6 --selected.foreground 5 --cursor "❯ " --header "" $argv
end

function ctf_confirm
    gum confirm "Select option" --prompt.foreground 240 --selected.background 5 --selected.foreground 255
end

function _ctf_spin
    set -l verbs "running" "executing" "processing" "computing" "pwning" "exploiting" "hacking" "cracking" "scanning" "enumerating" "fuzzing" "bruteforcing" "rooting" "escalating" "pivoting" "tunneling" "injecting" "dumping" "decrypting" "reverse-engineering" "brewing" "cooking" "dancing" "vibing" "contemplating" "procrastinating" "caffeinating" "debugging life" "yolo-ing" "memeing" "overthinking" "quantum-leaping" "time-traveling" "teleporting" "summoning chaos" "manifesting packets" "channeling energy" "consulting the void" "awakening the machine"
    set -l random_verb $verbs[(math (random) % (count $verbs) + 1)]
    gum spin --spinner minidot --title " $random_verb..." --spinner.foreground 6 --title.foreground 4 -- $argv
end




# Validate an IPv4 address with all octets in range.
function ctf_valid_ip --argument-names ip
    string match -qr '^(([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])$' -- $ip
end

# Add hostnames to /etc/hosts for an exact IP, without duplicating them.
function ctf_hosts_add --argument-names ip
    set -l hosts $argv[2..]
    if test (count $hosts) -eq 0
        return 1
    end

    set -l line (awk -v ip="$ip" '$1 == ip { print; exit }' /etc/hosts)
    if test -n "$line"
        set -l existing (string split ' ' (string replace -a \t ' ' (string trim -- $line)))
        set -l to_add
        for h in $hosts
            contains -- $h $existing; and continue
            contains -- $h $to_add; and continue
            set -a to_add $h
        end

        if test (count $to_add) -eq 0
            ctf_info "Host(s) already present for $ip: "(string join ' ' $hosts)
            awk -v ip="$ip" '$1 == ip' /etc/hosts
            return 0
        end

        set -l add_string (string join ' ' $to_add)
        set -l tmp (mktemp)
        if not awk -v ip="$ip" -v add="$add_string" '
                $1 == ip { print $0 " " add; next }
                { print }
            ' /etc/hosts > $tmp
            ctf_error "Failed to build /etc/hosts update for $ip"
            rm -f $tmp
            return 1
        end
        if not sudo tee /etc/hosts < $tmp > /dev/null
            ctf_error "Failed to update /etc/hosts for $ip"
            rm -f $tmp
            return 1
        end
        rm -f $tmp
        ctf_info "Appended \"$add_string\" to existing entry for \"$ip\" in /etc/hosts"
    else
        echo "$ip    "(string join ' ' $hosts) | sudo tee -a /etc/hosts > /dev/null
        or begin
            ctf_error "Failed to add $ip to /etc/hosts"
            return 1
        end
        ctf_info "Added new entry \"$ip "(string join ' ' $hosts)"\" to /etc/hosts"
    end

    awk -v ip="$ip" '$1 == ip' /etc/hosts
end

# Remove a box IP entry and its hostnames from /etc/hosts, preserving other
# entries and the localhost records.
function ctf_hosts_remove --argument-names ip
    set -l hosts $argv[2..]
    set -l tmp (mktemp)
    if not awk -v ip="$ip" '$1 != ip { print }' /etc/hosts > $tmp
        ctf_error "Failed to build /etc/hosts update for $ip"
        rm -f $tmp
        return 1
    end

    for h in $hosts
        set -l tmp2 (mktemp)
        if not awk -v h="$h" 'index($0, h) == 0 { print }' $tmp > $tmp2
            ctf_error "Failed to remove '$h' from /etc/hosts"
            rm -f $tmp $tmp2
            return 1
        end
        mv $tmp2 $tmp
    end

    if not grep -qE '^127\.0\.0\.1[[:space:]]+localhost' $tmp
        echo "127.0.0.1   localhost" >> $tmp
    end
    if not grep -qE '^::1[[:space:]]+localhost' $tmp
        echo "::1   localhost" >> $tmp
    end

    if not sudo tee /etc/hosts < $tmp > /dev/null
        ctf_error "Failed to update /etc/hosts"
        rm -f $tmp
        return 1
    end

    rm -f $tmp
    ctf_info "/etc/hosts cleaned for $ip"
    return 0
end

# Sync time with a target box. Stops systemd-timesyncd first to avoid conflicts.
function ctf_time_sync --argument-names target
    if not command -v ntpdate >/dev/null 2>&1
        ctf_warn "ntpdate not found; skipping time sync with $target."
        return 1
    end

    if command -v systemctl >/dev/null 2>&1
        sudo systemctl stop systemd-timesyncd 2>/dev/null
    end

    if not sudo ntpdate $target
        ctf_warn "Failed to sync time with $target."
        return 1
    end
    return 0
end

# Restore public NTP sync after cleanup/--off.
function ctf_time_sync_public
    ctf_time_sync pool.ntp.org
    set -l rc $status
    if command -v systemctl >/dev/null 2>&1
        sudo systemctl start systemd-timesyncd 2>/dev/null
    end
    return $rc
end

## no special symbols

# function ctf_header
#     echo (set_color yellow --bold)"[+] "$argv(set_color normal)
# end
# function ctf_info
#     echo (set_color cyan)"[*] "$argv(set_color normal)
# end
# function ctf_cmd
#     echo (set_color blue)"[>] "$argv(set_color normal)
# end
# function ctf_error
#     echo (set_color red --bold)"[!] "$argv(set_color normal)
# end
# function ctf_warn
#     echo (set_color magenta --bold)"[*] "$argv(set_color normal)
# end
# function ctf_success
#     echo (set_color magenta --bold)"[✓] "$argv(set_color normal)
# end
# function ctf_question
#     echo (set_color magenta)"[?] "$argv(set_color normal)
# end
# function ctf_title
#     echo (set_color magenta --bold)"[~] "$argv(set_color normal)
# end