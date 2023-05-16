package mellanox;
##
## rancid 3.2.99
#
#  RANCID - Really Awesome New Cisco confIg Differ
#
# mellanox.pm - Mellanox Onyx switches
#
# Contributed by J R Binks <jrbinks+rancid@gmail.com>
#
# Tested on:
#
# HPE SN2410M
# v3.9.2110

use 5.010;
use strict 'vars';
use warnings;
no warnings 'uninitialized';
require(Exporter);
our @ISA = qw(Exporter);

use rancid 3.2.99;
use rancid;

@ISA = qw(Exporter rancid main);

# load-time initialization
sub import {
    0;
}

# post-open(collection file) initialization
sub init {
    # add content lines and separators
    ProcessHistory("","","","!RANCID-CONTENT-TYPE: $devtype\n!\n");

    0;
}

# main loop of input of device output
sub inloop {
    my($INPUT, $OUTPUT) = @_;
    my($cmd, $rval);
    print STDERR ("\n") if ($debug);

TOP: while(<$INPUT>) {
        tr/\015//d;
        if (/[\]>#]\s*exit$/ || $found_end ) {
            $clean_run = 1;
            last;
        }
        if (/^Error:/) {
            print STDOUT ("$host $lscript error: $_");
            print STDERR ("$host $lscript error: $_") if ($debug);
            $clean_run = 0;
            last;
        }
        while (/[\]>#]\s*($cmds_regexp)\s*$/) {
            $cmd = $1;
            if (!defined($prompt)) {
                $prompt = ($_ =~ /^([^#>]+#)/)[0];
#                $prompt =~ s/([][}{)(+\\])/\\$1/g;
                $prompt =~ s/([][}{)(\\])/\\$1/g;
                print STDERR ("PROMPT MATCH: $prompt\n") if ($debug);
            }
            print STDERR ("HIT COMMAND:$_") if ($debug);
            if (! defined($commands{$cmd})) {
                print STDERR "$host: found unexpected command - \"$cmd\"\n";
                $clean_run = 0;
                last TOP;
            }
            if (! defined(&{$commands{$cmd}})) {
                printf(STDERR "$host: undefined function - \"%s\"\n",
                       $commands{$cmd});
                $clean_run = 0;
                last TOP;
            }
            $rval = &{$commands{$cmd}}($INPUT, $OUTPUT, $cmd);
            delete($commands{$cmd});
            if ($rval == -1) {
                $clean_run = 0;
                last TOP;
            }
        }
    }
}


# dummy function
sub DoNothing {print STDOUT;}

# Clean up lines on input
sub filter_lines {
    my ($l) = (@_);
    # spaces at end of line:
    $l =~ s/\s+$//g;
    #$l =~ s/\033\133\064\062\104\s+\033\133\064\062\104//g;
    return $l;
}

# Some commands are not supported on some models or versions
# of code.
# Remove the associated error messages, and rancid will ensure that
# these are not treated as "missed" commands

sub command_not_valid {
    my ($l) = (@_);

    if ( $l =~
        /% Unrecognized command/
    ) {
        return(1);
    } else {
        return(0);
    }
}

# Some commands are not authorized under the current
# user's permissions
sub command_not_auth {
    my ($l) = (@_);

    if ( $l =~
        # nothing needed here so far so just use a placeholder
        /XXXXPLACEHOLDERXXX/
    ) {
        return(1);
    } else {
        return(0);
    }
}

# Some output lines are always skipped
sub skip_pattern {
    my ($l) = (@_);

    if ( $l =~
        /^\s+\^$/
    ) {
        return(1);
    } else {
        return(0);
    }
}

## This routine processes general output of "display" commands
sub CommentOutput {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my $sub_name = (caller(0))[3];
    print STDERR "    In $sub_name: $_" if ($debug);

    chomp;

    # Display the command we're processing in the output:
    ProcessHistory("COMMENTS", "", "", "!\n! '$cmd':\n!\n");

    while (<$INPUT>) {
        tr/\015//d;

        # If we find the prompt, we're done
        last if (/^$prompt/);
        chomp;

        # filter out some junk
        $_ = filter_lines($_);
        return(1) if command_not_valid($_);
        return(-1) if command_not_auth($_);
        next if skip_pattern($_);
    }

    # Add a blank comment line to the output buffer
    ProcessHistory("COMMENTS", "", "", "!\n");
    return(0);
}


sub ShowConfiguration {
    my($INPUT, $OUTPUT, $cmd) = @_;
    my $sub_name = (caller(0))[3];
    print STDERR "    In $sub_name: $_" if ($debug);

    my($linecnt) = 0;

    while (<$INPUT>) {
        tr/\015//d;
        last if(/^\s*$prompt/);
        chomp;

        $_ = filter_lines($_);
        return(1) if command_not_valid($_);
        return(-1) if command_not_auth($_);
        next if skip_pattern($_);

        return(0) if ($found_end);

        $linecnt++;

        next if (/^## Generated at /);

        # Filter out some sensitive data:
	# "show running-config" (or "write terminal") produce an abbreviated config
        # which amongst other things does not display secrets
        # "show running-config expanded" has more detail, including secrets
        # In fact by default Onyx does not show most sensitive strings in
        # output from "write terminal", so most of this is unnecessary
        #if ( $filter_commstr &&
        #     /^(snmp-server community )(\S+)/
        #   ) {
        #    ProcessHistory("","","","! $1<removed>$'\n");
        #    next;
        #}
        #if ( $filter_pwds >= 1 &&
        #    /^((user .+ password|tacacs-server .+) ciphertext )(\S+)/
        #   ) {
        #    ProcessHistory("","","","! $1<removed>$'\n");
        #    next;
        #}

        ProcessHistory("", "", "", "$_\n");

    }

    # lacks a definitive "end of config" marker.
    if ($linecnt > 5) {
        $found_end = 1;
        return(0)
    }

    return(0);

}

1;

__END__


