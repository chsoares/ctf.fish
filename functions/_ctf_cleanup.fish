function _ctf_cleanup
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    if contains -- -h $argv; or contains -- --help $argv
        ctf_info "Usage: cleanup"
        return 0
    end

    if not set -q CTF_LAB; or test -z "$CTF_LAB"
        ctf_error "CTF_LAB is not set."
        return 1
    end

    if test -f $CTF_LAB/env.fish
        source $CTF_LAB/env.fish
    else
        ctf_error "No global env.fish found. Are you in a CTF session?"
        return 1
    end

    if not set -q boxpwd; or not set -q box; or not set -q ip
        ctf_error "Missing box, ip or boxpwd in $CTF_LAB/env.fish."
        return 1
    end

    if not test -d $boxpwd
        ctf_error "Box directory $boxpwd not found."
        return 1
    end

    set -l base_dir $CTF_LAB/boxes
    set -l new_box_dir $base_dir/$box
    if test -d "$new_box_dir"
        ctf_error "Destination already exists: $new_box_dir"
        ctf_warn "Move or remove it before running cleanup again."
        return 1
    end

    cd "$HOME"; or return 1
    ctf_header "Cleaning up ctf environment"

    # 1. Back up /etc/hosts before changing it.
    if not sudo cp /etc/hosts $boxpwd/hosts.bak
        ctf_error "Failed to back up /etc/hosts."
        return 1
    end
    set -l current_user (id -un)
    set -l current_group (id -gn)
    sudo chown "$current_user:$current_group" $boxpwd/hosts.bak 2>/dev/null
    ctf_info "Backed up /etc/hosts to $boxpwd/hosts.bak"

    # 2. Remove only this box's hosts entries, preserving other entries.
    if not ctf_hosts_remove $ip "$box.htb"
        ctf_error "Failed to clean /etc/hosts."
        return 1
    end

    echo ""

    # 3. Move the active box directory back to its archived name.
    if not mv $boxpwd $new_box_dir
        ctf_error "Failed to move $boxpwd to $new_box_dir"
        return 1
    end
    ctf_info "Moved $boxpwd to $new_box_dir"
    echo ""

    # 4. Unset environment variables and remove the global env file.
    if test -f $CTF_LAB/env.fish
        ctf_info "Unsetting environment variables from global env.fish"
        set -l env_vars (grep -E '^set -g[x]? ' $CTF_LAB/env.fish | sed -E 's/^set -g[x]? ([A-Za-z_][A-Za-z0-9_]*).*/\1/')
        for var in $env_vars
            if set -q $var
                set -e $var
            end
        end

        for var in KRB5_CONFIG KRB5CCNAME
            if set -q $var
                set -e $var
            end
        end

        rm -f $CTF_LAB/env.fish
        ctf_info "Removed global env.fish"
        echo ""
    end

    # 5. Restore public NTP sync.
    ctf_header "Syncing time with pool.ntp.org"
    ctf_time_sync_public
    echo ""
    ctf_success "Cleanup complete!"
end
