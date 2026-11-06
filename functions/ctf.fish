
function ctf
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    set -l commands start cleanup addhost env creds sync

    if test (count $argv) -eq 0
        ctf_show_menu
        return 0
    end

    set -l subcmd $argv[1]
    set -e argv[1]

    if test "$subcmd" = "-h" -o "$subcmd" = "--help" -o "$subcmd" = "help"
        ctf_show_menu
        return 0
    end

    if contains -- $subcmd $commands
        switch $subcmd
            case start
                _ctf_start $argv
            case cleanup
                _ctf_cleanup $argv
            case addhost
                _ctf_addhost $argv
            case env
                _ctf_env $argv
            case creds
                _ctf_creds $argv
            case sync
                _ctf_sync $argv
        end
        return $status
    else
        ctf_error "Unknown command: $subcmd"
        ctf_show_menu
        return 1
    end
end

function ctf_show_menu
    ctf_banner
    echo ""
    echo "Available commands:"
    echo "  start <boxname> <ip>   - Start a new CTF box environment"
    echo "  cleanup                - Cleanup and reset environment"
    echo "  addhost <ip> <host>    - Add or update /etc/hosts entry"
    echo "  env [set|edit] ...     - Manage box environment variables"
    echo "  creds <user> <pass>    - Add credentials to creds.txt"
    echo "  sync <ip|--off>        - Sync time with target box or public NTP"
    echo ""
    ctf_info "Usage: ctf <command> [options]"
end