# OmarRice

## To install off a fresh archlinux install:

### Ensure you have a solid internet connection

```Bash
# Option #1: Use a wired connection

# Option #2: use a wireless connection
iwctl
device list
station <device-name> scan
station <device-name> get-networks
station <device-name> connect <SSID> <password>

ping archlinux.org # Ensure this works
```

```Bash
curl -LO https://github.com/OmarSiwy/OmarRice/blob/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

