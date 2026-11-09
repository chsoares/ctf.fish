#!/usr/bin/env fish

# CTF Tools Installation Script
# This script installs CTF/pentest tools found in your current setup

set -l script_dir (dirname (realpath (status --current-filename)))

# Source color functions
source "$script_dir/functions/_ctf_colors.fish"
sudo -v > /dev/null

ctf_banner
ctf_title "ctf.fish curated ctf & pentest packages"

# Function to install yay packages
function install_yay_packages
    set -l packages $argv
    
    if test (count $packages) -gt 0
        ctf_header "Installing yay packages..."
        for package in $packages
            _ctf_spin yay -S --needed --noconfirm $package
            if test $status -eq 0
                ctf_success "$package"
            else
                ctf_error "Failed to install $package"
            end
        end
    end
end

# Function to install pipx packages
function install_pipx_packages
    set -l packages $argv
    
    if test (count $packages) -gt 0
        ctf_header "Installing pipx packages..."
        _ctf_spin pipx ensurepath
        for package in $packages
            _ctf_spin pipx install $package
            if test $status -eq 0
                ctf_success "$package"
            else
                ctf_error "Failed to install $package"
            end
        end
    end
end

# nmap's service database is root-owned. Patch it so 3389 is labelled rdp and
# the WinRM ports are common enough to be picked up by `nmap -F`.
function patch_nmap_services
    set -l services /usr/share/nmap/nmap-services
    if not test -f $services
        ctf_warn "nmap-services not found; skipping nmap patch."
        return
    end

    ctf_header "Patching nmap service database..."
    set -l tmp (mktemp)
    awk -F'\t' 'BEGIN { OFS = "\t" }
        $2 == "3389/tcp" || $2 == "3389/udp" { $1 = "rdp" }
        $2 == "5985/tcp" || $2 == "5985/udp" || $2 == "5986/tcp" || $2 == "5986/udp" { $1 = "winrm" }
        $2 == "5985/tcp" || $2 == "5986/tcp" { $3 = "0.050000" }
        { print }
    ' $services > $tmp

    if cmp -s $services $tmp
        ctf_success "nmap-services already patched"
        rm -f $tmp
        return
    end

    if not test -f "$services.ctf.fish.bak"
        sudo cp $services "$services.ctf.fish.bak"
    end

    if sudo install -m 644 $tmp $services
        ctf_success "nmap-services patched (3389 -> rdp, 5985/5986 in fast scan)"
    else
        ctf_error "Failed to patch nmap-services"
    end
    rm -f $tmp
end

install_yay_packages \
    bettercap \
    bind \
    cupp-git \
    ffuf \
    fping \
    gdb \
    gef \
    github-cli \
    gnu-netcat \
    hashcat \
    hydra \
    impacket \
    john \
    kerbrute-bin \
    ligolo \
    metasploit \
    nfs-utils \
    nmap \
    ntp \
    openssh \
    openvpn \
    openldap \
    onesixtyone-git \
    pre2k-git \
    perl-image-exiftool \
    responder \
    ruby-getoptlong \
    ruby-resolv-replace \
    seclists \
    sqlmap \
    targetedkerberoast-git \
    tcpdump \
    ufw \
    whatweb \
    wireshark-qt \
    wpscan \
    wscat \
    python-bloodhound-ce-git \
    python-bs4 \
    python-krb5 \
    python-pipx \
    python-pwntools

patch_nmap_services

install_pipx_packages \
    git+https://github.com/Pennyw0rth/NetExec \
    git+https://github.com/login-securite/DonPAPI.git \
    git+https://github.com/blacklanternsecurity/MANSPIDER \
    bloodyad \
    certipy-ad \
    wesng \
    Devious-WinRM \
    evil-winrm-py \
    gpp-decrypt \
    ldapdomaindump \
    mitm6 \

# Add user to wireshark group for packet capture permissions
ctf_header "Configuring user permissions..."
_ctf_spin sudo usermod -a -G wireshark $USER
if test $status -eq 0
    ctf_success "Added $USER to wireshark group"
else
    ctf_error "Failed to add $USER to wireshark group"
end

# Function to install git repositories
function install_git_repos
    ctf_header "Installing git repositories..."
    sudo -v >/dev/null
    
    # Create /opt if it doesn't exist
    if not test -d /opt
        sudo mkdir -p /opt
    end
    
    # Change to /opt directory
    cd /opt
    
    # Install krbrelayx
    if not test -d /opt/krbrelayx
        _ctf_spin sudo git clone https://github.com/dirkjanm/krbrelayx.git
        if test $status -eq 0
            sudo chown -R $USER:$USER /opt/krbrelayx
            chmod +x /opt/krbrelayx/*.py
            fish_add_path /opt/krbrelayx/
            ctf_success "krbrelayx"
        else
            ctf_error "Failed to install krbrelayx"
        end
    else
        ctf_success "krbrelayx (already exists)"
    end
    
    # Install username-anarchy
    if not test -d /opt/username-anarchy
        _ctf_spin sudo git clone https://github.com/urbanadventurer/username-anarchy.git
        if test $status -eq 0
            sudo chown -R $USER:$USER /opt/username-anarchy
            chmod +x /opt/username-anarchy/username-anarchy
            fish_add_path /opt/username-anarchy
            ctf_success "username-anarchy"
        else
            ctf_error "Failed to install username-anarchy"
        end
    else
        ctf_success "username-anarchy (already exists)"
    end
    
    # Install penelope
    if not test -d /opt/penelope
        _ctf_spin sudo git clone https://github.com/chsoares/penelope.git
        if test $status -eq 0
            sudo chown -R $USER:$USER /opt/penelope
            ctf_success "penelope"
        else
            ctf_error "Failed to install penelope"
        end
    else
        ctf_success "penelope (already exists)"
    end
end

install_git_repos

echo ""
ctf_title "󰆧 ctf.fish curated tools installation completed!"
echo ""
echo "All tools have been installed."
echo "You may need to restart your shell for some tools to be available in PATH."
echo ""
echo "Manual installation recommended:"
echo "  - BurpSuite Professional: https://portswigger.net/burp/releases"
echo "  - BloodHound Community Edition: https://bloodhound.specterops.io/get-started/quickstart/community-edition-quickstart"