#!/bin/perl
use strict;
use warnings;
use utf8;

use File::Basename;

foreach (@ARGV) {
print "Parsuji soubor $_ \n";
system '/home/tomas/running/parserun.pl', $_;
my $TMPNAME = basename $_.".tmp";
print "Nahravam do databaze.\n";
system '/home/tomas/running/dbupload.pl', $TMPNAME;
print "Pridavam geodata.\n";
system '/home/tomas/running/geocheck.pl', $TMPNAME;
print "Prepocitavam statistiky.\n";
system '/home/tomas/running/rebuildstats.pl';
print "Hotovo.\n";
}
