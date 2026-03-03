if [ "$TERM" = "xterm" ]; then
    #we're on the system console or maybe telnetting in
    #export PS1=$path_zy
    export PS1="\[\033]2;\h@\u \w \007 \033[33;1m\]\u@\h \033[35;1m\t\033[0m \[\033[36;1m\]\$PWD\[\033[0m\]\n\[\e[32;1m\]$ \[\e[0m\]"
    #export PS1="\[\033]2;\h:\u \w\007\033[33;1m\]\u \033[35;1m\t\033[0m \[\033[36;1m\]\$PWD\[\033[0m\]\n\[\e[32;1m\]$ \[\e[0m\]"
elif [ "$TERM" == "screen" ]; then
    export PS1="\[\033]2;\h@\u \w \007 \033[33;1m\]\u@\h \033[35;1m\t\033[0m \[\033[36;1m\]\$PWD\[\033[0m\]\n\[\e[32;1m\]$ \[\e[0m\]"
elif [ "$TERM" == "xterm-256color" ]; then
    export PS1="\[\033]2;\h@\u \w \007\033[33;1m\]\u@\h \033[35;1m\t\033[0m \[\033[36;1m\]\$PWD\[\033[0m\]\n\[\e[32;1m\]$ \[\e[0m\]"
    alias sz='/usr/bin/tsz'
    alias rz='/usr/bin/trz'
else
    export PS1="\[\033]2;\h@\u \w \007 \033[33;1m\]\u@\h \033[35;1m\t\033[0m \[\033[36;1m\]\$PWD\[\033[0m\]\n\[\e[32;1m\]$ \[\e[0m\]"
fi
