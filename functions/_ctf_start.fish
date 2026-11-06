function _ctf_start
    if not set -q CTF_HOME; or not test -d "$CTF_HOME"
        echo "CTF_HOME is not set or does not exist." >&2
        return 1
    end

    source "$CTF_HOME/functions/_ctf_colors.fish"
    ctf_banner

    set -l usage "Usage: start <boxname> <boxip>"
    if contains -- -h $argv; or contains -- --help $argv
        ctf_info $usage
        return 0
    end

    if not set -q CTF_LAB; or test -z "$CTF_LAB"
        ctf_error "CTF_LAB is not set."
        return 1
    end

    # Validate arguments before any network operation.
    if test (count $argv) -ne 2
        ctf_error $usage
        return 1
    end

    set -l box $argv[1]
    set -l ip $argv[2]

    if not string match -qr '^[A-Za-z0-9._-]+$' -- $box; or test "$box" = "." -o "$box" = ".."
        ctf_error "Invalid box name: $box"
        return 1
    end

    if not ctf_valid_ip $ip
        ctf_error "Invalid IP address: $ip"
        return 1
    end

    set -l base_dir $CTF_LAB/boxes
    set -l box_dir $base_dir/$box
    set -l box_dir_zero $base_dir/0_$box

    # Update repositories. Failures are non-fatal.
    if set -q CTF_HOME; and test -d "$CTF_HOME/.git"
        ctf_header "Updating ctf-utils repository..."
        if git -C "$CTF_HOME" pull --quiet
            ctf_success "ctf-utils updated"
        else
            ctf_warn "Could not update ctf-utils; continuing with the current checkout."
        end
        echo
    end

    if set -q EZPZ_HOME; and test -d "$EZPZ_HOME/.git"
        ctf_header "Updating ezpz repository..."
        if git -C "$EZPZ_HOME" pull --quiet
            ctf_success "ezpz updated"
        else
            ctf_warn "Could not update ezpz; continuing with the current checkout."
        end
        echo
    end

    ctf_header "Setting up ctf environment..."

    # === Existing active box ===
    if test -d $box_dir_zero
        ctf_info "Active box directory already exists: $box_dir_zero"
        cd $box_dir_zero; or return 1

        if test -f env.fish
            ctf_header "Sourcing environment variables from env.fish"
            if not cp env.fish $CTF_LAB/env.fish
                ctf_error "Failed to update $CTF_LAB/env.fish"
                return 1
            end
            source $CTF_LAB/env.fish
        else
            ctf_warn "env.fish not found in $box_dir_zero"
        end

        # If the hosts entry disappeared (for example after a cleanup), add it
        # back without touching unrelated entries.
        if test -n "$ip"; and not awk -v ip="$ip" '$1 == ip { found=1 } END { exit !found }' /etc/hosts
            ctf_header "Restoring /etc/hosts entry for $ip"
            ctf_hosts_add $ip "$box.htb"
            or return 1
        end

        echo ""
        ctf_header "Syncing time with target box"
        ctf_time_sync $ip
        echo ""
        ctf_success "Box '$box' environment restored! Happy hacking 😉"
        return 0
    end

    # === Archived box ===
    if test -d $box_dir
        ctf_info "Box directory already exists: $box_dir"
        cd $box_dir; or return 1

        if test -f env.fish
            ctf_header "Sourcing environment variables from env.fish"
            if not cp env.fish $CTF_LAB/env.fish
                ctf_error "Failed to update $CTF_LAB/env.fish"
                return 1
            end
            source $CTF_LAB/env.fish
        else
            ctf_warn "env.fish not found in $box_dir"
        end

        if test -f hosts.bak
            ctf_header "Restoring /etc/hosts from hosts.bak"
            if not sudo tee /etc/hosts < hosts.bak > /dev/null
                ctf_error "Failed to restore /etc/hosts"
                return 1
            end
        else
            ctf_warn "hosts.bak not found in $box_dir"
        end

        if not test -d $box_dir_zero
            if not mv $box_dir $box_dir_zero
                ctf_error "Failed to move $box_dir to $box_dir_zero"
                return 1
            end
            ctf_info "Moved $box_dir to $box_dir_zero"
            cd $box_dir_zero; or return 1
        else
            cd $box_dir_zero; or return 1
        end

        echo ""
        ctf_header "Syncing time with target box"
        ctf_time_sync $ip
        echo ""
        ctf_success "Box '$box' environment restored! Happy hacking 😉"
        return 0
    end

    # === New box ===
    set -l arch_ip (ip a 2>/dev/null | grep tun0 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" | head -n1)
    set -l url "http://$box.htb"
    set -l boxpwd $box_dir_zero

    if not mkdir -p "$boxpwd"
        ctf_error "Failed to create $boxpwd"
        return 1
    end
    cd "$boxpwd"; or return 1
    mkdir -p screenshots

    # Generate env.fish with escaped values so paths/usernames with spaces
    # survive `source`.
    set -l env_lines
    set -a env_lines "set -gx arch "(string escape -- "$arch_ip")
    set -a env_lines "set -gx box "(string escape -- "$box")
    set -a env_lines "set -gx ip "(string escape -- "$ip")
    set -a env_lines "set -gx url "(string escape -- "$url")
    set -a env_lines "set -gx boxpwd "(string escape -- "$boxpwd")
    printf '%s\n' $env_lines > env.fish

    if not cp env.fish "$CTF_LAB/env.fish"
        ctf_error "Failed to write $CTF_LAB/env.fish"
        return 1
    end

    ctf_info "Created directory at $boxpwd"
    echo ""
    if test -n "$arch_ip"
        ctf_info "\$arch is set to $arch_ip"
    else
        ctf_warn "\$arch is empty: tun0 IP not found."
    end
    ctf_info "\$ip is set to $ip"
    ctf_info "\$box is set to $box"
    ctf_info "\$url is set to $url"
    echo ""

    ctf_hosts_add $ip "$box.htb"
    or return 1

    echo ""
    ctf_header "Syncing time with target box"
    ctf_time_sync $ip
    echo ""

    ctf_success "Box environment created! Happy hacking 😉"
    source "$CTF_LAB/env.fish"
end
