#!/usr/bin/bash
# tmux-popup-pane-manager.sh - menu driven tmux pane activities
# github repo: https://github.com/pl643/tmux-scripts
#   resize, selection, syncronize, layout, splits, kill, break

# sample tmux.conf binding:
#    bind-key -m      M-p tmux-popup-pane-manager.sh

[ -z $TMUX ] && echo "NOTE: needs to be run inside a tmux sessions" && exit 1

realpath="$(realpath $0)"
[ "$1" != "--no-popup" ] && tmux popup -E -T "────────── Pane Manager ─────" -w 50 -h 34 "$realpath --no-popup" && exit

pane_border_status="off"
display_menu() {
	clear
    tmux list-windows | grep active | awk '{print $2}' | tail -c2 | grep -q Z && zoom_status="on" || zoom_status="off"
    tmux show-options -w | grep -q 'synchronize-panes.*on' && synchronize_panes="on" || synchronize_panes="off"
    tmux show-options -w | grep -q 'pane-border-status.*top'    && pane_border_status="top"
    tmux show-options -w | grep -q 'pane-border-status.*bottom' && pane_border_status="bottom"
	printf "
 Resize

  hjkl    x 5            HJKL    x 1
  1 - 9   | x 10%%        ! - )   ─ x 10%%
  = +     equally | -

 Split

   s -    spilt -        v |       spilt |
	   
 Navigation

   n p       next/prev pane
   N P       next/prev layout
   u d       swap pane up/down

 Toggles 

   b         border [ %s ]
   S         syncronize [ %s ]
   z         zoom [ %s ]

 Misc

   B         break (make pane into window)
   o         join this pane to window
   D         send C-d
   t         rename pane
   X         kill (no confirm!)
   e         exit" $pane_border_status $synchronize_panes $zoom_status
}
display_menu

trap ctrl_c INT

function ctrl_c() {
    echo exiting
    MAXNUMLOOP=20
    exit
}

# https://www.reddit.com/r/tmux/comments/g9nr01/how_to_show_message_or_effect_when/
# Uncomment this setting if want status of pane sync on the status bar
tmux set -ag status-right '#{?pane_synchronized, #[fg=red]IN_SYNC#[default],}'

# https://www.reddit.com/r/tmux/comments/dfj5ye/rename_pane_not_window_is_there_a_builtin/
tmux set -g pane-border-format " [ ###P #T ] "

# If C-c is press in the while [ true ] loop, a run runaway process occurs, limiting 
#   it to 20 will cause the loop to exit after 20 loops.  Modify MAXNUMLOOP if you 
#   need more keys presses.
MAXNUMLOOP=20
COUNTER=0
while [ $COUNTER -lt $MAXNUMLOOP ]; do

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

    # border status ( 3 toggle off, top, bottom )
    [ "$c" = "b" ] && [ "$pane_border_status" = "off" ]    && tmux set pane-border-status     && display_menu && continue
    [ "$c" = "b" ] && [ "$pane_border_status" = "top" ]    && tmux set pane-border-status bottom && display_menu && continue
    [ "$c" = "b" ] && [ "$pane_border_status" = "bottom" ] && tmux set pane-border-status off \
                   && pane_border_status="off" && display_menu && continue

    # Split panes
    [ "$c" = "s" ] || [ "$c" = "-" ] && tmux split -v
    [ "$c" = "v" ] || [ "$c" = "|" ] && tmux split -h

    # Misc
    [ "$c" = "B" ] && tmux break-pane
    [ "$c" = "o" ] && printf "\n\n join window: " && read window && tmux join-pane -t $window
    [ "$c" = "X" ] && tmux kill-pane
    [ "$c" = "D" ] && tmux send-key C-d ; display_menu
    [ "$c" = "e" ] && exit
    [ "$c" = "z" ] && tmux resize-pane -Z && display_menu
    [ "$c" = "t" ] && printf "\n\n pane name: " && read pane_name && tmux select-pane -T "$pane_name" && display_menu
    let COUNTER=COUNTER+1
    echo $COUNTER > /tmp/counter
done
