# OmarRice

# After running pacman

1. Load the keys based on your operating system:

```Bash
localectl list-keymaps
loadkeys keymap
```

2. Connect to the internet wirelessly, or plugin cable (skip this step)

```Bash
iwctl

device list
station <device-name> scan
station <device-name> get-networks
station <device-name> connect <SSID>

# To test:
ping 8.8.8.8
```

3. Set the console font

```Bash
setfont Lat2-Terminus16
```

4. Partioning Setup:

```Bash
# UEFI or BIOS, if this runs you are in UEFI:
ls /sys/firmware/efi/efivars

# Check name of hard disk
fdisk -l
fdisk name
```

5. A. Partioning with UEFI

Press <kbd>g</kbd> to create a new GUID Partition Table (GPT).

| Mount point | Partition                   | Partition type | Suggested size      |
| ----------- | --------------------------- | -------------- | ------------------- |
| /mnt/boot   | /dev/_efi_system_partition_ | uefi           | At least 300 MiB    |
| [SWAP]      | /dev/_swap_partition_       | swap           | More than 512 MiB   |
| /mnt        | /dev/_root_partition_       | linux          | Remainder of device |

##### Create boot partition

1. Press <kbd>n</kbd>.
1. Press <kbd>Enter</kbd> to select the default partition number.
1. Press <kbd>Enter</kbd> to use the default first sector.
1. Enter _+300M_ for the last sector.
1. Press <kbd>t</kbd> and choose 1 and write _uefi_.

##### Create swap partition

1. Press <kbd>n</kbd>.
1. Press <kbd>Enter</kbd> to select the default partition number.
1. Press <kbd>Enter</kbd> to use the default first sector.
1. Enter _+512M_ for the last sector.
1. Press <kbd>t</kbd> and choose 2 and write _swap_.

##### Create root partition

1. Press <kbd>n</kbd>.
1. Press <kbd>Enter</kbd> to select the default partition number.
1. Press <kbd>Enter</kbd> to use the default first sector.
1. Enter <kbd>Enter</kbd> to use the default last sector.
1. Press <kbd>t</kbd> and choose 3 and write _linux_.

⚠️\ **When you are done partitioning don't forget to press <kbd>w</kbd> to save the changes!**

After partitioning check if the partitions have been created using `fdisk -l`.

##### Partition formatting

```
$ mkfs.ext4 /dev/<root_partition>
$ mkswap /dev/<swap_partition>
$ mkfs.fat -F 32 /dev/<efi_system_partition>
```

##### Mounting the file system

```
$ mount /dev/<root_partition> /mnt
$ mount --mkdir /dev/<efi_system_partition> /mnt/boot
$ swapon /dev/<swap_partition>
```

5. B. Partioning with MBR

Press <kbd>o</kbd> to create a new MBR partition table.

We will do it according to the example layout of the Arch wiki:

| Mount point | Partition             | Partition type | Suggested size      |
| ----------- | --------------------- | -------------- | ------------------- |
| [SWAP]      | /dev/_swap_partition_ | swap           | More than 512 MiB   |
| /mnt        | /dev/_root_partition_ | linux          | Remainder of device |

##### Create swap partition

1. Press <kbd>n</kbd>.
1. Press <kbd>Enter</kbd> to select the default partition number.
1. Press <kbd>Enter</kbd> to select the default primary partition type.
1. Press <kbd>Enter</kbd> to use the default first sector.
1. Enter _+512M_ for the last sector.
1. Press <kbd>t</kbd> and choose 1 and write _swap_.

##### Create root partition

1. Press <kbd>n</kbd>.
1. Press <kbd>Enter</kbd> to select the default partition number.
1. Press <kbd>Enter</kbd> to select the default primary partition type.
1. Press <kbd>Enter</kbd> to use the default first sector.
1. Enter <kbd>Enter</kbd> to use the default last sector.
1. Press <kbd>t</kbd> and choose 2 and write _linux_.

##### Make partition bootable

Press <kbd>a</kbd> and choose 2 to make the root partition bootable.

⚠️\ **When you are done partitioning don't forget to press <kbd>w</kbd> to save the changes!**

After partitioning check if the partitions have been created using `fdisk -l`.

##### Partition formatting

```
$ mkfs.ext4 /dev/<root_partition>
$ mkswap /dev/<swap_partition>
```

##### Mounting the file system

```
$ mount /dev/<root_partition> /mnt
$ swapon /dev/<swap_partition>
```

6. Default Packages:

```Bash
pacstrap -K /mnt base base-devel linux linux-firmware e2fsprogs dhcpcd networkmanager sof-firmware git neovim man-db man-pages texinfo

```

