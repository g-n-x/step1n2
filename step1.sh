#!/bin/sh
# function declarations
function newl() {
	echo -e "\n"
}
export -f newl
function update_config_and_keyrings() {
	loadkeys br-abnt2 # bcuz yes
	clear
	newl
	echo "Downloading dependencies"
	newl
	# initial config
	echo "Defaults env_reset,pwfeedback" >> /etc/sudoers # allow password feedback
	umount -l /etc/pacman.d/gnupg
	pacman -Sy gnupg archlinux-keyring artix-keyring --noconfirm
	rm -r /etc/pacman.d/gnupg
	pacman-key --init
	pacman-key --populate archlinux artix
	pacman -Scc --noconfirm
	pacman -S wget --noconfirm
	
	# changed from wget to curl bcuz of libnettle.so.8 problems
	curl https://raw.githubusercontent.com/g-n-x/step1n2/master/pkglist.txt -o pkglist.txt
	curl https://raw.githubusercontent.com/g-n-x/step1n2/master/yaylist.txt -o yaylist.txt
	curl https://raw.githubusercontent.com/g-n-x/step1n2/master/step2.sh -o step2.sh
	reset # so pwfeedback is aplied
	PS1=""
}
export -f update_config_and_keyrings
function base_install() {
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
    
    # removed -n switch bcuz it makes the file go emptyy
    # why im using double quotes: https://askubuntu.com/questions/76808/how-do-i-use-variables-in-a-sed-command
    sed -i "s/s6/$INIT_SYS/" pkglist.txt

    newl

    # linux selection
    echo -e "Which Linux:\n \
        linux-lts\n \
        linux"
    read -p "> " LINUX_TYPE
    export LINUX_TYPE=$LINUX_TYPE
    
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
    basestrap /mnt base base-devel $INIT_SYS elogind-${INIT_SYS} $LINUX_TYPE linux-firmware

    fstabgen -U /mnt >> /mnt/etc/fstab

    # move automation script files to new system
    mv step2.sh /mnt/
    mv pkglist.txt /mnt/
    mv yaylist.txt /mnt/
    # chroot into new system and source ./step2.sh in new system
    artools-chroot /mnt chmod 755 step2.sh
    artools-chroot /mnt /step2.sh
}

# call the main function
base_install

# this will run after step2.sh
umount -R /mnt
clear

# finished
figlet "Installation Complete!"
echo "rebooting in 5s"
sleep 5s
reboot
