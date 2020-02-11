#!/bin/sh

# function declarations
function update_config_and_keyrings() {
	# initial config
	echo "Downloading dependencies"
	echo "Defaults env_reset,psfeedback" >> /etc/sudoers # allow password feedback
	umount -l /etc/pacman.d/gnupg
	pacman -Sy gnupg archlinux-keyring artix-keyring --noconfirm
	rm -r /etc/pacman.d/gnupg
	pacman-key --init
	pacman-key --populate archlinux artix
	pacman -Scc --noconfirm
	wget https://raw.githubusercontent.com/g-n-x/step1n2/master/pkglist.txt
	wget https://raw.githubusercontent.com/g-n-x/step1n2/master/yaylist.txt
	wget https://raw.githubusercontent.com/g-n-x/step1n2/master/step2.sh
	reset # so pwfeedback is aplied
	PS1=""
}
export -f update_config_and_keyrings
function newl() {
	echo -e "\n"
}
export -f newl
update_config_and_keyrings # to avoid corrupted packages + aesthetics
pacman -Sy figlet parted --noconfirm
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
parted ${DISK_USED} mklabel msdos
parted ${DISK_USED} mkpart primary ext4 1MiB 100%
echo y|mkfs.ext4 ${DISK_USED}1
mount ${DISK_USED}1 /mnt
echo "$DISK_USED is your new-system's home"
export DISK_USED=$DISK_USED

newl

# base system
basestrap /mnt base base-devel $INIT_SYS elogind-${INIT_SYS} linux linux-firmware

fstabgen -U /mnt >> /mnt/etc/fstab

# move automation script files to new system
mv step2.sh /mnt/
mv pkglist.txt /mnt/
mv yaylist.txt /mnt/
# chroot into new system
# user will run source ./step2.sh in new system
artools-chroot /mnt

# this will run after step2.sh
umount -R /mnt
clear

# finished
figlet "Installation Complete!"
echo "rebooting in 5s"
sleep 5s
reboot
