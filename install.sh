#!/bin/bash

# ################################################
# Colors for better readability
# ################################################

RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

print_section() {
    echo ""
    echo -e "${CYAN}========== $1 ==========${NC}"
    echo ""
}

print_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# ################################################
# Check sudo
# ################################################

if ! sudo -v; then
    print_error "Sudo is required but not available. Exiting."
    exit 1
fi

# ################################################
# Check flatpak
# ################################################

if ! command -v flatpak >/dev/null 2>&1; then
    print_error "Flatpak is not installed or not in PATH."
    exit 1
fi

# ################################################
# Install whiptail if not available
# ################################################

if ! command -v whiptail >/dev/null 2>&1; then
    print_error "Whiptail is not installed. Installing now..."
    sudo apt update
    sudo apt install -y whiptail
fi

# ################################################
# Create directories
# ################################################

print_section "Create directories..."
mkdir -p ~/Bilder
mkdir -p ~/.local/bin
mkdir -p ~/.config ~/.fonts ~/.icons ~/.themes

# ################################################
# Check for --all argument
# ################################################

ALL_INSTALL=false
if [[ "$1" == "--all" ]]; then
    ALL_INSTALL=true
fi

# ################################################
# Show interactive menu or select everything
# ################################################

if [ "$ALL_INSTALL" = true ]; then
    OPTIONS="update essential monitoring terminal devtools pge_deps neovim lazygit clion idea chrome messenger multimedia nextcloud nordvpn docker vscode gaming virt_manager firefox_remove bittorrent_remove"
else
    OPTIONS=$(whiptail --title "Installation Menu" --checklist \
    "Select the components you want to install:" 20 78 15 \
    "update" "System Update & Upgrade" ON \
    "essential" "Essential Tools" ON \
    "monitoring" "Monitoring Tools" ON \
    "terminal" "Alternative terminal Alacritty, Zsh" ON \
    "devtools" "Development Tools" ON \
    "pge_deps" "olcPixelGameEngine dependencies" OFF \
    "neovim" "Neovim with LazyVim" ON \
    "lazygit" "Lazygit (Git UI)" ON \
    "clion" "CLion IDE" OFF \
    "idea" "IntelliJ IDEA Community Edition" OFF \
    "chrome" "Google Chrome Browser" ON \
    "messenger" "Messenger Client (WasIstLos)" ON \
    "multimedia" "Multimedia Applications (VLC, GIMP, etc.)" ON \
    "nextcloud" "Nextcloud Client & gocryptfs" ON \
    "nordvpn" "NordVPN Setup" OFF \
    "docker" "Docker Engine" OFF \
    "vscode" "Visual Studio Code" OFF \
    "gaming" "Steam" OFF \
    "virt_manager" "Manage virtual machines with virt-manager" OFF \
    "firefox_remove" "Remove Firefox" ON \
    "bittorrent_remove" "Remove BitTorrent client (Transmission)" ON 3>&1 1>&2 2>&3)

    exitstatus=$?
    if [ $exitstatus != 0 ]; then
        print_error "Installation cancelled."
        exit 1
    fi
fi

# ################################################
# Install functions
# ################################################

install_update() {
    print_section "Updating system..."
    sudo apt update
    sudo apt upgrade -y
}

install_essential() {
    print_section "Installing essential tools..."
    sudo apt install -y htop mc neofetch wget curl keepassxc unrar tree gparted grub2-theme-mint putty apt-transport-https ca-certificates unzip vulkan-tools cpu-checker
}

install_monitoring() {
    print_section "Installing monitoring tools..."
    sudo apt install -y lm-sensors xsensors fonts-symbola smartmontools wavemon
}

install_terminal() {
    print_section "Installing alternative terminal..."
    sudo apt install -y alacritty zsh
}

install_devtools() {
    print_section "Installing development tools..."
    sudo apt install -y build-essential git cmake default-jre doxygen graphviz doxygen-gui
    cp -R .config/alacritty ~/.config
}

install_pge_deps() {
    print_section "Installing olcPixelGameEngine dependencies..."
    sudo apt install -y libx11-dev libgl1-mesa-dev libpng-dev
}

install_neovim() {
    print_section "Installing Neovim with LazyVim..."
    sudo apt install -y neovim luarocks ripgrep fd-find
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
}

install_lazygit() {
    print_section "Installing Lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit
}

install_clion() {
    print_section "Installing CLion..."
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
Icon=com.jetbrains.CLion
Selection=any
Extensions=any;
EOF
}

install_idea() {
    print_section "Installing IntelliJ IDEA Community..."
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
    print_section "Installing Google Chrome..."
    wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    sudo apt install -y ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
}

install_messenger() {
    print_section "Installing Messenger Client (WasIstLos)..."
    WA_VERSION=$(curl -s "https://api.github.com/repos/xeco23/WasIstLos/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    wget https://github.com/xeco23/WasIstLos/releases/latest/download/wasistlos_${WA_VERSION}_amd64.deb
    sudo apt install -y ./wasistlos_${WA_VERSION}_amd64.deb
    rm wasistlos_${WA_VERSION}_amd64.deb
}

install_multimedia() {
    print_section "Installing multimedia applications..."
    sudo apt install -y vlc gimp gimp-help-de
}

install_nextcloud() {
    mkdir -p ~/Nextcloud
    mkdir -p ~/Tresor
    print_section "Installing Nextcloud Client and gocryptfs..."
    sudo apt install -y gnome-calendar nextcloud-desktop gocryptfs libsecret-tools
    cp .local/bin/gcfs.sh ~/.local/bin
}

install_nordvpn() {
    print_section "Installing NordVPN..."
    curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh | sh
}

install_docker() {
    print_section "Installing Docker..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_vscode() {
    print_section "Installing Visual Studio Code..."
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    sudo apt update
    sudo apt install -y code
    mkdir -p ~/.local/share/nemo/actions
    cat <<EOF > ~/.local/share/nemo/actions/open_in_vscode.nemo_action
[Nemo Action]
Name=Öffnen in VS Code
Exec=code %F
Icon=com.visualstudio.code
Selection=any
Extensions=any;
Dependencies=code;
EOF
}

install_gaming() {
    print_section "Installing Steam..."
    sudo apt install -y steam-devices
    sudo flatpak install -y com.valvesoftware.Steam
    sudo flatpak install -y net.lutris.Lutris
    sudo flatpak install -y net.davidotek.pupgui2
    sudo flatpak install -y com.github.tchx84.Flatseal
}

install_libvirt() {
    print_section "Installing virt-manager..."
    sudo apt install -y virt-manager
}

remove_firefox() {
    print_section "Removing Firefox..."
    sudo apt purge -y firefox firefox-locale-*
}

remove_bittorrent() {
    print_section "Removing BitTorrent client (Transmission)..."
    sudo apt purge -y transmission-*
}

setup_firewall() {
    print_section "Setting up the firewall..."
    sudo apt install -y ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw enable
}

setup_appearance() {
    print_section "Setting up system appearance..."

    # Download icons
    print_section "Downloading icons..."
    cd ~/.icons
    git clone https://github.com/bikass/kora.git .
    rm -rf .git .github

    # Download GTK theme
    print_section "Downloading GTK theme..."
    cd ~/.themes
    git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
    cd WhiteSur-gtk-theme/release
    tar xvf WhiteSur-Dark.tar.xz -C ~/.themes
    cd ~/.themes
    rm -rf WhiteSur-gtk-theme

    # Download Nerd Font
    print_section "Downloading Nerd Font..."
    cd ~/.fonts
    wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
    unzip -o JetBrainsMono.zip -d JetBrainsMono
    rm JetBrainsMono.zip
    fc-cache -f

    # Download wallpaper
    print_section "Downloading wallpaper..."
    wallpaper_file_name="waterfall_grass_nature_92753_1920x1200.jpg"
    wallpaper_image_path="file://$HOME/Bilder/$wallpaper_file_name"
    cd ~/Bilder
    wget -nc https://images.wallpaperscraft.com/image/single/${wallpaper_file_name}

    # Apply settings
    print_section "Applying desktop settings..."
    gsettings set org.cinnamon.desktop.background picture-uri "$wallpaper_image_path"
    gsettings set org.cinnamon.desktop.interface icon-theme "kora"
    gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
    gsettings set org.cinnamon.theme name "WhiteSur-Dark"
    gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"
}

# ################################################
# Execute based on selection
# ################################################

[[ $OPTIONS == *"update"* ]] && install_update
[[ $OPTIONS == *"essential"* ]] && install_essential
[[ $OPTIONS == *"monitoring"* ]] && install_monitoring
[[ $OPTIONS == *"terminal"* ]] && install_terminal
[[ $OPTIONS == *"devtools"* ]] && install_devtools
[[ $OPTIONS == *"pge_deps"* ]] && install_pge_deps
[[ $OPTIONS == *"neovim"* ]] && install_neovim
[[ $OPTIONS == *"lazygit"* ]] && install_lazygit
[[ $OPTIONS == *"clion"* ]] && install_clion
[[ $OPTIONS == *"idea"* ]] && install_idea
[[ $OPTIONS == *"chrome"* ]] && install_chrome
[[ $OPTIONS == *"messenger"* ]] && install_messenger
[[ $OPTIONS == *"multimedia"* ]] && install_multimedia
[[ $OPTIONS == *"nextcloud"* ]] && install_nextcloud
[[ $OPTIONS == *"nordvpn"* ]] && install_nordvpn
[[ $OPTIONS == *"docker"* ]] && install_docker
[[ $OPTIONS == *"vscode"* ]] && install_vscode
[[ $OPTIONS == *"gaming"* ]] && install_gaming
[[ $OPTIONS == *"virt_manager"* ]] && install_libvirt
[[ $OPTIONS == *"firefox_remove"* ]] && remove_firefox
[[ $OPTIONS == *"bittorrent_remove"* ]] && remove_bittorrent

# ################################################
# Firewall && Theme
# ################################################

setup_firewall
setup_appearance

# ################################################
# Clean up
# ################################################

print_section "Cleaning up..."
sudo apt autoremove -y

# ################################################
# Completed
# ################################################

print_section "Installation completed. Have fun with Linux Mint! 🎉"
print_section "It's probably a good idea to restart your computer."
