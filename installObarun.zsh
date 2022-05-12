#!/usr/bin/env zsh
#!/bin/zsh
#    ___           _        _ _
#   |_ _|_ __  ___| |_ __ _| | |
#    | || '_ \/ __| __/ _` | | |
#    | || | | \__ \ || (_| | | |
#   |___|_| |_|___/\__\__,_|_|_|
#


fpath+="${0:A:h}/fn"

## Autoload zsh modules when they are referenced
#################################################
autoload -U colors && colors
autoload -Uz $fpath[-1]/*(.:t)

current_dir="${0:A:h}"

pck_install=$current_dir/pkgInstallObarun.txt
log_full=$current_dir/log_full_install.log
log_err=$current_dir/log_err_install.log

## Debug:
# echo $fpath
# echo $fpath[-1]/*(.:t)
# exec > >(tee -a ${log_full} )
exec 2> >(tee -a ${log_err} >&2)


function install_arch {

    printf "\n$fg[green]Installation of Obarun/Arch will start:$reset_color\n\n\n"

    partition_delete /dev/sda
    partition_drive /dev/sda
    ## Call external function for formating
    partition_format /dev/sda1 fat
    partition_format /dev/sda2 ext4
    partition_format /dev/sda3 ext4

    partition_mount

    printf "$fg[green]Partitions:$reset_color\n\n"

    lsblk -f

    printf "$fg[green]Prepare Pacman$reset_color\n\n"

    prepare_pacman $pck_install

    printf "$fg[cyan]Pacstrap Installation$reset_color\n\n"
    pacstrap -C pacman.conf.obarun /mnt base linux linux-firmware - < $pck_install

    genfstab -t PARTUUID -p /mnt >> /mnt/etc/fstab

    printf "$fg[green]Base Installation done, now we will proceed with basic setup before reboot$reset_color\n\n"

    setup_etckeeper

    setup_locale
    arch-chroot /mnt locale-gen
    arch-chroot /mnt locale
    arch-chroot /mnt etckeeper commit "Configure locale and keyboard"

    # Setup boot tree
    arch-chroot /mnt 66-tree -n boot
    arch-chroot /mnt 66-enable -t boot boot@system
    arch-chroot /mnt 66-env -t boot -r 'HOSTNAME=!obarun' boot@system
    arch-chroot /mnt 66-env -t boot -r 'KEYMAP=!be-latin1' boot@system
    arch-chroot /mnt 66-env -t boot -r 'TZ=Europe/Paris' boot@system
    arch-chroot /mnt 66-enable -t boot -F boot@system

    # Setup Net tree
    arch-chroot /mnt 66-tree -nE net
    arch-chroot /mnt 66-enable -t net dhcpcd
    arch-chroot /mnt 66-enable -t net sshd
    # Setup timedate
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
    #arch-chroot /mnt timedatectl set-timezone Europe/Paris
    #arch-chroot /mnt timedatectl set-ntp true
    arch-chroot /mnt hwclock --systohc --utc
    arch-chroot /mnt hwclock --verbose
    #arch-chroot /mnt timedatectl status
    arch-chroot /mnt etckeeper commit "Configure Date/Time and synchronization"


    setup_network "obarun"
    #arch-chroot /mnt hostnamectl set-hostname arch
    #arch-chroot /mnt hostnamectl status
    arch-chroot /mnt hostname
    arch-chroot /mnt etckeeper commit "Configure Network files"

    mkdir -p /mnt/boot/loader/entries

    setup_obarun

    user_root
    arch-chroot /mnt etckeeper commit "Configure Boot loader and root user"

    ### Copy pacman configs to new setup
    #cp /etc/pacman.conf /mnt/etc/
    #cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

    ### Configuration files for network
    cp conf/etc/systemd/network/10-* /mnt/etc/systemd/network/

    ### Set a welcome motd
    cp conf/etc/profile.d/archmotd.sh /mnt/etc/profile.d/

    setup_config
    arch-chroot /mnt etckeeper commit "Configure other base functionalities"

    ### Enable Service for startup
    #arch-chroot /mnt systemctl enable sshd 2>&1
    #arch-chroot /mnt systemctl enable systemd-networkd 2>&1
    #arch-chroot /mnt systemctl enable systemd-networkd-wait-online 2>&1
    #arch-chroot /mnt systemctl enable systemd-resolved 2>&1
    #arch-chroot /mnt systemctl enable systemd-timesyncd 2>&1
    #arch-chroot /mnt etckeeper commit "Enable services and set root PWD"

    printf "$fg[green]Base Configuration finished, unmount and reboot$reset_color\n\n"

    cp -r $PWD /mnt/root

}
install_arch "$@"
