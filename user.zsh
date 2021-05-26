#!/usr/bin/env zsh
#!/bin/zsh

fpath+="${0:A:h}/fn"

## Autoload zsh modules when they are referenced
#################################################
autoload -U colors && colors
autoload -Uz $fpath[-1]/*(.:t)

current_dir="${0:A:h}"

pck_install=$current_dir/pkgUser.txt
log_full=$current_dir/log_full_user.log
log_err=$current_dir/log_err_user.log

## Debug:
# echo $fpath
# echo $fpath[-1]/*(.:t)
# exec > >(tee -a ${log_full} )
exec 2> >(tee -a ${log_err} >&2)

function user {

    

}
user "$@"
