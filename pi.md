# ################################################
# PRE INSTALL BACKUP
# ################################################
# Thunderbird
# Chrome bookmarks or use Floccus
# KeepassXC file + keyfile
# Bilder, Dokumente, Videos, CLionProjects
# ################################################

# ################################################
# POST POST INSTALL
# ################################################
# 1) Create SSH Key
# 2) Setup gocrytpfs
# 3) Zsh / oh-my-zsh
# 4) KeepassXC

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

# ################################################
# 4) KeepassXC
# ################################################

# Create keyfile:
# echo "YOURSTRING" | sha256sum /dev/stdin | cut -d " " -f 1 >> /path/to/keyfile.key

# Store password
# secret-tool store --label="KeepassXC" password keepass

# Autostart KeepassXC via Shell-Script
# PASSWORD=$(secret-tool lookup password keepass)
# echo $PASSWORD | /usr/bin/keepassxc --pw-stdin /path/to/your.kdbx --keyfile /path/to/keyfile.key > /path/to/autostart.log 2>&1

# Enable: Bei Programmstart Fenster minimieren
# Enable: Minimieren statt Programm zu beenden
# Enable: Taskleistensymbol anzeigen
