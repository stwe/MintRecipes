#!/bin/bash

# ################################################
# PRE INSTALL BACKUP
# ################################################
# Thunderbird
# Chrome bookmarks
# KeepassXC file
# Bilder, Dokumente, Videos, CLionProjects
# ################################################

# ################################################
# Constants
# ################################################

clion_version="2024.2.2"
idea_version="2024.2.3"
whatsapp_version="1.6.5"
wallpaper_file_name=waterfall_grass_nature_92753_1920x1200.jpg
wallpaper_image_path="file://$HOME/Bilder/$wallpaper_file_name"

# ################################################
# Create directories
# ################################################

echo "Create directories..."
mkdir -p ~/Nextcloud
mkdir -p ~/Tresor
mkdir -p ~/Bilder
mkdir -p ~/.clion
mkdir -p ~/.idea
mkdir -p ~/.local/bin
mkdir -p ~/.config ~/.fonts ~/.icons ~/.themes

# ################################################
# Copy configuration files
# ################################################

echo "Copying configuration files..."
cp -R .config/alacritty ~/.config
cp -R .config/nvim ~/.config
cp .local/bin/gcfs.sh ~/.local/bin

# ################################################
# Install
# ################################################

# Update
echo "Updating the system..."
sudo apt update -y
sudo apt upgrade -y

# Nala
echo "Installing Nala..."
sudo apt install -y nala
sudo nala fetch

# Tools
echo "Installing essential tools..."
sudo nala install -y htop mc neofetch wget curl keepassxc unrar xpad tree gparted grub2-theme-mint eza putty apt-transport-https ca-certificates unzip

# Alacritty && Zsh
echo "Installing alternative terminal..."
sudo nala install -y alacritty zsh

# Dev stuff
echo "Installing development tools..."
sudo nala install -y build-essential git cmake openjdk-17-jre

# OlcPixelGameEngine dependencies
echo "Installing development libs..."
sudo nala install -y libglu1-mesa-dev libpng-dev

# Zed && Neovim
echo "Installing Zed and Neovim..."
curl -f https://zed.dev/install.sh | sh
sudo nala install -y neovim luarocks ripgrep

# Lazygit
echo "Installing Lazygit..."
LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
tar xf lazygit.tar.gz lazygit
sudo install lazygit /usr/local/bin
rm lazygit.tar.gz
rm lazygit

# CLion
echo "Installing CLion ${clion_version}..."
wget https://download.jetbrains.com/cpp/CLion-${clion_version}.tar.gz
tar xvzf CLion-${clion_version}.tar.gz -C ~/.clion
rm CLion-${clion_version}.tar.gz

# IntelliJ IDEA Community
echo "Installing IntelliJ IDEA Community ${idea_version}..."
wget https://download.jetbrains.com/idea/ideaIC-${idea_version}.tar.gz
tar xvzf ideaIC-${idea_version}.tar.gz -C ~/.idea
rm ideaIC-${idea_version}.tar.gz

# Google Chrome
echo "Installing Google Chrome..."
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo nala install -y ./google-chrome-stable_current_amd64.deb
rm google-chrome-stable_current_amd64.deb

# WhatsApp Client
echo "Installing WhatsApp Client ${whatsapp_version}..."
wget https://github.com/eneshecan/whatsapp-for-linux/releases/download/v${whatsapp_version}/whatsapp-for-linux_${whatsapp_version}_amd64.deb
sudo nala install -y ./whatsapp-for-linux_${whatsapp_version}_amd64.deb
rm whatsapp-for-linux_${whatsapp_version}_amd64.deb

# Multimedia
echo "Installing multimedia applications..."
sudo nala install -y vlc gimp gimp-help-de

# To use Nextcloud
echo "Installing Nextcloud Client and gocryptfs..."
sudo nala install -y gnome-calendar nextcloud-desktop gocryptfs libsecret-tools

# NordVPN
echo "Installing NordVPN..."
sh <(curl -sSf https://downloads.nordcdn.com/apps/linux/install.sh)

# Docker
echo "Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo nala update
sudo nala install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Visual Studio Code
echo "Installing Visual Studio Code..."
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
rm -f packages.microsoft.gpg
sudo nala update
sudo nala install -y code

# Ollama
curl -fsSL https://ollama.com/install.sh | sh

# ################################################
# Remove packages
# ################################################

echo "Removing unnecessary packages..."
sudo nala purge -y firefox firefox-locale-*
sudo nala purge -y transmission-*
sudo nala purge -y sticky

# ################################################
# Set up the firewall
# ################################################

echo "Setting up the firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# ################################################
# Icons, Themes, default Terminal, default Shell
# ################################################

echo "Download icons..."
cd ~/.icons
git clone https://github.com/bikass/kora.git .
rm -rf .git
rm -rf .github

echo "Download theme..."
cd ~/.themes
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git
cd WhiteSur-gtk-theme/release
tar xvf WhiteSur-Dark.tar.xz -C ~/.themes
cd ~/.themes
rm -rf WhiteSur-gtk-theme

echo "Download nerd font..."
cd ~/.fonts
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip
unzip JetBrainsMono.zip -d JetBrainsMono
rm JetBrainsMono.zip
fc-cache -f

echo "Download wallpaper..."
cd ~/Bilder
wget https://images.wallpaperscraft.com/image/single/${wallpaper_file_name}

echo "Setting desktop environment preferences..."
gsettings set org.cinnamon.desktop.background picture-uri "$wallpaper_image_path"
gsettings set org.cinnamon.desktop.interface icon-theme "kora"
gsettings set org.cinnamon.desktop.interface gtk-theme "WhiteSur-Dark"
gsettings set org.cinnamon.theme name "WhiteSur-Dark"
gsettings set org.cinnamon.desktop.default-applications.terminal exec "alacritty"

echo "Completed. Have fun with Linux Mint."
echo "It's probably a good idea to restart your computer."

# ################################################
# POST POST INSTALL
# ################################################
# 1) Create SSH Key
# 2) Setup gocrytpfs
# 3) Zsh / oh-my-zsh
# 4) nordvpn login / nordvpn connect

# ################################################
# 1) Create SSH Key
# ################################################

# generate a local SSH pair of keys: ssh-keygen -t ed25519 -C "blibla@blub.tt"
# Make sure ssh-agent is running in the background: eval "$(ssh-agent -s)"
# Add private key (the one without extension) to the ssh-agent: ssh-add ~/.ssh/id_ed25519
# Copy public key to your clipboard: cat ~/.ssh/example_keys.pub
# Add to GitHub: -> Settings -> SSH and GPG keys ->  New SSH key

# ################################################
# 2) Setup (new!!) gocrytpfs
# ################################################
#
# unmount if needed: fusermount -u ~/Tresor
# mkdir ~/Tresor
# mkdir ~/Nextcloud/.encrypted
# gocryptfs -init ~/Nextcloud/.encrypted
# secret-tool store --label="Nextcloud Tresor" password tresor
# secret-tool lookup password tresor
# gocryptfs ~/Nextcloud/.encrypted/ ~/Tresor/
# gcfs.sh add to autostart

# ################################################
# 3) Zsh / oh-my-zsh
# ################################################
#
# ## Go with Zsh - Reboot needed!!!!
# chsh -s $(which zsh)

# ## Install oh-my-zsh
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# ## Autosuggestion and syntax highlight plugins
# git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH/plugins/zsh-autosuggestions
# git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH/plugins/zsh-syntax-highlighting
# plugins=(git z zsh-autosuggestions zsh-syntax-highlighting)

# ## Install Powerlevel10k
# git clone https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
# ZSH_THEME="powerlevel10k/powerlevel10k"
