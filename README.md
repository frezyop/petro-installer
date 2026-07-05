# 🚀 Pterodactyl & Wings Auto-Installer (Frezy Edition)

![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Pterodactyl](https://img.shields.io/badge/Pterodactyl-Panel-0D47A1?style=for-the-badge&logo=pterodactyl&logoColor=white)
![Cloudflare](https://img.shields.io/badge/Cloudflare-Tunnels-F38020?style=for-the-badge&logo=cloudflare&logoColor=white)

An interactive, fully automated CLI tool designed to streamline the installation and configuration of **Pterodactyl Panel** and **Wings**. Built for efficiency, this script eliminates the repetitive tasks of manual setups, automatically handling configurations, dependencies, and SSL patching for Cloudflare Tunnels.

---

## ✨ Features

* **Interactive CLI Menu:** A clean, easy-to-navigate terminal interface.
* **Fully Automated Panel Setup:** Uses `expect` to automatically answer installer prompts (database, user, FQDN) based on your initial inputs.
* **Smart Wings Installation:** 
  * Choose between installing Wings on the **Same VPS** (shares SSL certificates) or a **Different VPS** (generates fresh certificates).
* **Cloudflare Tunnel Ready:** Automatically generates local SSL certificates and patches Nginx/Wings configs to allow seamless integration with Cloudflare "No TLS Verify" tunnels.
* **Safe Uninstallation:** Built-in options to safely remove the Panel or Wings without blindly destroying your OS.

---

## 📋 Prerequisites

Before running the script, ensure you have:
1. A fresh installation of **Ubuntu** or **Debian**.
2. **Root (sudo)** access to your VPS.
3. Your Panel/Node domains ready (e.g., `testpanel.frezy.xyz`, `node.frezy.xyz`).
4. Access to your Cloudflare Zero Trust Dashboard (for tunnel creation).

---

## ⚡ Quick Start

Run the following command as `root` in your terminal to launch the installer. 

*(Note: Click the copy button on the top right of the code block below to ensure you don't copy any markdown brackets by mistake)*

```bash <(curl -fsSL https://raw.githubusercontent.com/frezyop/petro-installer/main/petro-installer.sh)```
