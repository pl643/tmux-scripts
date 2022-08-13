#!/usr/bin/env perl

# Grabs history of just panes in current window (Default)
$tmux_list_panes="tmux list-panes";
 
## Grabs history of ALL panes, NOTE: this could take a long time
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

# dump files and directories
#foreach(`find ~ -type f -or -type d`) {
#    !$lines{$_}++;
#}

$bash_prompt="$ENV{USER}\@$ENV{NAME}";

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
            !$stripped{$_}++;
        }
        #print "space: $_\n";
    }
}
foreach (keys %words_by_space) {
    if(m!/!) {
        foreach(split /\//) {
            !$words_by_symbol{$_}++;
            #print "/ $_\n";
        }
    }
    if(/-/) {
        foreach(split /-/) {
            !$words_by_symbol{$_}++;
            #print "- $_\n";
        }
    }
    if(/_/) {
        foreach(split /_/) {
            !$words_by_symbol{$_}++;
            #print "_ $_\n";
        }
    }
    if(/@/) {
        foreach(split /@/) {
            $words_by_symbol{$_}++;
            #print " $_\n";
        }
    }
    if(/\./) {
        foreach(split /\./) {
            !$words_by_symbol{$_}++;
            #print "+ $_\n";
        }
    }
    if(/\+/) {
        foreach(split /\+/) {
            !$words_by_symbol{$_}++;
            #print "+ $_\n";
        }
    }
    if(/=/) {
        foreach(split /=/) {
            !$words_by_symbol{$_}++;
            #print "= $_\n";
        }
    }
    if(/"/) {
        foreach(split /"/) {
            !$words_by_symbol{$_}++;
            #print "\" $_\n";
        }
    }
    if(/\(/) {
        foreach(split /\(/) {
            !$words_by_symbol{$_}++;
            #print "\" $_\n";
        }
    }
    if(/\)/) {
        foreach(split /\)/) {
            !$words_by_symbol{$_}++;
            #print "\" $_\n";
        }
    }
}

# strip non-alphanumeric characters from beginning and end
foreach (keys %words_by_symbol) {
    if ( m/^[^\p{PosixAlnum}]+/ or m/[^\p{PosixAlnum}]+$/ ) {
        s/^[^\p{PosixAlnum}]+//g;
        s/[^\p{PosixAlnum}]+$//g;
        next if /^\s*$/;
        !$stripped{$_}++;
    }
}
#print "stripped:\n\n";
foreach(keys %stripped) {
    #print "$_\n"
    !$ALL{$_}++
}
#print "words_by_symbol::::\n\n";
foreach(keys %words_by_symbol) {
    #print "$_\n"
    !$ALL{$_}++
}
#print "words_by_space:::::\n\n";
foreach(keys %words_by_space) {
    #print "$_\n"
    !$ALL{$_}++
}
#print "lines:::::\n\n";
foreach(keys %lines) {
    chomp;
    #print "$_\n"
    !$ALL{$_}++
}
foreach(keys %bash_commands) {
    #print "$_\n"
    !$ALL{$_}++
}

foreach(keys %ALL) {
    print "$_\n"
}
