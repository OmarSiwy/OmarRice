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

nmcli device wifi list
nmcli device wifi connect <SSID> password <password>
ping 8.8.8.8 # To make sure you are connected

git clone https://github.com/OmarSiwy/OmarRice
cd OmarRice
chmod +x RiceSetup.sh
sudo ./RiceSetup.sh
```

