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
# DOWNLOAD HELPER
################################################

install_apt_packages() {
    print_section "Installing: $*"
    sudo apt install -y "$@" >>"$LOGFILE" 2>&1
}

download_curl() {
    local url="$1"
    local output="$2"

    print_section "Downloading $(basename "$output")"

    curl -fL --retry 3 --retry-delay 2 --progress-bar "$url" -o "$output" \
        || { print_error "Download failed: $url"; return 1; }
}

download_silent() {
    local url="$1"
    local output="$2"

    print_section "Downloading $(basename "$output")"

    curl -fsSL --retry 3 --retry-delay 2 "$url" -o "$output" >>"$LOGFILE" 2>&1 \
        || { print_error "Download failed: $url"; return 1; }
}

################################################
# PREPARE
################################################

sudo apt update
sudo apt upgrade -y

if ! command -v yad >/dev/null; then
    print_section "YAD missing – proceeding with installation..."
    install_apt_packages yad
    print_success "YAD successfully installed"
fi

mkdir -p ~/.local/bin ~/.fonts ~/.icons ~/.themes

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
    --field="Terminal Emulator:CB" "Alacritty!Kitty!Beide!Standard" \
    --field="Desktop Theme:CB" "WhiteSur-Dark!Mint-Standard" \
    --field="Icons und Fonts (Kora, JetBrains NerdFont):CHK" TRUE \
    --field="Plank Dock:CHK" TRUE \
    --field="SSH-Key generieren:CHK" FALSE \
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
DO_SSH=$(echo "$PAGE3" | cut -d'|' -f5)
DO_CLEANUP=$(echo "$PAGE3" | cut -d'|' -f6)

################################################
# EXECUTION - PAGE 1
################################################

if [[ "$DO_INFRA" == "TRUE" ]]; then
    print_section "Installing Infrastructure"
    install_apt_packages \
        git curl wget apt-transport-https ca-certificates \
        build-essential cmake clangd default-jre
    print_success "Infrastructure installed"
fi

if [[ "$DO_CLI" == "TRUE" ]]; then
    print_section "Installing CLI Power-Tools"
    install_apt_packages htop btop mc neofetch unzip unrar p7zip-full tree cpu-checker
    print_success "CLI Power-Tools installed"
fi

install_keepassxc_latest() {
    print_section "Installing KeePassXC"

    if ! grep -rq "phoerious/keepassxc" /etc/apt/sources.list.d 2>/dev/null; then
        sudo add-apt-repository -y ppa:phoerious/keepassxc
        sudo apt update
    fi

    install_apt_packages keepassxc

    print_success "KeePassXC installed"
}

if [[ "$DO_SYSGUI" == "TRUE" ]]; then
    print_section "Installing System GUI Apps"
    install_apt_packages gparted putty grub2-theme-mint
    install_keepassxc_latest
    print_success "System GUI Apps installed"
fi

if [[ "$DO_MONITORING" == "TRUE" ]]; then
    print_section "Installing Monitoring Tools"
    install_apt_packages lm-sensors xsensors smartmontools wavemon
    print_success "Monitoring Tools installed"
fi

if [[ "$DO_VIRT" == "TRUE" ]]; then
    print_section "Installing Virt-Manager"
    install_apt_packages virt-manager
    print_success "Virt-Manager installed"
fi

if [[ "$DO_XANMOD" == "TRUE" ]]; then
    print_section "Installing XanMod Kernel V3"

    download_silent "https://dl.xanmod.org/archive.key" "/tmp/xanmod.key"
    sudo gpg --dearmor -o /etc/apt/keyrings/xanmod-archive-keyring.gpg /tmp/xanmod.key
    rm /tmp/xanmod.key

    echo "deb [signed-by=/etc/apt/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/xanmod-release.list
    sudo apt update
    install_apt_packages linux-xanmod-x64v3

    print_success "XanMod Kernel installed"
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
vm.swappiness=100
vm.vfs_cache_pressure=50
vm.page-cluster=0
EOF

    sudo sysctl --system

    # HDD -> BFQ
    sudo tee /etc/udev/rules.d/60-ioschedulers.rules > /dev/null <<EOF
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
EOF

    sudo udevadm control --reload-rules
    sudo udevadm trigger

    # Compositing bypassed for full-screen
    gsettings set org.cinnamon.muffin unredirect-fullscreen-windows true

    print_success "Performance tuning applied"
fi

if [[ "$DO_FW" == "TRUE" ]]; then
    print_section "Configuring firewall"
    install_apt_packages ufw
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw --force enable
    print_success "Firewall configured"
fi

################################################
# EXECUTION - PAGE 2
################################################

if [[ "$DO_BROWSER" == "TRUE" ]]; then
    print_section "Installing Google Chrome"
    download_curl \
        "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb" \
        "google-chrome-stable_current_amd64.deb"
    install_apt_packages ./google-chrome-stable_current_amd64.deb
    rm google-chrome-stable_current_amd64.deb
    print_success "Google Chrome installed"
fi

if [[ "$DO_MESSENGER" == "TRUE" ]]; then
    print_section "Installing Messenger Client (WasIstLos)"

    download_silent "https://api.github.com/repos/xeco23/WasIstLos/releases/latest" "/tmp/wasistlos.json"
    WA_VERSION=$(grep -Po '"tag_name": "v\K[^"]*' /tmp/wasistlos.json)
    rm /tmp/wasistlos.json

    download_curl \
        "https://github.com/xeco23/WasIstLos/releases/latest/download/wasistlos_${WA_VERSION}_amd64.deb" \
        "wasistlos_${WA_VERSION}_amd64.deb"

    install_apt_packages ./wasistlos_${WA_VERSION}_amd64.deb
    rm wasistlos_${WA_VERSION}_amd64.deb

    print_success "Messenger Client installed"
fi

if [[ "$DO_MULTIMEDIA" == "TRUE" ]]; then
    print_section "Installing Multimedia Apps"
    install_apt_packages vlc gimp gimp-help-de
    print_success "Multimedia Apps installed"
fi

if [[ "$DO_DOCKER" == "TRUE" ]]; then
    print_section "Installing Docker"

    # Get Ubuntu base codename
    source /etc/os-release
    UBUNTU_BASE_CODENAME=$(awk -F= '/UBUNTU_CODENAME/ {print $2}' /etc/os-release)

    # Keyring directory
    sudo install -m 0755 -d /etc/apt/keyrings

    # Add Docker’s official GPG key
    download_silent "https://download.docker.com/linux/ubuntu/gpg" "/tmp/docker.asc"
    sudo install -m 644 /tmp/docker.asc /etc/apt/keyrings/docker.asc
    rm /tmp/docker.asc

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

    download_silent "https://packages.microsoft.com/keys/microsoft.asc" "/tmp/vscode.asc"
    gpg --dearmor < /tmp/vscode.asc > /tmp/packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 /tmp/packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    rm /tmp/vscode.asc /tmp/packages.microsoft.gpg

    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
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
print_success "Visual Studio Code installed"
fi

if [[ "$DO_LAZYGIT" == "TRUE" ]]; then
    print_section "Installing Lazygit"

    download_silent "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" "/tmp/lazygit.json"
    LAZYGIT_VERSION=$(grep -Po '"tag_name": "v\K[^"]*' /tmp/lazygit.json)
    rm /tmp/lazygit.json

    download_curl \
        "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" \
        "lazygit.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit.tar.gz lazygit

    print_success "Lazygit installed"
fi

install_clion() {
    print_section "Installing CLion"

    download_silent "https://data.services.jetbrains.com/products/releases?code=CL&latest=true&type=release" "/tmp/clion.json"
    clion_version=$(grep -Po '"version":"\K[0-9.]+' /tmp/clion.json)
    rm /tmp/clion.json

    download_curl \
        "https://download.jetbrains.com/cpp/CLion-${clion_version}.tar.gz" \
        "CLion-${clion_version}.tar.gz"
    mkdir -p ~/.clion
    tar xvzf CLion-${clion_version}.tar.gz -C ~/.clion --strip-components=1
    rm CLion-${clion_version}.tar.gz

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

    download_silent "https://data.services.jetbrains.com/products/releases?code=IIC&latest=true&type=release" "/tmp/idea.json"
    idea_version=$(grep -Po '"version":"\K[0-9.]+' /tmp/idea.json)
    rm /tmp/idea.json

    download_curl \
        "https://download.jetbrains.com/idea/ideaIC-${idea_version}.tar.gz" \
        "ideaIC-${idea_version}.tar.gz"
    mkdir -p ~/.idea
    tar xvzf ideaIC-${idea_version}.tar.gz -C ~/.idea --strip-components=1
    rm ideaIC-${idea_version}.tar.gz
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

    print_success "JetBrains IDE(s) installed ($SEL_JETBRAINS)"
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

if [ "$DO_CLOUD" = "TRUE" ]; then
    mkdir -p "$HOME/Nextcloud" "$HOME/Tresor"

    print_section "Setting up Nextcloud & Secure Vault Service"
    install_apt_packages gnome-calendar nextcloud-desktop gocryptfs libsecret-tools

    if ! secret-tool lookup password tresor >/dev/null 2>&1; then
        echo "No password for 'tresor' found in keyring."
        read -s -p "Please enter the master password for your vault: " TRESOR_PW
        echo ""
        printf "%s" "$TRESOR_PW" | secret-tool store --label="Gocryptfs Tresor" password tresor
        unset TRESOR_PW
        print_success "Password securely stored in keyring."
    fi

    if [ -f "$SCRIPT_DIR/.local/bin/gcfs.sh" ]; then
        install -m 700 "$SCRIPT_DIR/.local/bin/gcfs.sh" "$HOME/.local/bin/gcfs.sh"

        yad --title="Secure Vault Information" \
            --window-icon="security-high" \
            --width=450 \
            --text-align=left \
            --text="\n<b>The Vault setup is complete, but requires manual action later:</b>\n\n1. Launch <b>Nextcloud Desktop</b> and log in.\n2. Ensure your encrypted folder (e.g., <i>~/Nextcloud/Vault_Raw</i>) is synced.\n3. The <b>Tresor</b> will automatically mount via autostart once the files are present.\n\n<i>Note: The drive will remain empty until Nextcloud has finished downloading your vault data.</i>\n" \
            --button="Understood":0 &

        mkdir -p "$HOME/.config/autostart"
        ABSOLUTE_PATH="$HOME/.local/bin/gcfs.sh"

        cat <<EOF > "$HOME/.config/autostart/tresor.desktop"
[Desktop Entry]
Type=Application
Exec="$ABSOLUTE_PATH"
X-GNOME-Autostart-enabled=true
Name=Tresor
Comment=Mount Tresor
X-GNOME-Autostart-Delay=5
Icon=security-high
EOF

        chmod 644 "$HOME/.config/autostart/tresor.desktop"
    fi

    print_success "Cloud tools installed"
fi

if [[ "$DO_VPN" == "TRUE" ]]; then
    print_section "Installing NordVPN"

    download_silent "https://downloads.nordcdn.com/apps/linux/install.sh" "/tmp/nordvpn_install.sh"
    bash /tmp/nordvpn_install.sh -n >>"$LOGFILE" 2>&1 || print_error "NordVPN Installation fehlgeschlagen"
    rm /tmp/nordvpn_install.sh

    print_success "NordVPN installed"
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

        download_silent "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest" "/tmp/nerdfonts.json"
        FONT_URL=$(grep "browser_download_url.*JetBrainsMono.zip" /tmp/nerdfonts.json | cut -d '"' -f 4)
        rm /tmp/nerdfonts.json

        download_curl "$FONT_URL" "/tmp/JetBrainsMono.zip"
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

        print_success "Nerd Fonts installed"
    fi

    # Kora Icon Theme
    if [ ! -d ~/.icons/kora ]; then
        print_section "Installing Kora Icons."

        cd ~/.icons
        git clone https://github.com/bikass/kora.git

        mv kora/kora/* kora/
        rm -rf kora/kora

        gsettings set org.cinnamon.desktop.interface icon-theme "kora"

        print_success "Kora Icons installed and applied"
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
    print_success "WhiteSur Theme applied"
fi

install_alacritty() {
    print_section "Installing Alacritty"

    install_apt_packages alacritty

    if [ -d "$SCRIPT_DIR/.config/alacritty" ]; then
        cp -R "$SCRIPT_DIR/.config/alacritty" ~/.config/
        chown -R "$USER:$USER" ~/.config/alacritty
    fi

    print_success "Alacritty installed"
}

install_kitty() {
    print_section "Installing Kitty"

    # 1. Alte Version entfernen
    if dpkg -l | grep -q kitty; then
        sudo apt purge -y kitty kitty-terminfo
    fi

    # 2. Installer ausführen
    download_curl "https://sw.kovidgoyal.net/kitty/installer.sh" "/tmp/kitty_installer.sh"
    sh /tmp/kitty_installer.sh
    rm /tmp/kitty_installer.sh

    # 3. Symlinks für PATH
    mkdir -p ~/.local/bin
    ln -sf ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
    ln -sf ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten

    # 4. Konfiguration aus dem Repo kopieren
    if [ -d "$SCRIPT_DIR/.config/kitty" ]; then
        mkdir -p ~/.config/kitty
        cp -r "$SCRIPT_DIR/.config/kitty/." ~/.config/kitty/
        print_success "Kitty config copied from repo"
    fi

    # 4. Desktop-Icon für das Mint-Menü (Cinnamon) fixen
    mkdir -p ~/.local/share/applications
    cp ~/.local/kitty.app/share/applications/kitty.desktop ~/.local/share/applications/

    # Pfad zum Icon im Desktop-File korrigieren
    sed -i "s|Icon=kitty|Icon=$HOME/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" ~/.local/share/applications/kitty.desktop

    # Pfad zum Executable korrigieren
    sed -i "s|Exec=kitty|Exec=$HOME/.local/bin/kitty|g" ~/.local/share/applications/kitty.desktop

    print_success "Kitty installed and configured"
}

choose_default_terminal() {
    print_section "Selecting default terminal"

    yad --title="Select Default Terminal" \
        --width=400 \
        --center \
        --text="Please choose your default terminal:" \
        --button="Alacritty:0" \
        --button="Kitty:1" \
        --button="Cancel:2"

    case $? in
        0)
            gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"
            print_success "Alacritty set as default terminal"
            ;;
        1)
            gsettings set org.cinnamon.desktop.default-applications.terminal exec "$HOME/.local/bin/kitty"
            print_success "Kitty set as default terminal"
            ;;
        *)
            print_error "No selection made – default terminal unchanged"
            ;;
    esac
}

install_yazi() {
    print_section "Installing Yazi"

    # Latest Release JSON holen
    download_silent "https://api.github.com/repos/sxyazi/yazi/releases/latest" "/tmp/yazi.json"

    # Version extrahieren (z.B. 26.1.22)
    YAZI_VERSION=$(grep -Po '"tag_name": "v\K[^"]*' /tmp/yazi.json)

    # Passendes .deb Asset extrahieren
    YAZI_URL=$(grep -Po '"browser_download_url": "\K[^"]*x86_64-unknown-linux-gnu\.deb' /tmp/yazi.json)

    rm /tmp/yazi.json

    if [[ -z "$YAZI_URL" ]]; then
        print_error "Failed to find Yazi .deb download URL"
        return 1
    fi

    YAZI_DEB="/tmp/yazi_${YAZI_VERSION}.deb"

    download_curl "$YAZI_URL" "$YAZI_DEB"

    # Installation + Dependency Fix
    if ! sudo apt install -y "$YAZI_DEB" >>"$LOGFILE" 2>&1; then
        print_error "APT install failed, attempting fix..."
        sudo apt -f install -y >>"$LOGFILE" 2>&1
        install_apt_packages libimage-exiftool-perl
    fi

    rm -f "$YAZI_DEB"

    print_success "Yazi $YAZI_VERSION installed"
}

install_zsh() {
    print_section "Installing Zsh"

    install_apt_packages zsh

    ZSH_PATH=$(command -v zsh)
    if [[ "$SHELL" != "$ZSH_PATH" ]]; then
        sudo usermod -s "$ZSH_PATH" "$USER"
        print_success "Zsh set as default shell (effective after re-login)."
    fi

    print_success "Zsh installed"
}

install_omz() {
    print_section "Installing Oh My Zsh"

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_section "Installing Oh My Zsh"

        download_curl "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "/tmp/ohmyzsh.sh"
        RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh /tmp/ohmyzsh.sh
        rm /tmp/ohmyzsh.sh

        print_success "Oh My Zsh installed"
    fi

    # Ensure ZSH_CUSTOM is set globally
    export ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # Install Powerlevel10k
    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        print_section "Installing Powerlevel10k"

        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$ZSH_CUSTOM/themes/powerlevel10k" \
            || print_error "Powerlevel10k install failed"

        print_success "Powerlevel10k installed"
    fi

    # Install Zsh plugins
    print_section "Installing Zsh Plugins"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions" \
            || print_error "Autosuggestions install failed"
        print_success "Autosuggestions installed"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" \
            || print_error "Syntax highlighting install failed"
        print_success "Syntax highlighting installed"
    fi
}

apply_zsh_config() {
    print_section "Applying Zsh configuration"

    if [ -d "$SCRIPT_DIR/.config/zsh" ]; then
        mkdir -p ~/.config/zsh
        
        # Kopieren der Configs aus dem Repo ins System
        cp -r "$SCRIPT_DIR/.config/zsh/." ~/.config/zsh/
        
        # Symlinks setzen (Wichtig: -f erzwingt das Überschreiben)
        ln -sf ~/.config/zsh/.zshrc ~/.zshrc
        # Falls .p10k.zsh auch in .config/zsh liegt, von dort verlinken:
        ln -sf ~/.config/zsh/.p10k.zsh ~/.p10k.zsh

        print_success "Zsh config deployed and linked."
    else
        print_error "Zsh config source directory not found!"
    fi
}

if [[ "$SEL_TERM" != "Standard" ]]; then
    print_section "Installing terminal tools"

    case "$SEL_TERM" in
        "Alacritty")
            install_alacritty
            gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"
            ;;

        "Kitty")
            install_kitty
            gsettings set org.cinnamon.desktop.default-applications.terminal exec "$HOME/.local/bin/kitty"
            ;;

        "Beide")
            install_alacritty
            install_kitty
            choose_default_terminal
            ;;
    esac

    # Yazi nur bei Kitty oder Beide
    if [[ "$SEL_TERM" == "Kitty" || "$SEL_TERM" == "Beide" ]]; then
        install_yazi
    fi

    install_zsh
    install_omz
    apply_zsh_config

    print_success "Terminal environment setup complete ($SEL_TERM)"
fi

if [[ "$DO_PLANK" == "TRUE" ]]; then
    print_section "Setting up panels"

    # Install Plank Reloaded (zquestz repo)
    if ! dpkg -l | grep -q plank-reloaded; then
        download_silent "https://zquestz.github.io/ppa/ubuntu/KEY.gpg" "/tmp/plank.key"
        sudo gpg --dearmor -o /usr/share/keyrings/zquestz-archive-keyring.gpg /tmp/plank.key
        rm /tmp/plank.key

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
    download_silent "https://cinnamon-spices.linuxmint.com/files/applets/bash-sensors@pkkk.zip" "/tmp/bash-sensors.zip"
    unzip -o /tmp/bash-sensors.zip -d "$TARGET_DIR"

    # Sensors@claudiux
    download_silent "https://cinnamon-spices.linuxmint.com/files/applets/Sensors@claudiux.zip" "/tmp/sensors-claudiux.zip"
    unzip -o /tmp/sensors-claudiux.zip -d "$TARGET_DIR"

    rm /tmp/bash-sensors.zip /tmp/sensors-claudiux.zip

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

if [[ "$DO_SSH" == "TRUE" ]]; then
    print_section "Generating SSH Key"

    SSH_KEY="$HOME/.ssh/id_ed25519"

    if [[ -f "$SSH_KEY" ]]; then
        print_error "SSH Key already exists. Skipping generation."
    else
        SSH_EMAIL=$(yad --title="SSH Configuration" --window-icon="security-high" \
            --text="Please enter your email for the SSH key:" \
            --entry --entry-label="Email:" --entry-text="user@example.com" --width=400)

        if [[ -n "$SSH_EMAIL" ]]; then
            echo -e "${CYAN}ATTENTION: Please look at the terminal to set your SSH passphrase!${NC}"

            ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY"

            eval "$(ssh-agent -s)"
            ssh-add "$SSH_KEY"

            print_success "SSH Key generated successfully."
        else
            print_error "SSH Setup cancelled (no email provided)."
        fi
    fi
fi

if [[ "$DO_CLEANUP" == "TRUE" ]]; then
    print_section "Final Cleanup"
    sudo apt purge -y firefox firefox-locale-de
    sudo apt purge -y transmission-*
    sudo apt autoremove -y
    sudo apt autoclean
    print_success "Cleanup finished"
fi

print_success "Installation abgeschlossen! Log: $LOGFILE"
yad --info --title "Fertig!" --text "Das System wurde erfolgreich konfiguriert. 

Es wird empfohlen, das System jetzt neu zu starten, um alle Änderungen (Kernel, Docker-Gruppen, Themes) zu aktivieren." --width=400 --image="system-reboot"

# TODO
# Schreibtischschrift muss selbst gesetzt werden
# Hinting auf Mittel muss ueber die Gui gesetzt werden
# Conky
