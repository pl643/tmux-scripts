#!/usr/bin/env bash
# tmux-popup-fzf-selector.sh - fzf in a tmux pop with options to edit/split/copy
                                                                                    
# sample tmux.conf binding:                                                         
#    bind-key -n      C-t tmux-popup-fzf-selector.sh

[ -z $TMUX ] && echo "NOTE: needs to be in a tmux sessions" && exit 1       
                                                                                    
realpath="$(realpath $0)"                                                           
# restart script in a popup
if [ "$1" != "--no-popup" ]; then 
    echo "" >> /tmp/db
    echo start >> /tmp/db $(date) >> /tmp/db
    set -x
    tmux popup -E -h 10 -T '─[ <Enter> paste ] [ C-d copy to buffer ] [ <C-e> edit ] [ <C-s> splits -_/= ]-' "$realpath --no-popup" 
    tmp_file="/tmp/.fzf.edit"
    # for editing option
    # popup -T '─[ <Enter> accept edit and paste <q> - cancel ]-'
    # script to run after 
    if [ -f $tmp_file ]; then
        tmux popup -E -h 6 \
            -T '─[ <Enter> accept edit and paste <q> - cancel ]-' \
            nvim \
            -c 'inoremap <CR> <Esc>:x<cr>'  \
            -c 'nnoremap <CR> :x<cr>'  \
            -c 'nnoremap q    :%d<cr>:x!<cr>' \
            "$tmp_file"
                    if [ -s $tmp_file ]; then  # if size is not zero. 
                        echo -n $(cat $tmp_file) | tmux load-buffer -
                        tmux paste-buffer
                    fi
                    rm "$tmp_file"
    fi
    exit 0
fi 

# --include-all-tmux-panes : default to only panes in current owindow
# pane_list_command="tmux list-panes -a" ALL windows, could be slow
    # else
pane_list_command="tmux list-panes"  # only current window

fzf_selector() {
    size=$(stty size)
    pane_lines=${size% *}
    let fzf_height=$(($pane_lines - 1))
    echo ""
    readarray -t lines < <(echo "$1" | fzf --height=$fzf_height --expect ctrl-d --expect ctrl-e --expect ctrl-s)

    if [ "${lines[0]}" = ctrl-s ]; then
        #ctrl_s_sel=$(echo ${lines[1]} | fzf --height $fzf_height)
        ctrl_s_words="$(echo "${lines[1]}" | sed  -e 's![[:space:]]\+!\n!g' -e 's![-/_=]\+!\n!g' | sort -u)"
        fzf_selector "$ctrl_s_words"
        exit
    fi

    ### EDIT C-d ###
    if [ "${lines[0]}" = ctrl-d ]; then
        echo -n $(echo "${lines[1]}") | tmux load-buffer -
        exit
    fi

    ### EDIT C-e ###
    if [ "${lines[0]}" = ctrl-e ]; then
        tmp_file="/tmp/.fzf.edit"
        echo ${lines[1]} > $tmp_file 
        #nvim $tmp_file
        #echo -n $(cat $tmp_file) | tmux load-buffer -
        #rm $tmp_file
        #tmux paste-buffer
        exit
    fi

    ### Enter ###
    sel="${lines[1]}"
    [ -z "$sel" ] || echo -n "$sel" | tmux load-buffer - \; paste-buffer
}

#perl_sort_uniq() {
#
#}

default_fzf_contents() {
    if [ -z $ALL_PANES_OPTION ]; then
        list_panes="tmux list-panes"
    else
        list_panes="tmux list-panes -a"
    fi

    # iterate through all selected panes
    for pane in $($list_panes | cut -f 7 -d " "); do
        echo pane: $pane >> /tmp/db
        current_pane_lines=$(tmux capture-pane -t $pane -pS -)
        [ -z all_pane_lines ] && all_pane_lines="$current_pane_lines" || \
                all_pane_lines="$all_pane_lines$current_pane_lines"
    done

    # splits lines into words
    echo split lines int words >> /tmp/db
    date >> /tmp/db
    #all_pane_words="$(echo $all_pane_lines | sed -e 's/[[:space:]]\+/\n/g' | sort -u )"
    # all_pane_words="$(echo $all_pane_lines | sed -e 's/[[:space:]]\+/\n/g' )"
    # all_pane_words="$(perl -e ' @words = split /\s+/, $ARGV[0]; foreach(@words) { $words{$_}++;}foreach $word (keys %words ) {print "$word\n";}' \"$all_pane_lines\" )"
    date >> /tmp/db

    files_contents=$(cat ~/.bash_history)
    all_pane_lines="$all_pane_lines$files_contents"
    all_pane_lines="$(perl -e ' @words = split /\s+/, $ARGV[0]; foreach(@words) { $words{$_}++;}foreach $word (keys %words ) {print "$word\n";}' \"$all_pane_lines\" )"

    fzf_contents="$all_pane_lines"
}

# INIT - define custom fzf_contents
init_file="$HOME/.init.fzf-popup-selector"
[ -f "$init_file" ] && source "$init_file"
[ -z "$fzf_contents" ] && default_fzf_contents
##echo (/per

echo openvim files >> /tmp/db
date >> /tmp/db
all_open_vim_files=$(cat $(lsof | grep nvim | awk '{ print $9 }' | grep .swp|cut -f2- -d%| sed -e 's!%!/!g' -e 's!.swp!!' -e 's!^!/!') | sed -e 's/[[:space:]]\+/\n/g' | sort -u )
date >> /tmp/db
echo all_open_vim_files wc: $(echo $all_open_vim_files|wc) >> /tmp/db
echo "$all_open_vim_files" > /tmp/all_open_vim_files
fzf_contents="$fzf_contents$all_open_vim_files"
echo wc fzfcontents: $(echo "$fzf_contents"|wc ) >> /tmp/db
fzf_selector "$fzf_contents"
# TEST555
# 'open files in vi/nvim
# lsof | grep nvim | awk '{ print $9 }' | grep .swp|cut -f2- -d%| sed -e 's!%!/!g' -e 's!.swp!!' -e 's!^!/!'
# very-long-variable-is-here 
