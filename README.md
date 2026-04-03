# Linux Mint Post-Install Script

> ⚠️ Personal setup script – tailored to my own system and preferences.

This repository contains a **post-installation script for Linux Mint (Cinnamon)** that automates a large part of my personal system setup after a fresh install.

It is **not intended as a universal solution** or best-practice template. It reflects **my workflow, my hardware assumptions, and my preferences**.

<img src="https://github.com/stwe/MintRecipes/blob/main/pics/desktop.png" width="300" height="600" />

---

## ✨ What This Script Does

The script provides a **GUI-based installer (via YAD)** that lets you select different setup components across three categories:

### 1. System Base
- Core infrastructure tools (git, curl, build tools, etc.)
- CLI utilities (htop, btop, mc, etc.)
- GUI system tools (GParted, KeePassXC, etc.)
- Monitoring tools (lm-sensors, smartmontools, etc.)
- Optional virtualization support
- Optional **XanMod Kernel (V3)**
- Basic **performance tuning**
- Firewall setup (UFW)

---

### 2. Software & Development
- Google Chrome
- Messenger client (WasIstLos)
- Multimedia tools (VLC, GIMP)
- Docker (with proper repo setup)
- Visual Studio Code
- Lazygit
- JetBrains IDEs (CLion / IntelliJ)
- Native Linux gaming stack (AMD-focused)
- Nextcloud client + encryption setup
- NordVPN

---

### 3. Desktop & Appearance
- Terminal setup (Alacritty or Kitty + Zsh + Oh My Zsh + Powerlevel10k)
- GTK Theme (WhiteSur Dark)
- Icon theme (Kora)
- Nerd Fonts (JetBrains Mono)
- Plank Dock setup
- Remove Firefox and Transmission

---

## ⚙️ Performance Tweaks

This script applies several performance-related tweaks that are **based on my personal preferences and system behavior**:

- **Preload**
- **ZRAM (systemd-zram-generator)**
- **Custom sysctl tuning**
- **BFQ scheduler (for SSDs)**
- **XanMod kernel**

> ⚠️ These are not guaranteed to improve performance on every system.

---

## 🎮 Gaming Approach

For gaming, the script installs a **native Linux stack**:

- Steam
- Vulkan / Mesa drivers
- Gamemode
- MangoHud
- Goverlay

This setup is **optimized for AMD hardware**, which is what I’m using.

> ⚠️ NVIDIA systems are **not considered or tested** here. Driver handling and compatibility can differ significantly, so adjustments will be required if you're on NVIDIA.

No custom Proton builds or Lutris automation included (by design).

---

## 🎨 Desktop Customization

The script applies a **modern look** using:

- WhiteSur GTK theme
- Kora icons
- Custom fonts (Inter + JetBrains Mono Nerd Font)
- Optional dock (Plank)

However:

- 🖼️ **Wallpaper is NOT set** (left to the user)
- 🧩 **Panel layout is only partially configured**
- ⚙️ Further customization is expected to be done manually

---

## ⚠️ Important Notes

- This script is **heavily tailored to my personal setup**
- Assumes:
  - Linux Mint (Cinnamon)
  - Typical desktop hardware (AMD-friendly)
- Some parts are:
  - Written in **German**
  - Still **work in progress**
  - Not fully modular or reusable

---

## ▶️ Usage

```bash
chmod +x install2.sh
./install2.sh
```

- Do not run as root
- Requires sudo
- A GUI session is required (YAD)

---

## 📄 License

MIT License
