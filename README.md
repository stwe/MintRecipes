# 🧰 Linux Mint Post-Installation Setup Script

A comprehensive Bash script to automate post-installation setup for **Linux Mint**.  
Includes essential tools, development environments, appearance tweaks, and application installation — all selectable via a friendly **whiptail** interface or a `--all` flag.

---

## ✨ Features

- Easy interactive selection or full automation (`--all`)
- System update and essential utilities
- Developer tools (Neovim, Git, LazyVim, Lazygit, Docker, etc.)
- IDEs: IntelliJ IDEA, CLion, Visual Studio Code
- Alternative terminal setup (Alacritty + Zsh)
- Multimedia and messaging apps
- Flatpak-based gaming setup (Steam, Lutris)
- Optional removal of Firefox and BitTorrent client
- NordVPN installation
- Nextcloud + gocryptfs
- Firewall setup (UFW)
- Desktop theming:
  - **Kora** icons
  - **WhiteSur** GTK theme
  - **JetBrainsMono Nerd Font**
  - Wallpaper configuration

---

## 🚀 Usage

### 1. Download the script

```bash
git clone https://github.com/stwe/MintRecipes.git
cd MintRecipes
chmod +x install.sh
```

### 2. Run the script

#### With interactive menu:

```bash
./install.sh
```

#### Install everything (non-interactive):

```bash
./install.sh --all
```

---

## 📋 Prerequisites

- Linux Mint (tested with current versions)
- Sudo privileges
- Internet connection

The script checks for required tools and installs them if needed (`whiptail`, `flatpak`, etc.).

---

## 🗂️ Structure

Each feature group is modular, handled in its own function inside the script.  
Selected options are applied in the order defined in the menu.

---

## 💡 Notes

- The script creates folders like `~/Bilder`, `~/.local/bin`, `~/.config`, etc.
- Fonts and themes are downloaded from GitHub and applied automatically.
- Some tools (e.g. `Lazygit`, `CLion`) fetch the latest version dynamically.

---

## ⚠️ Disclaimer

Use this script at your own risk.  
While it has been tested with Linux Mint, system configurations may vary.  
Review the code before executing.

---

## ✅ License

MIT License
