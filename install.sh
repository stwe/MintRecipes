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

################################################
# ERROR HANDLING
################################################

trap 'echo -e "${RED}Error on line $LINENO. Exit code: $?${NC}"' ERR

print_section() {
    echo ""
    echo -e "${CYAN}========== $1 ==========${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

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

UBUNTU_CODENAME=$(lsb_release -cs)

################################################
# HELPERS
################################################

install_apt_packages() {
    sudo apt install -y "$@"
}

is_selected() {
    echo "$OPTIONS" | grep -qw "\"$1\""
}

################################################
# PREP
################################################

if ! command -v whiptail >/dev/null; then
    sudo apt update
    install_apt_packages whiptail
fi

mkdir -p ~/Bilder ~/.local/bin ~/.config ~/.fonts ~/.icons ~/.themes

################################################
# OPTIONS
################################################

ALL_INSTALL=false
if [[ "${1:-}" == "--all" ]]; then
    ALL_INSTALL=true
fi

if [ "$ALL_INSTALL" = true ]; then
    OPTIONS="\
    update \
    essential \
    monitoring \
    terminal \
    devtools \
    lazygit \
    clion \
    idea \
    chrome \
    messenger \
    multimedia \
    nextcloud \
    nordvpn \
    docker \
    vscode \
    gaming \
    xanmod \
    virt_manager \
    firefox_remove \
    bittorrent_remove"
else
    OPTIONS=$(whiptail --title "Mint Post Install" --checklist \
    "Select components:" 20 78 15 \
    "update" "System Update" ON \
    "essential" "Essential Tools" ON \
    "monitoring" "Monitoring Tools" ON \
    "terminal" "Alacritty + Zsh" ON \
    "devtools" "Build Tools" ON \
    "lazygit" "Lazygit" ON \
    "clion" "CLion IDE" OFF \
    "idea" "IntelliJ IDEA Community Edition" OFF \
    "chrome" "Google Chrome" ON \
    "messenger" "Messenger Client (WasIstLos)" ON \
    "multimedia" "VLC + GIMP" ON \
    "nextcloud" "Nextcloud + gocryptfs" ON \
    "nordvpn" "NordVPN" OFF \
    "docker" "Docker Engine" OFF \
    "vscode" "Visual Studio Code" OFF \
    "gaming" "Steam + Tools" OFF \
    "xanmod" "XanMod Kernel V3" OFF \
    "virt_manager" "Manage virtual machines with virt-manager" OFF \
    "firefox_remove" "Remove Firefox" ON \
    "bittorrent_remove" "Remove BitTorrent client (Transmission)" ON \
    3>&1 1>&2 2>&3) || exit 1
fi

# ################################################
# Install functions
# ################################################

install_update() {
    print_section "Updating system"
    sudo apt update
    sudo apt upgrade -y
}

install_essential() {
    print_section "Installing essential tools"
    install_apt_packages \
        htop mc neofetch wget curl keepassxc \
        unrar tree gparted \
        grub2-theme-mint putty apt-transport-https ca-certificates \
        unzip cpu-checker
}

install_monitoring() {
    print_section "Installing monitoring tools"
    install_apt_packages lm-sensors xsensors smartmontools wavemon
}

install_terminal() {
    print_section "Installing terminal tools"
    install_apt_packages alacritty zsh
    if [ -d "$SCRIPT_DIR/.config/alacritty" ]; then
        cp -R "$SCRIPT_DIR/.config/alacritty" ~/.config/
    fi
}

install_devtools() {
    print_section "Installing development tools"
    install_apt_packages build-essential git cmake default-jre doxygen doxygen-gui clangd
}

install_lazygit() {
    print_section "Installing Lazygit"
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
}

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
        tar xvzf ideaIC-${idea_version}.tar.gz -C ~/.idea
        rm ideaIC-${idea_version}.tar.gz
    else
        print_error "Download of IntelliJ IDEA ${idea_version} failed."
    fi
}

install_chrome() {
    print_section "Installing Google Chrome"
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    install_apt_packages ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
}

install_messenger() {
    print_section "Installing Messenger Client (WasIstLos)"
    WA_VERSION=$(curl -s "https://api.github.com/repos/xeco23/WasIstLos/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    wget https://github.com/xeco23/WasIstLos/releases/latest/download/wasistlos_${WA_VERSION}_amd64.deb
    install_apt_packages ./wasistlos_${WA_VERSION}_amd64.deb
    rm wasistlos_${WA_VERSION}_amd64.deb
}

install_multimedia() {
    print_section "Installing multimedia applications"
    install_apt_packages vlc gimp gimp-help-de
}

install_nextcloud() {
    mkdir -p ~/Nextcloud
    mkdir -p ~/Tresor
    print_section "Installing Nextcloud Client and gocryptfs"
    install_apt_packages gnome-calendar nextcloud-desktop gocryptfs libsecret-tools
    if [ -f "$SCRIPT_DIR/.local/bin/gcfs.sh" ]; then
        install -m 755 "$SCRIPT_DIR/.local/bin/gcfs.sh" ~/.local/bin/gcfs.sh
    fi
}

install_nordvpn() {
    print_section "Installing NordVPN"
    sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)
}

install_docker() {
    print_section "Installing Docker"

    # Get Ubuntu base codename (important for Mint)
    UBUNTU_BASE_CODENAME=$(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)

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
}

install_vscode() {
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
}

install_gaming() {
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

    # Performance tools
    install_apt_packages \
        gamemode \
        mangohud \
        goverlay

    sudo systemctl enable gamemoded 2>/dev/null || true

    print_success "Native AMD gaming stack installed."
}

install_xanmod() {
    print_section "Installing XanMod Kernel V3"
    wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -vo /etc/apt/keyrings/xanmod-archive-keyring.gpg
    echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/xanmod-release.list
    sudo apt update
    install_apt_packages linux-xanmod-x64v3
}

install_libvirt() {
    print_section "Installing virt-manager"
    install_apt_packages virt-manager
}

remove_firefox() {
    print_section "Removing Firefox"
    sudo apt purge -y firefox firefox-locale-*
}

remove_bittorrent() {
    print_section "Removing BitTorrent client (Transmission)"
    sudo apt purge -y transmission-*
}

setup_firewall() {
    print_section "Configuring firewall"
    install_apt_packages ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
}

setup_appearance() {
    if [[ "$XDG_CURRENT_DESKTOP" != *"Cinnamon"* ]]; then
        print_error "Appearance setup skipped (not Cinnamon)."
        return
    fi

    print_section "Installing themes & icons"

    # Download icons
    print_section "Downloading icons"
    cd ~/.icons
    if [ ! -d kora ]; then
        git clone https://github.com/bikass/kora.git .
    fi
    rm -rf .git .github

    # Download GTK theme
    print_section "Downloading GTK theme"
    cd ~/.themes
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme/release
    if [ -f WhiteSur-Dark.tar.xz ]; then
        tar xvf WhiteSur-Dark.tar.xz -C ~/.themes
    else
        print_error "WhiteSur-Dark.tar.xz not found"
    fi
    cd ~/.themes
    rm -rf WhiteSur-gtk-theme

    # Download Fonts
    print_section "Downloading Fonts"
    cd ~/.fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip -d JetBrainsMono
    rm JetBrainsMono.zip
    install_apt_packages fonts-inter fonts-jetbrains-mono fonts-symbola
    fc-cache -f
    sleep 3

    # Download wallpaper
    print_section "Downloading wallpaper"
    wallpaper_file_name="buildings_village_lake_192651_1920x1080.jpg"
    wallpaper_image_path="file://$HOME/Bilder/$wallpaper_file_name"
    cd ~/Bilder
    wget -nc https://images.wallpaperscraft.com/image/single/${wallpaper_file_name}

    # Apply settings
    print_section "Applying desktop and font settings..."
    gsettings set org.cinnamon.desktop.background picture-uri "$wallpaper_image_path"
    gsettings set org.cinnamon.desktop.interface icon-theme "kora"
    gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
    gsettings set org.cinnamon.theme name "WhiteSur-Dark"

    gsettings set org.cinnamon.desktop.interface font-name "Inter Regular 10"
    gsettings set org.gnome.desktop.interface document-font-name "Inter Regular 10"
    gsettings set org.gnome.desktop.interface monospace-font-name "JetBrains Mono Regular 10"
    gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "Inter Display Regular 10"

    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0

    # Only set Alacritty if terminal was selected
    if [[ $OPTIONS == *"terminal"* ]]; then
        gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"
    fi
}

setup_dock() {
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

    # Autostart Dock
    cp /usr/share/applications/plank.desktop ~/.config/autostart/ 2>/dev/null || true

    # Panels: Only ONE top panel
    gsettings set org.cinnamon panels-enabled "['1:0:top']"
    gsettings set org.cinnamon panels-height "['1:26']"
    gsettings set org.cinnamon panels-autohide "['1:false']"

    # Applets
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
        'panel1:right:11:cornerbar@cinnamon.org:14',
        'panel1:right:12:Sensors@claudiux:15',
        'panel1:right:13:bash-sensors@pkkk:17']"
}

# ################################################
# EXECUTION
# ################################################

is_selected update && install_update
is_selected essential && install_essential
is_selected monitoring && install_monitoring
is_selected terminal && install_terminal
is_selected devtools && install_devtools
is_selected lazygit && install_lazygit
is_selected clion && install_clion
is_selected idea && install_idea
is_selected chrome && install_chrome
is_selected messenger && install_messenger
is_selected multimedia && install_multimedia
is_selected nextcloud && install_nextcloud
is_selected nordvpn && install_nordvpn
is_selected docker && install_docker
is_selected vscode && install_vscode
is_selected gaming && install_gaming
is_selected xanmod && install_xanmod
is_selected virt_manager && install_libvirt
is_selected firefox_remove && remove_firefox
is_selected bittorrent_remove && remove_bittorrent

# ################################################
# Firewall && Theme
# ################################################

setup_firewall
setup_appearance
setup_dock

# ################################################
# Clean up
# ################################################

print_section "Cleaning up"
sudo apt autoremove -y

# ################################################
# Completed
# ################################################

print_success "Installation completed. Have fun with Linux Mint! 🎉"
print_success "It's probably a good idea to restart your computer."
print_success "Log file: $LOGFILE"

# TODO
# Schreibtischschrift muss gesetzt werden
# Hinting auf Mittel muss ueber die Gui gesetzt werden
