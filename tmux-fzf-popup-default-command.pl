#!/usr/bin/env perl

# fzf defaults to just the 'find' command. This perl script adds the following beside just 'find':
#   - fd . ~ || find ~
#   - contents of nvim open files
#   - contents of tmux pane history 
#   - split all words found by spaces /@,\+()

use Time::HiRes qw(time);
# time how long it takes the script to run
$epoc_start = time();  # $epoc_stop = time()  at bottom

# https://www.reddit.com/r/neovim/comments/w6fxhu/opened_files_in_neovim_from_the_command_line/
# lsof | grep nvim| awk '{ print $9 }' |grep .swp|cut -f2- -d%| sed -e 's!%!/!g' -e 's!.swp!!' -e 's!^!/!'
foreach(`lsof`) {
    if(/$ENV{USER}/ && /nvim/ && /\s.+?(%.+\.swp)/) {
        $fname=$1;
        $fname=~s!\%!/!g;
        $fname=~s!\.swp!!;
        #print "$fname\n";
        !$nvimfiles{$fname}++;
    }
}

foreach(keys %nvimfiles) {
    foreach(`cat $_`) {
        next if /^\s*$/;
        !$nvimfilescontents{$_}++;
    }
}
# gets tmux history of just panes in current window (Default)
$tmux_list_panes="tmux list-panes";
 
# gets history of ALL panes, NOTE: this could take a long time
#$tmux_list_panes="tmux list-panes -a";

foreach(`tmux list-panes | cut -f 7 -d " "`) {
    $pane_number=$_;
    chomp $pane_number;
    foreach(`tmux capture-pane -t $pane_number -pS -`) {
        next if /^\s*$/;
        !$lines{$_}++;
        $line_count++;
        if(/(".+")/) {
            !$quotes{"$1"}++;
            #print "2\" $1\n";
        }
        if(/"(.+)"/) {
            #print "2\" $1\n";
            !$quotes{"$1"}++;
        }
    }
}

# remove dupe words and store in %words_by_space
foreach $line (keys %lines) {
    if ( $line =~ /^$bash_prompt.+?\s(\S.+)/ ) {
        # print "DB38: $1\n";
        !$bash_commands{"$1"}++;
    }
    foreach(split /\s+/, $line) {
        next if /^\s*$/;
        $words_by_space{$_}++;
        if ( m/^[^\p{PosixAlnum}]+/ or m/[^\p{PosixAlnum}]+$/ ) {
            s/^[^\p{PosixAlnum}]+//g;
            s/[^\p{PosixAlnum}]+$//g;
            next if /^\s*$/;
            !$strip_symbol_words{$_}++;
        }
    }
}
foreach (keys %words_by_space) {
    if(m!/!) {
        foreach(split /\//) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/-/) {
        foreach(split /-/) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/_/) {
        foreach(split /_/) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/@/) {
        foreach(split /@/) {
            $words_by_symbol{$_}++;
        }
    }
    if(/\./) {
        foreach(split /\./) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/\+/) {
        foreach(split /\+/) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/=/) {
        foreach(split /=/) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/"/) {
        foreach(split /"/) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/\(/) {
        foreach(split /\(/) {
            !$words_by_symbol{$_}++;
        }
    }
    if(/\)/) {
        foreach(split /\)/) {
            !$words_by_symbol{$_}++;
        }
    }
}

# strip non-alphanumeric characters from beginning and end
foreach (keys %words_by_symbol) {
    if ( m/^[^\p{PosixAlnum}]+/ or m/[^\p{PosixAlnum}]+$/ ) {
        s/^[^\p{PosixAlnum}]+//g;
        s/[^\p{PosixAlnum}]+$//g;
        next if /^\s*$/;
        !$strip_symbol_words{$_}++;
    }
}
foreach(keys %nvimfilescontents) {
    !$ALL{$_}++
}
foreach(keys %strip_symbol_words) {
    !$ALL{$_}++
}
foreach(keys %words_by_symbol) {
    !$ALL{$_}++
}
foreach(keys %words_by_space) {
    !$ALL{$_}++
}
foreach(keys %lines) {
    chomp;
    !$ALL{$_}++
}
foreach(keys %bash_commands) {
    !$ALL{$_}++
}

# install fd, so much faster!
$fdlocation=`which fd`;
chomp $fdlocation;
if ( -e "$fdlocation" ) {
    $files_cmd='fd . ~';
} else {
    $files_cmd="find ~ -not -path '*/.*'"
}
foreach(`$files_cmd`) {
    chomp;
    !$ALL{$_}++;
    $file_count++;
}

foreach(keys %ALL) {
    print "$_\n"
}

$epoc_stop = time();
printf "file cmd:         %s\n", $files_cmd;
printf "file count:       %s\n", $file_count;
printf "script run time:  %3.3f seconds\n", $epoc_stop - $epoc_start;
printf "total lines:      %d\n", scalar keys %ALL;
