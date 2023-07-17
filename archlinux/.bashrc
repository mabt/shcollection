# Umask
umask 022

# History
export HISTSIZE=10000000
export HISTCONTROL=ignoreboth:erasedups
export HISTIGNORE="w:exit:clear"
export CYAN=$(echo -e '\e[0;36m')
export NORMAL=$(echo -e '\e[0m')
export HISTTIMEFORMAT="${CYAN}[ %d/%m/%Y %H:%M:%S ]${NORMAL} "

# Default editor
export EDITOR=emacs

alias taocl='cat ~/Nextcloud/usefull/theartofcommandline.txt'
alias hyall='cat ~/Nextcloud/usefull/fm_hypervisors.txt'

# Alias
alias ls='ls --color'
alias grep='grep --color=auto'
alias rgrep='grep -r'
alias dig='dog'
