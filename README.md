# **OmarRice**

## **Installation Guide for a Fresh Arch Linux Install**

### **Step 1: Connect to the Internet**

#### **Option 1: Wired Connection**

- Simply plug in an Ethernet cable. It should automatically connect.

#### **Option 2: Wireless Connection**

Use the following commands in the terminal:

```Bash
iwctl
device list
station <device-name> scan
station <device-name> get-networks
station <device-name> connect <SSID> <password>

ping archlinux.org # Ensure this works
```

### **Step 2: Download and run the archlinux install script**

```Bash
curl -LO https://raw.githubusercontent.com/OmarSiwy/OmarRice/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

**Remove your iso boot drive while the computer reboots**

### **3. After Rebooting**

**Login is root -> root**

```Bash
systemctl start NetworkManager
systemctl enable NetworkManager

# Create a new user
sudo useradd -m -G wheel,users,storage,power,video,audio,input <USERNAME>
sudo passwd <USERNAME>
su - <USERNAME>

# if wireless
nmcli device wifi list
nmcli device wifi connect <SSID> password <password>
ping 8.8.8.8 # To make sure you are connected

git clone https://github.com/OmarSiwy/OmarRice
cd OmarRice
chmod +x RiceSetup.sh
./RiceSetup.sh
```

### **4. Post-Install**

**Install Windows Apps**:

```Bash
# https://github.com/lgili/Install-Altium-Linux
# https://www.geeksforgeeks.org/how-to-install-windows-apps-in-linux/
```

**Install Windows Games**:

```Bash
# Two Options
sudo pacman -S Lutris

# 1. If the game is on Steama
# Download the game using Lutris, right click the game, select properties, select the compatbility tab
# Tick Force the use of a specific Steam play compatibility tool

# 2. If the game isn't on Steam
# Download the setup executable
# Add it as a non-steam game to steam
# Run it in compatbility mode using proton-experimental
```

**Github Configuration**:

```Bash
gh auth login
git config –global user.name “Your Name”
git config –global user.email “youremail@domain.com”
```
