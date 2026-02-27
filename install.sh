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

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        print_error "$1 is required but not installed."
        exit 1
    }
}

install_apt_packages() {
    sudo apt install -y "$@"
}

is_selected() {
    echo "$OPTIONS" | grep -qw "\"$1\""
}

################################################
# PREP
################################################

require_command flatpak

if ! command -v whiptail >/dev/null; then
    sudo apt update
    install_apt_packages whiptail
fi

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

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
        unzip vulkan-tools cpu-checker
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

    # Keyring directory
    sudo install -m 0755 -d /etc/apt/keyrings

    # Add Docker’s official GPG key
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add repository using modern .sources format
    sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $UBUNTU_CODENAME
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

# oder native Pakete nehmen
install_gaming() {
    print_section "Installing Steam"
    install_apt_packages steam-devices
    flatpak install -y flathub com.valvesoftware.Steam
    flatpak install -y flathub net.lutris.Lutris
    flatpak install -y flathub net.davidotek.pupgui2
    flatpak install -y flathub com.github.tchx84.Flatseal
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
        git clone https://github.com/bikass/kora.git kora
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
    gsettings set org.gnome.desktop.interface desktop-font-name "Inter Regular 10"
    gsettings set org.cinnamon.desktop.wm.preferences titlebar-font "Inter Display Regular 10"

    gsettings set org.cinnamon.desktop.interface font-antialiasing "rgba"
    gsettings set org.cinnamon.desktop.interface font-rgba-order "rgb"
    gsettings set org.cinnamon.desktop.interface font-hinting "medium"
    gsettings set org.cinnamon.desktop.interface text-scaling-factor 1.0

    # Only set Alacritty if terminal was selected
    if [[ $OPTIONS == *"terminal"* ]]; then
        gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"
    fi
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
