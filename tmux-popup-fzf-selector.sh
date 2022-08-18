#!/usr/bin/env bash
# tmux-popup-fzf-selector.sh - fzf in a tmux pop with options to edit/split/copy
# sample tmux.conf binding:                                                         
#    bind-key -n      C-t tmux-popup-fzf-selector.sh

[ -z $TMUX ] && echo "NOTE: needs to be in a tmux sessions" && exit 1       
realpath="$(realpath $0)"                                                           
# restart script in a popup
if [ "$1" != "--no-popup" ]; then 
    #set -x
    tmux popup -E -h 10 -T '─[ <Enter> paste+<Enter> ] [ A-c copy to buffer ] [ <C-e> edit ] [ <C-s> splits -_/= ]-' "$realpath --no-popup" 
    tmp_file="/tmp/.fzf.edit"
    # for editing option
    # popup -T '─[ <Enter> accept edit and paste <q> - cancel ]-'
    # script to run after 
    if [ -f $tmp_file ]; then
        tmux popup -E -h 6 \
            -T '─[ <Enter> paste+Enter <;p> paste <;q> - cancel ]-' \
            nvim \
            -c 'inoremap <CR> <Esc>:x<cr>'  \
            -c 'nnoremap <CR> :x<cr>'  \
            -c 'nnoremap q    :%d<cr>:x!<cr>' \
            -c 'nnoremap M-v  :%d<cr>:x!<cr>' \
            "$tmp_file"
                    if [ -s $tmp_file ]; then  # if size is not zero. 
                        echo -n $(cat $tmp_file) | tmux load-buffer -
                        tmux paste-buffer
                    fi
                    rm "$tmp_file"
    fi
    exit 0
fi 

fzf_with_options() {
    size=$(stty size)
    pane_lines=${size% *}
    let fzf_height=$(($pane_lines - 1))
    echo ""
    readarray -t lines < <(echo "$1" | fzf --height=$fzf_height --expect alt-c --expect alt-f --expect alt-v --expect alt-e --expect ctrl-s)

    if [ "${lines[0]}" = ctrl-s ]; then
        #ctrl_s_sel=$(echo ${lines[1]} | fzf --height $fzf_height)
        ctrl_s_words="$(echo "${lines[1]}" | sed  -e 's![[:space:]]\+!\n!g' -e 's![-/_=]\+!\n!g' | sort -u)"
        fzf_with_options "$ctrl_s_words"
        exit
    fi

    ### COPY A-c ###
    # copy to tmux clipboard
    if [ "${lines[0]}" = alt-c ]; then
        echo -n $(echo "${lines[1]}") | tmux load-buffer -
        exit
    fi

    ### EDIT A-e ###
    if [ "${lines[0]}" = alt-e ]; then
        tmp_file="/tmp/.fzf.edit"
        echo ${lines[1]} > $tmp_file 
        #edit_selection="${lines[1]}"
        tmux set-env edit-selection "${lines[1]}"
        #nvim $tmp_file
        #echo -n $(cat $tmp_file) | tmux load-buffer -
        #rm $tmp_file
        #tmux paste-buffer
        exit
    fi

    ### EDIT A-f ###
    if [ "${lines[0]}" = alt-f ]; then
        tmp_file="/tmp/.fzf.edit"
        echo ${lines[1]} > $tmp_file 
        #nvim $tmp_file
        #echo -n $(cat $tmp_file) | tmux load-buffer -
        #rm $tmp_file
        #tmux paste-buffer
        exit
    fi

    ### COPY A-v ###
    # paste selected
    if [ "${lines[0]}" = alt-v ]; then
        echo -n $(echo "${lines[1]}") | tmux load-buffer - \; paste-buffer 
        exit
    fi

    ### Enter ###
    sel="${lines[1]}"
    [ -z "$sel" ] || echo -n "$sel" | tmux load-buffer - \; paste-buffer \; send-key Enter
}

# INIT - define custom fzf_contents
init_file="$HOME/.init.fzf-popup-selector"
[ -f "$init_file" ] && source "$init_file"
fzf_with_options "$(fzf.default.command.pl)"
# echo tmux.conf echo tmux-popup-fzf-selector.sh 
