function _ctf_sync
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    if contains -- -h $argv; or contains -- --help $argv
        ctf_info "Usage: ctf sync <ip> | ctf sync --off"
        return 0
    end

    if test (count $argv) -eq 0
        ctf_error "Usage: ctf sync <ip> | ctf sync --off"
        echo ""
        echo "  ctf sync <ip>    - Sync time with target box"
        echo "  ctf sync --off   - Unsync and use public NTP"
        return 1
    end

    set -l target $argv[1]

    if test "$target" = "--off"
        ctf_header "Syncing time with pool.ntp.org"
        ctf_time_sync_public
        or return 1
        ctf_success "Time synced with public NTP"
    else
        if not ctf_valid_ip $target
            ctf_error "Invalid IP address: $target"
            return 1
        end

        ctf_header "Syncing time with target box ($target)"
        ctf_time_sync $target
        or return 1
        ctf_success "Time synced with $target"
    end
end
