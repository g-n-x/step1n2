#!/bin/sh

# function declarations
function update_keyrings() {
	# initial config
	echo "Downloading dependencies"
	echo "Defaults env_reset,psfeedback" >> /etc/sudoers # allow password feedback
	umount -l /etc/pacman.d/gnupg
	pacman -Sy gnupg archlinux-keyring artix-keyring --noconfirm
	rm -r /etc/pacman.d/gnupg
	pacman-key --init
	pacman-key --populate archlinux artix
	pacman -Scc
	wget https://raw.githubusercontent.com/g-n-x/step1n2/master/pkglist.txt
	wget https://raw.githubusercontent.com/g-n-x/step1n2/master/yaylist.txt
	wget https://raw.githubusercontent.com/g-n-x/step1n2/master/step2.sh
}
export -f update_keyrings
function newl() {
	echo -e "\n"
}
export -f newl
update_keyrings
pacman -Sy figlet parted --noconfirm
reset # so pwfeedback is aplied
PS1=""
clear

# banner
figlet Artix Linux auto-installation

# init selection
echo -e "Please select your init system of choice: \n \
	openrc\n \
	runit\n \
	s6"

read -p "> " INIT_SYS
echo "Your system will have $INIT_SYS as PID1 now"
export INIT_SYS=$INIT_SYS


newl

# partition creation
lsblk | echo -e "Available disks:\n \
	/dev/`awk '/disk/{print$1};'`"
read -p "> " DISK_USED
# TODO: parted is not functioning properly
parted ${DISK_USED} mklabel msdos
parted ${DISK_USED} mkpart primary ext4 1MiB 100%
mkfs.ext4 ${DISK_USED}1
mount ${DISK_USED}1 /mnt
echo "$DISK_USED is your new-system's home"
export DISK_USED=$DISK_USED

newl

# base system
basestrap /mnt base base-devel $INIT_SYS elogind-${INIT_SYS} linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab
mv step2.sh /mnt/
mv pkglist.txt /mnt/
mv yaylist.txt /mnt/
artools-chroot /mnt # chroot into new system

# after step2
umount -R /mnt
clear
figlet "Installation Complete!"
echo "rebooting in 5s"
sleep 5s
reboot
