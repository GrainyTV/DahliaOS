# **Preinstall Actions**
- Enable root mode `sudo su`
- Select your preferred keyboard **$layout** `loadkeys $layout`
- Check network connectivity `ping artixlinux.org`
- Check wether you booted in UEFI mode `ls /sys/firmware/efi/efivars`

# **Partitioning**
- Find your **$device** `lsblk`
- Invoke partitioning tool `fdisk $device`
- Create your desired partitioning scheme e.g.
```
ESP - Efi System Partition [FAT32][EFI System]
SWP - Swap Space [SWAP][Linux swap]
ART - Artix Linux [EXT4][Linux filesystem]
TIN - Tiny11 [NTFS][Microsoft basic data]
```
- Verify results `lsblk -o NAME,LABEL,FSTYPE,PARTUUID`

# **Mounting**
- Mount created Linux partitions
```
swapon -L SWP
mount -L ART /mnt
mount -L ESP /mnt/boot --mkdir
```

# **System Clock**
- Synchronize the computer's real-time clock `dinitctl start ntpd`

# **Installing Base System**
- Install init system packages `basestrap /mnt base base-devel dinit elogind-dinit`
- Install kernel packages `basestrap /mnt linux linux-firmware`
- Install microcode package either for AMD or Intel processors
```
basestrap /mnt amd-ucode
basestrap /mnt intel-ucode
```
- Generate fstab file from mountpoints `fstabgen -U /mnt >> /mnt/etc/fstab`
- Chroot into the newly installed environment `artix-chroot /mnt`

# **Configuring Base System**
- Install file editor of choice e.g. `pacman -S micro`

## **Region Related**
- Configure system clock with your **$region** and **$city**
```
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc
```
- Make keyboard layout persistent `micro /etc/vconsole.conf`
- Enable necessary localization
```
micro /etc/locale.gen
locale-gen
```

## **Boot Manager**
- Install Git CLI and refind `pacman -S git refind`
- Create folders at fallback location `mkdir -p /boot/EFI/BOOT/icons`
- Copy refind binary there `cp /usr/share/refind/refind_x64.efi /boot/EFI/BOOT/bootx64.efi`
- Clone this repository `git clone https://github.com/GrainyTV/DahliaOS.git /home/dahlia`
- Copy refind config file `cp /home/dahlia/refind/refind.conf /boot/EFI/BOOT/refind.conf`
- Copy asset files `cp /home/dahlia/refind/icons/*.png /boot/EFI/BOOT/icons`

## **User**
- Create a new **$user** `useradd -m $user`
- Give it a password `passwd $user`
- Add **$user** to wheel group `usermod -aG wheel $user`
- Link micro to vi `ln -s /usr/bin/micro /usr/bin/vi`
- Invoke visudo `visudo`
- Uncomment line `# %wheel ALL=(ALL:ALL) ALL`
- Verify results `sudo -lU $user`

## **Network**
- Select a **$hostname** `micro /etc/hostname`
- Find your permanent IP **$address** `ip addr`
- Fill out the hosts file `micro /etc/hosts`
```
127.0.0.1    localhost
::1          localhost
$address     $hostname.localdomain $hostname
```
- Install networkmanager `pacman -S networkmanager-dinit`

# **Booting Into Fresh System**
- Leave chroot mode `exit`
- Unmount all mounts recursively `umount -R /mnt`
- Reboot `reboot`
