#!/usr/bin/bash
# tmux-popup-pane-manager.sh - menu driven tmux pane activities
# github repo: https://github.com/pl643/tmux-scripts
#   resize, selection, syncronize, layout, splits, kill

# sample tmux.conf binding:
#    bind-key -m      M-p tmux-popup-pane-manager.sh

[ -z $TMUX ] && echo "NOTE: needs to be run inside a tmux sessions" && exit 1

realpath="$(realpath $0)"
[ "$1" != "--no-popup" ] && tmux popup -E -T "────────── Pane Manager ─────" -w 38 -h 22 "$realpath --no-popup" && exit

display_menu() {
	clear
    tmux show-options -w | grep -q 'synchronize-panes.*on' && synchronize_panes="on" || synchronize_panes="off"
	printf "
   hjkl      resize x5
   HJKL      resize x1
   1 - 9     resize | x 10%%
   ! - )     resize ─ x 10%%
   = +       resize equally | -
   z         zoom

   n p       next/prev pane
   N P       next/prev layout
   u d       swap pane up/down

   s -       spilt -
   v |       spilt |
	   
   S         sync toggle [ %s ]
   X         kill

         Esc - (e)xit " $synchronize_panes
}
display_menu

# https://www.reddit.com/r/tmux/comments/g9nr01/how_to_show_message_or_effect_when/
# Uncomment this setting if want status of pane sync on the status bar
# set -ag status-right '#{?pane_synchronized, #[fg=red]IN_SYNC#[default],}'

while [ true ]; do

    read -sn1 c

    # Resize x 1
    [ "$c" = "H" ] && tmux resize-pane -L 1
    [ "$c" = "L" ] && tmux resize-pane -R 1
    [ "$c" = "J" ] && tmux resize-pane -D 1
    [ "$c" = "K" ] && tmux resize-pane -U 1

    # Resize x 5
    [ "$c" = "h" ] && tmux resize-pane -L 5
    [ "$c" = "l" ] && tmux resize-pane -R 5
    [ "$c" = "j" ] && tmux resize-pane -D 5
    [ "$c" = "k" ] && tmux resize-pane -U 5

    # Resize X percent
    [ "$c" = "1" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 10 / 100))
    [ "$c" = "2" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 20 / 100))
    [ "$c" = "3" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 30 / 100))
    [ "$c" = "4" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 40 / 100))
    [ "$c" = "5" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 50 / 100))
    [ "$c" = "6" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 60 / 100))
    [ "$c" = "7" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 70 / 100))
    [ "$c" = "8" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 80 / 100))
    [ "$c" = "9" ] && tmux resize-pane -x $(($(tmux display-message -p "#{window_width}") * 90 / 100))

    # Resize Y percent
    [ "$c" = "!" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 10 / 100))
    [ "$c" = "@" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 20 / 100))
    [ "$c" = "#" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 30 / 100))
    [ "$c" = "$" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 40 / 100))
    [ "$c" = "%" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 50 / 100))
    [ "$c" = "^" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 60 / 100))
    [ "$c" = "&" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 70 / 100))
    [ "$c" = "*" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 80 / 100))
    [ "$c" = "(" ] && tmux resize-pane -y $(($(tmux display-message -p "#{window_height}") * 90 / 100))

    # Pane layout cycle
    [ "$c" = "N" ] || [ "$c" = " " ] && tmux next-layout
    [ "$c" = "P" ] && tmux previous-layout

    # Pane selection cycle
    [ "$c" = "n" ] && tmux select-pane -t :.+
    [ "$c" = "p" ] && tmux select-pane -t :.-

    # Pane selection even horizontal/vertical
    [ "$c" = "=" ] && tmux select-layout even-horizontal
    [ "$c" = "+" ] && tmux select-layout even-vertical

    # Rotate pane
    [ "$c" = "u" ] && tmux swap-pane -U
    [ "$c" = "d" ] && tmux swap-pane -D

    # Syncronize pane
    [ "$c" = "S" ] && tmux setw synchronize-pane && display_menu

    # Split panes
    [ "$c" = "s" ] || [ "$c" = "-" ] && tmux split -v
    [ "$c" = "v" ] || [ "$c" = "|" ] && tmux split -h
    [ "$c" = "X" ] && tmux kill-pane
    [ "$c" = "e" ] || [ "$c" = $'\e' ] && exit
    [ "$c" = "z" ] && tmux resize-pane -Z

done
