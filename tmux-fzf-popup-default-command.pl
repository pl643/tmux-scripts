#!/usr/bin/env perl

$epoc_start = time();

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

$fdlocation=`which fd`;
if ( -e "$fdlocation" ) {
    print "db126: found fd\n";
}
if($exit_code=0) {
    $lsfiles="fd";
} else {
    $lsfiles="find ~ -not -path '*/.*'"
}
foreach(`$lsfiles`) {
    chomp;
    !$ALL{$_}++;
    $file_count++;
}

foreach(keys %ALL) {
    print "$_\n"
}

$epoc_stop = time();
printf "lsfiles: %s\n", $lsfiles;
printf "file count: %s\n", $file_count;
printf "total time: %s\n", $epoc_stop - $epoc_start;
printf "total lines: %d\n", scalar keys %ALL;
my $output=`which fd`;
print "db126: ec: $? output $output\n";
