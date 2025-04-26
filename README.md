# 🐧 Linux Mint Post-Install Script

This script automates my typical post-installation setup on **Linux Mint**.

It installs a wide range of tools and applications, applies system themes, and configures useful defaults – so you can get straight to work without the hassle.

## ✅ Features

The script installs and configures:

- **Browsers**:
  - Google Chrome

- **Development tools**:
  - CLion
  - IntelliJ IDEA Community Edition
  - Visual Studio Code
  - Git, Neovim (with LazyVim), Lazygit, CMake, JRE, Docker

- **Utilities**:
  - htop, mc, KeepassXC, Alacritty, Zsh, GParted, smartmontools, sensors, etc.

- **Multimedia**:
  - VLC
  - GIMP (with German help files)

- **Cloud & Sync**:
  - Nextcloud client
  - gocryptfs

- **Messaging**:
  - A WhatsApp desktop client ([WasIstLos](https://github.com/xeco23/WasIstLos))

- **Aesthetics**:
  - [Kora icon theme](https://github.com/bikass/kora.git)
  - [WhiteSur-Dark GTK theme](https://github.com/vinceliuice/WhiteSur-gtk-theme.git)
  - Nerd fonts
  - A custom wallpaper from [WallpapersCraft](https://wallpaperscraft.com)

- **Security**:
  - UFW firewall setup
  - NordVPN install support

## 🚀 Usage

### 1. Make the script executable:

```bash
chmod +x ./pi.sh
```

### 2. Run it:

```bash
./pi.sh
```

## ⚠️ Disclaimer

This script makes system-level changes and installs third-party software. Use at your own risk and always review the contents before execution.

## 📂 License

MIT – feel free to adapt or contribute.
