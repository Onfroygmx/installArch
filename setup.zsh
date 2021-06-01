#!/usr/bin/env zsh
#!/bin/zsh

fpath+="${0:A:h}/fn"

## Autoload zsh modules when they are referenced
#################################################
autoload -U colors && colors
autoload -Uz $fpath[-1]/*(.:t)

current_dir="${0:A:h}"

pck_install=$current_dir/pkgSetup.txt
log_full=$current_dir/log_full_setup.log
log_err=$current_dir/log_err_setup.log

## Debug:
# echo $fpath
# echo $fpath[-1]/*(.:t)
# exec > >(tee -a ${log_full} )
exec 2> >(tee -a ${log_err} >&2)


function setup {

    printf "$fg[cyan]Download additional packages and finalize instalation$reset_color\n\n"

    ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

    printf "\n\n$fg[yellow]Add Build folder, group, user$reset_color\n"
    groupadd builders

    useradd -m -G wheel,builders -s /bin/zsh -c "Main User" onf
    #useradd -o -u 0 -m -G wheel,builders -s /bin/zsh -c "Main User" onf

    printf "$fg[red]Set Password for Onf$reset_color\n\n"
    passwd onf

    mkdir -pv /srv/builds
    chgrp builders /srv/builds
    chmod 770 /srv/builds
    chmod +s /srv/builds

#    reflector -c FR,DE -a 1 -p http,https --sort rate --fastest 10 --download-timeout 10 --save /etc/pacman.d/mirrorlist
    # reflector -c FR,DE -a 12 -p http,https --sort rate --latest 10 --download-timeout 10 --save /etc/pacman.d/mirrorlist
    pacman -Sy --noconfirm - < $pck_install

    printf "$fg[cyan]Update keys, create mandb and locatedb$reset_color\n\n"
    pacman-key --init && pacman-key --populate
 #   sudo pacman-key --refresh-keys
    sudo mandb -c
    sudo updatedb

    printf "\n$fg[green]Finished Setup:$reset_color\n\n\n"

}
setup "$@"
