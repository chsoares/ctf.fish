# Load the active box environment. If the global env.fish disappeared (for
# example after a cleanup), recover it when there is exactly one active 0_*
# box. With multiple active boxes, let the user pick with `ctf start`.
if test -f ~/Lab/env.fish
    source ~/Lab/env.fish
    test -d "$boxpwd"; and cd "$boxpwd"
else
    set -l active_envs
    for envfile in ~/Lab/boxes/0_*/env.fish
        test -f $envfile; and set -a active_envs $envfile
    end

    if test (count $active_envs) -eq 1
        if cp $active_envs[1] ~/Lab/env.fish
            source ~/Lab/env.fish
            test -d "$boxpwd"; and cd "$boxpwd"
        end
    else if test (count $active_envs) -gt 1
        echo "ctf: multiple active boxes found; run 'ctf start <box> <ip>' to select one." >&2
    end
end

## Aliases
alias www 'ls; python -m http.server 8888'

## Functions
function bloodhound
    set oldpwd (pwd)
    cd ~/.config/bloodhound
    docker compose up -d
    cd $oldpwd
end

function claudectf
    set oldpwd (pwd)
    cd $OBSIDIAN
    claude
    cd $oldpwd
end

function binbag
    set oldpwd (pwd)
    cd ~/Lab/binbag
    ls
    python -m http.server 8000
    cd $oldpwd
end

function ligolo
    set oldpwd (pwd)
    cd ~
    
    # Use provided port or default to 11601
    set port 11601
    if test (count $argv) -gt 0
        set port $argv[1]
    end
    
    sudo /usr/share/ligolo/linux/proxy/amd64/proxy -selfcert -laddr 0.0.0.0:$port
    cd $oldpwd
end

## Abbreviations
abbr --add nmap 'sudo nmap --min-rate 10000'
abbr --add ovpn 'sudo openvpn'
abbr --erase box 2>/dev/null
function box
    if set -q boxpwd; and test -d "$boxpwd"
        cd "$boxpwd"
    else
        echo "ctf: no active box; run 'ctf start <box> <ip>'." >&2
        return 1
    end
end
abbr --add john 'john -w=$rockyou'

## Variables
set -x rockyou '/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt'
set -x weblist '/home/chsoares/Repos/ezpz/utils/weblist_ezpz.txt'

## Executables
alias penelope '/opt/penelope/penelope.py -i tun0'
alias john /opt/john/run/john

## ezpz
#set -Ux EZPZ_HOME '/home/chsoares/Repos/ezpz' 
#set -U fish_function_path "$EZPZ_HOME/functions" $fish_function_path
#set -U fish_complete_path "$EZPZ_HOME/completions" $fish_complete_path
abbr --add netscan 'ezpz netscan'
abbr --add webscan 'ezpz webscan'
abbr --add adscan 'ezpz adscan'
abbr --add testcreds 'ezpz testcreds'
abbr --add checkvulns 'ezpz checkvulns'
abbr --add getloot 'ezpz getloot'
abbr --add secretsparse 'ezpz secretsparse'
abbr --add enumsqli 'ezpz enumsqli'
abbr --add enumdomain 'ezpz enumdomain'
abbr --add enumuser 'ezpz enumuser'
abbr --add enumshares 'ezpz enumshares'
abbr --add enumnull 'ezpz enumnull'
abbr --add getflag 'ezpz getflag'
abbr --add getshell 'ezpz getshell'
