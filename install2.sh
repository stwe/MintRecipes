#!/usr/bin/env bash
set -Eeuo pipefail

################################################
# CONFIG
################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOGFILE="$HOME/mint-postinstall.log"

exec > >(tee -i "$LOGFILE")
exec 2>&1

RED='\033[1;31m'
CYAN='\033[1;36m'
GREEN='\033[1;32m'
NC='\033[0m'

UBUNTU_CODENAME=$(lsb_release -cs)

################################################
# HELPER
################################################

trap 'echo -e "${RED}Error on line $LINENO. Exit code: $?${NC}"' ERR

print_section() { echo -e "\n${CYAN}========== $1 ==========${NC}\n"; }
print_success() { echo -e "${GREEN}✔ $1${NC}"; }
print_error() { echo -e "${RED}✘ $1${NC}"; }

################################################
# VALIDATION
################################################

if [[ $EUID -eq 0 ]]; then
    print_error "Do not run as root. Use normal user with sudo."
    exit 1
fi

if ! grep -q "Linux Mint" /etc/os-release; then
    print_error "This script is intended for Linux Mint only."
    exit 1
fi

if ! sudo -v; then
    print_error "Sudo authentication failed."
    exit 1
fi

################################################
# APT HELPER
################################################

install_apt_packages() { sudo apt install -y "$@"; }

################################################
# PREPARE
################################################

sudo apt update
sudo apt upgrade -y

if ! command -v yad >/dev/null; then
    print_section "YAD fehlt – wird installiert..."
    install_apt_packages yad
    print_success "YAD erfolgreich installiert"
fi

mkdir -p ~/Bilder ~/.local/bin ~/.config ~/.fonts ~/.icons ~/.themes

################################################
# GUI
################################################

PAGE1=$(yad --title "Mint Setup (1/3) - System Basis" --width=650 --form --separator="|" \
    --text "<b>System-Grundlagen und Performance</b>" \
    --field="Infrastruktur:CHK" TRUE \
    --field="CLI Power-Tools:CHK" TRUE \
    --field="System GUI Apps:CHK" TRUE \
    --field="Monitoring Tools:CHK" TRUE \
    --field="Virtuelle Maschinenverwaltung:CHK" FALSE \
    --field="XanMod Kernel V3:CHK" FALSE \
    --field="Performance:CHK" FALSE \
    --field="Firewall (UFW):CHK" TRUE \
    --button="Abbrechen:1" --button="Weiter:0") || exit 1

PAGE2=$(yad --title "Mint Setup (2/3) - Software" --width=650 --form --separator="|" \
    --text "<b>Programme und Entwicklung</b>" \
    --field="Google Chrome:CHK" FALSE \
    --field="Messenger:CHK" FALSE \
    --field="Multimedia:CHK" FALSE \
    --field="Docker Engine:CHK" FALSE \
    --field="Visual Studio Code:CHK" FALSE \
    --field="Lazygit:CHK" FALSE \
    --field="JetBrains IDEs:CB" "Keine!CLion!IntelliJ!Beide" \
    --field="Gaming Stack:CHK" FALSE \
    --field="Nextcloud:CHK" FALSE \
    --field="NordVPN:CHK" FALSE \
    --button="Zurück:2" --button="Weiter:0" --button="Abbrechen:1")
RET=$?; [[ $RET -eq 1 ]] && exit 1; [[ $RET -eq 2 ]] && exec "$0"

PAGE3=$(yad --title "Mint Setup (3/3) - Design" --width=650 --form --separator="|" \
    --text "<b>Erscheinungsbild und Aufräumen</b>" \
    --field="Terminal Emulator:CB" "Alacritty!Standard" \
    --field="Desktop Theme:CB" "WhiteSur-Dark!Mint-Standard" \
    --field="Icons und Fonts (Kora, JetBrains NerdFont):CHK" TRUE \
    --field="Plank Dock:CHK" TRUE \
    --field="Firefox und Transmission entfernen:CHK" FALSE \
    --button="Zurück:2" --button="INSTALLIEREN:0" --button="Abbrechen:1")
RET=$?; [[ $RET -eq 1 ]] && exit 1; [[ $RET -eq 2 ]] && exec "$0"

################################################
# VARIABLEN PARSEN
################################################

# Page 1
DO_INFRA=$(echo "$PAGE1" | cut -d'|' -f1)
DO_CLI=$(echo "$PAGE1" | cut -d'|' -f2)
DO_SYSGUI=$(echo "$PAGE1" | cut -d'|' -f3)
DO_MONITORING=$(echo "$PAGE1" | cut -d'|' -f4)
DO_VIRT=$(echo "$PAGE1" | cut -d'|' -f5)
DO_XANMOD=$(echo "$PAGE1" | cut -d'|' -f6)
DO_PERF=$(echo "$PAGE1" | cut -d'|' -f7)
DO_FW=$(echo "$PAGE1" | cut -d'|' -f8)

# Page 2
DO_BROWSER=$(echo "$PAGE2" | cut -d'|' -f1)
DO_MESSENGER=$(echo "$PAGE2" | cut -d'|' -f2)
DO_MULTIMEDIA=$(echo "$PAGE2" | cut -d'|' -f3)
DO_DOCKER=$(echo "$PAGE2" | cut -d'|' -f4)
DO_VSCODE=$(echo "$PAGE2" | cut -d'|' -f5)
DO_LAZYGIT=$(echo "$PAGE2" | cut -d'|' -f6)
SEL_JETBRAINS=$(echo "$PAGE2" | cut -d'|' -f7)
DO_GAMING=$(echo "$PAGE2" | cut -d'|' -f8)
DO_CLOUD=$(echo "$PAGE2" | cut -d'|' -f9)
DO_VPN=$(echo "$PAGE2" | cut -d'|' -f10)

# Page 3
SEL_TERM=$(echo "$PAGE3" | cut -d'|' -f1)
SEL_THEME=$(echo "$PAGE3" | cut -d'|' -f2)
DO_ASSETS=$(echo "$PAGE3" | cut -d'|' -f3)
DO_PLANK=$(echo "$PAGE3" | cut -d'|' -f4)
DO_CLEANUP=$(echo "$PAGE3" | cut -d'|' -f5)

################################################
# EXECUTION - PAGE 1
################################################

if [[ "$DO_INFRA" == "TRUE" ]]; then
    print_section "Installing Infrastructure"
    install_apt_packages \
        git curl wget apt-transport-https ca-certificates \
        build-essential cmake clangd cmake default-jre
fi

if [[ "$DO_CLI" == "TRUE" ]]; then
    print_section "Installing CLI Power-Tools"
    install_apt_packages htop btop mc neofetch unzip unrar p7zip-full tree cpu-checker
fi

if [[ "$DO_SYSGUI" == "TRUE" ]]; then
    print_section "Installing System GUI Apps"
    install_apt_packages gparted keepassxc putty grub2-theme-mint
fi

if [[ "$DO_MONITORING" == "TRUE" ]]; then
    print_section "Installing Monitoring Tools"
    install_apt_packages lm-sensors xsensors smartmontools wavemon
fi

if [[ "$DO_VIRT" == "TRUE" ]]; then
    print_section "Installing Virt-Manager"
    install_apt_packages virt-manager
fi

if [[ "$DO_XANMOD" == "TRUE" ]]; then
    print_section "Installing XanMod Kernel V3"
    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -vo /etc/apt/keyrings/xanmod-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/xanmod-release.list
    sudo apt update
    install_apt_packages linux-xanmod-x64v3
fi

if [[ "$DO_PERF" == "TRUE" ]]; then
    print_section "Optimizing Performance"
    
    # Preload
    install_apt_packages preload

    # ZRAM
    install_apt_packages systemd-zram-generator

    # ZRAM Generator config
    sudo tee /etc/systemd/zram-generator.conf > /dev/null <<EOF
[zram0]
zram-size = min(2048, ram / 4)
compression-algorithm = zstd
swap-priority = 100
EOF

    sudo systemctl daemon-reexec
    sudo systemctl restart systemd-zram-setup@zram0.service || true

    # Sysctl
    sudo tee /etc/sysctl.d/99-mint-performance.conf > /dev/null <<EOF
vm.swappiness=10
vm.vfs_cache_pressure=50
EOF

    sudo sysctl --system

    # BFQ only for SATA
    sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null <<EOF
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="bfq"
EOF

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    print_success "Performance tuning applied."
fi

if [[ "$DO_FW" == "TRUE" ]]; then
    print_section "Configuring firewall"
    install_apt_packages ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
fi

################################################
# EXECUTION - PAGE 2
################################################

if [[ "$DO_BROWSER" == "TRUE" ]]; then
    print_section "Installing Google Chrome"
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    install_apt_packages ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
fi

if [[ "$DO_MESSENGER" == "TRUE" ]]; then
    print_section "Installing Messenger Client (WasIstLos)"
    WA_VERSION=$(curl -s "https://api.github.com/repos/xeco23/WasIstLos/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    wget https://github.com/xeco23/WasIstLos/releases/latest/download/wasistlos_${WA_VERSION}_amd64.deb
    install_apt_packages ./wasistlos_${WA_VERSION}_amd64.deb
    rm wasistlos_${WA_VERSION}_amd64.deb
fi

if [[ "$DO_MULTIMEDIA" == "TRUE" ]]; then
    print_section "Installing Multimedia Apps"
    install_apt_packages vlc gimp gimp-help-de
fi

if [[ "$DO_DOCKER" == "TRUE" ]]; then
    print_section "Installing Docker"

    # Get Ubuntu base codename
    source /etc/os-release
    UBUNTU_BASE_CODENAME=$(awk -F= '/UBUNTU_CODENAME/ {print $2}' /etc/os-release)

    # Keyring directory
    sudo install -m 0755 -d /etc/apt/keyrings

    # Add Docker’s official GPG key
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add repository
    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $UBUNTU_BASE_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

    sudo apt update

    install_apt_packages \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    # Add current user to docker group
    sudo usermod -aG docker "$USER"

    print_success "Docker installed successfully."
    print_success "Log out and log back in so docker group permissions apply."
fi

if [[ "$DO_VSCODE" == "TRUE" ]]; then
    print_section "Installing Visual Studio Code"
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update
    install_apt_packages code
    mkdir -p ~/.local/share/nemo/actions
    cat <<EOF > ~/.local/share/nemo/actions/open_in_vscode.nemo_action
[Nemo Action]
Name=Öffnen in VS Code
Exec=code %F
Icon-Name=com.visualstudio.code
Selection=any
Extensions=any;
Dependencies=code;
EOF
fi

if [[ "$DO_LAZYGIT" == "TRUE" ]]; then
    print_section "Installing Lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
fi

install_clion() {
    print_section "Installing CLion"
    clion_version=$(curl -s "https://data.services.jetbrains.com/products/releases?code=CL&latest=true&type=release" | grep -Po '"version":"\K[0-9.]+')
    if wget "https://download.jetbrains.com/cpp/CLion-${clion_version}.tar.gz"; then
        mkdir -p ~/.clion
        tar xvzf CLion-${clion_version}.tar.gz -C ~/.clion --strip-components=1
        rm CLion-${clion_version}.tar.gz
    else
        print_error "Download of CLion ${clion_version} failed."
    fi
    mkdir -p ~/.local/share/nemo/actions
    cat <<EOF > ~/.local/share/nemo/actions/open_in_clion.nemo_action
[Nemo Action]
Name=Öffnen in CLion
Exec=$HOME/.clion/bin/clion %F
Icon-Name=com.jetbrains.CLion
Selection=any
Extensions=any;
EOF
}

install_idea() {
    print_section "Installing IntelliJ IDEA Community"
    idea_version=$(curl -s "https://data.services.jetbrains.com/products/releases?code=IIC&latest=true&type=release" | grep -Po '"version":"\K[0-9.]+')
    if wget "https://download.jetbrains.com/idea/ideaIC-${idea_version}.tar.gz"; then
        mkdir -p ~/.idea
        tar xvzf ideaIC-${idea_version}.tar.gz -C ~/.idea --strip-components=1
        rm ideaIC-${idea_version}.tar.gz
    else
        print_error "Download of IntelliJ IDEA ${idea_version} failed."
    fi
}

if [[ "$SEL_JETBRAINS" != "Keine" ]]; then
    case "$SEL_JETBRAINS" in
        "CLion")
            install_clion
            ;;
        "IntelliJ")
            install_idea
            ;;
        "Beide")
            install_clion
            install_idea
            ;;
    esac
fi

if [[ "$DO_GAMING" == "TRUE" ]]; then
    print_section "Installing Native Gaming Stack (AMD)"

    # Enable 32-bit support (required for Steam & Proton)
    if ! dpkg --print-foreign-architectures | grep -q i386; then
        sudo dpkg --add-architecture i386
        sudo apt update
    fi

    # Steam
    install_apt_packages steam steam-devices

    # Vulkan / Mesa stack (AMD)
    install_apt_packages \
        mesa-vulkan-drivers \
        mesa-utils \
        vulkan-tools \
        libvulkan1 \
        libvulkan1:i386

    # Tools
    install_apt_packages \
        gamemode \
        mangohud \
        goverlay

    sudo systemctl enable gamemoded 2>/dev/null || true

    print_success "Native AMD gaming stack installed."
fi

if [[ "$DO_CLOUD" == "TRUE" ]]; then
    mkdir -p ~/Nextcloud
    mkdir -p ~/Tresor
    print_section "Installing Nextcloud Client and gocryptfs"
    install_apt_packages gnome-calendar nextcloud-desktop gocryptfs libsecret-tools
    if [ -f "$SCRIPT_DIR/.local/bin/gcfs.sh" ]; then
        install -m 755 "$SCRIPT_DIR/.local/bin/gcfs.sh" ~/.local/bin/gcfs.sh
    fi
fi

if [[ "$DO_VPN" == "TRUE" ]]; then
    print_section "Installing NordVPN"
    sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
fi

################################################
# EXECUTION - PAGE 3
################################################

if [[ "$DO_ASSETS" == "TRUE" ]]; then
    if [[ "$XDG_CURRENT_DESKTOP" != *"Cinnamon"* ]]; then
        print_error "Appearance setup skipped (not Cinnamon)."
        exit 0
    fi

    print_section "Installing Fonts & Icons"
    
    # JetBrains Mono Nerd Font
    if [ ! -d ~/.fonts/JetBrainsMono ]; then
        print_section "Downloading JetBrains Mono Nerd Font."
        FONT_URL=$(curl -s https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest | grep "browser_download_url.*JetBrainsMono.zip" | cut -d '"' -f 4)
        wget -qO /tmp/JetBrainsMono.zip "$FONT_URL"
        mkdir -p ~/.fonts/JetBrainsMono
        unzip -o /tmp/JetBrainsMono.zip -d ~/.fonts/JetBrainsMono
        rm /tmp/JetBrainsMono.zip
        install_apt_packages fonts-inter fonts-jetbrains-mono fonts-symbola
        fc-cache -f
        sleep 3
        gsettings set org.cinnamon.desktop.interface font-name "Inter Regular 10"
        gsettings set org.gnome.desktop.interface document-font-name "Inter Regular 10"
        gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono Regular 10"
        gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "Inter Display Regular 10"
        gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0
        print_success "Nerd Fonts installed."
    fi

    # Kora Icon Theme
    if [ ! -d ~/.icons/kora ]; then
        print_section "Installing Kora Icons."
        cd ~/.icons
        git clone https://github.com/bikass/kora.git --depth=1
        gsettings set org.cinnamon.desktop.interface icon-theme "kora"
        print_success "Kora Icons installed and applied."
    fi
fi

if [[ "$SEL_THEME" == "WhiteSur-Dark" ]]; then
    print_section "Installing WhiteSur GTK Theme"
    
    # Abhängigkeiten für WhiteSur Installer
    install_apt_packages gtk2-engines-murrine gtk2-engines-pixbuf sassc
    
    TEMP_THEME_DIR=$(mktemp -d)
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git "$TEMP_THEME_DIR" --depth=1
    
    # Installation (Dark-Version, Cinnamon optimiert)
    bash "$TEMP_THEME_DIR/install.sh" -d ~/.themes -t all -s standard -c Dark
    
    # Theme anwenden
    gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
    gsettings set org.cinnamon.theme name "WhiteSur-Dark"
    
    rm -rf "$TEMP_THEME_DIR"
    print_success "WhiteSur Theme applied."
fi

if [[ "$SEL_TERM" == "Alacritty" ]]; then
    print_section "Installing terminal tools"
    install_apt_packages alacritty zsh
    if [ -d "$SCRIPT_DIR/.config/alacritty" ]; then
        cp -R "$SCRIPT_DIR/.config/alacritty" ~/.config/
        chown -R "$USER:$USER" ~/.config/alacritty
    fi
    gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"
fi

if [[ "$DO_PLANK" == "TRUE" ]]; then
    print_section "Setting up panels"
    # Install Plank Reloaded (zquestz repo)
    if ! dpkg -l | grep -q plank-reloaded; then
        curl -fsSL https://zquestz.github.io/ppa/ubuntu/KEY.gpg \
            | sudo gpg --dearmor -o /usr/share/keyrings/zquestz-archive-keyring.gpg

        echo "deb [signed-by=/usr/share/keyrings/zquestz-archive-keyring.gpg] https://zquestz.github.io/ppa/ubuntu ./" \
            | sudo tee /etc/apt/sources.list.d/zquestz.list

        sudo apt update
        install_apt_packages plank-reloaded
    fi

    # Plank Reloaded Autostart
    mkdir -p ~/.config/autostart
    cat > ~/.config/autostart/plank-reloaded.desktop <<EOF
[Desktop Entry]
Type=Application
Exec=sh -c "sleep 3 && plank"
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Plank Reloaded Dock
Comment=Start Plank Reloaded Dock at login
EOF

    # Only one top panel
    gsettings set org.cinnamon panels-enabled "['1:0:top']"
    gsettings set org.cinnamon panels-height "['1:26']"
    gsettings set org.cinnamon panels-autohide "['1:false']"

    # Applets
    TARGET_DIR="$HOME/.local/share/cinnamon/applets"
    mkdir -p "$TARGET_DIR"

    # Bash Sensors
    wget -q https://cinnamon-spices.linuxmint.com/files/applets/bash-sensors@pkkk.zip -O bash-sensors.zip
    unzip -o bash-sensors.zip -d "$TARGET_DIR"

    # Sensors@claudiux
    wget -q https://cinnamon-spices.linuxmint.com/files/applets/Sensors@claudiux.zip -O sensors-claudiux.zip
    unzip -o sensors-claudiux.zip -d "$TARGET_DIR"

    rm bash-sensors.zip sensors-claudiux.zip

    gsettings set org.cinnamon enabled-applets \
        "['panel1:left:0:menu@cinnamon.org:0',
        'panel1:left:1:separator@cinnamon.org:1',
        'panel1:left:2:grouped-window-list@cinnamon.org:2',
        'panel1:right:0:systray@cinnamon.org:3',
        'panel1:right:1:xapp-status@cinnamon.org:4',
        'panel1:right:2:notifications@cinnamon.org:5',
        'panel1:right:3:printers@cinnamon.org:6',
        'panel1:right:4:removable-drives@cinnamon.org:7',
        'panel1:right:5:keyboard@cinnamon.org:8',
        'panel1:right:6:favorites@cinnamon.org:9',
        'panel1:right:7:network@cinnamon.org:10',
        'panel1:right:8:sound@cinnamon.org:11',
        'panel1:right:9:power@cinnamon.org:12',
        'panel1:right:10:calendar@cinnamon.org:13',
        'panel1:right:12:Sensors@claudiux:14',
        'panel1:right:13:bash-sensors@pkkk:15']"

    # Bash Sensors config
    SOURCE_SENSOR_CONFIG="$SCRIPT_DIR/.config/cinnamon/spices/bash-sensors@pkkk/config.json"

    if [ -f "$SOURCE_SENSOR_CONFIG" ]; then
        INSTANCE_ID=$(gsettings get org.cinnamon enabled-applets \
            | grep -o "bash-sensors@pkkk:[0-9]*" \
            | grep -o "[0-9]*")

        if [ -n "$INSTANCE_ID" ]; then

            TARGET_SENSOR_DIR="$HOME/.config/cinnamon/spices/bash-sensors@pkkk"
            mkdir -p "$TARGET_SENSOR_DIR"

            cp "$SOURCE_SENSOR_CONFIG" "$TARGET_SENSOR_DIR/${INSTANCE_ID}.json"
            chmod 644 "$TARGET_SENSOR_DIR/${INSTANCE_ID}.json"

            print_success "Bash Sensors config applied to instance $INSTANCE_ID."

        else
            print_error "Could not determine bash-sensors instance ID."
        fi
    else
        print_error "Source bash-sensors config not found."
    fi

    # Plank Reloaded settings
    gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ icon-size 36
    gsettings set net.launchpad.plank.dock.settings:/net/launchpad/plank/docks/dock1/ theme 'Gtk+'
fi

if [[ "$DO_CLEANUP" == "TRUE" ]]; then
    print_section "Final Cleanup"
    sudo apt purge -y firefox firefox-locale-de
    sudo apt purge -y transmission-*
    sudo apt autoremove -y
    sudo apt autoclean
fi

print_success "Installation abgeschlossen! Log: $LOGFILE"
yad --info --title "Fertig!" --text "Das System wurde erfolgreich konfiguriert. 

Es wird empfohlen, das System jetzt neu zu starten, um alle Änderungen (Kernel, Docker-Gruppen, Themes) zu aktivieren." --width=400 --image="system-reboot"
