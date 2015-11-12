#!/bin/perl
use strict;
use warnings;
use utf8;

use XML::LibXML;
use File::Basename;
use DateTime::Format::ISO8601;

foreach (@ARGV) {
my $VSTUP = $_;
my $JMENO = basename $VSTUP;
my @VYSTUP;
my $PREDCHOZICAS="";
my $FLAKANI = 0;

# Nacteni a zparsovani vstupniho souboru
my $parser = XML::LibXML->new->parse_file($VSTUP);
#my $xmldoc = $parser->parse_string($FTEXT) or die "can't parse your file: $@";
my $xmldoc = XML::LibXML::XPathContext->new;
$xmldoc->registerNs('x', 'http://www.garmin.com/xmlschemas/TrainingCenterDatabase/v2');

# Ziskavani dat
my $START = 0;

# Ziskani casu startu z dat primo z Garmina
if ( $xmldoc->exists('//x:Trackpoint',$parser) == 1) {
	my @TRACKS = $xmldoc->findnodes('//x:Trackpoint',$parser);
	foreach (@TRACKS) {
		$START = $_->getElementsByTagName("Time");
		last;
		} # end of foreach
	undef @TRACKS;
	} #End of if
# Ziskani casu startu z dat z Endomonda
else {
	for my $node ($xmldoc->findnodes('//x:Lap', $parser)) {
		$START = $xmldoc->findvalue('@StartTime', $node);
		last;
	} # End of for

} # end of else

push (@VYSTUP, $START);

my @LAPS = ($xmldoc->findnodes('//x:Lap', $parser));
my $DIST = 0;
my $TIME = 0;
my $AVGHR = 0;
my $COUNT = 0;
foreach (@LAPS) {
	$DIST = $DIST + $xmldoc->findvalue('x:DistanceMeters', $_);
	$TIME = $TIME + $xmldoc->findvalue('x:TotalTimeSeconds', $_);
} #End of foreach (@LAPS)

# Celkova vzdalenost
push (@VYSTUP, $DIST);
# Celkovy cas
push (@VYSTUP, $TIME);

# HeartRate

if ( $xmldoc->exists('//x:AverageHeartRateBpm',$parser) == 1) {
	my @HR = ($xmldoc->findnodes('//x:AverageHeartRateBpm',$parser));
	foreach (@HR) {
		$COUNT++;
		$AVGHR = $AVGHR + $xmldoc->findvalue('x:Value',$_);	
		} # End of foreach
	$AVGHR = int($AVGHR / $COUNT);
} # End of if exist HeartRate
push (@VYSTUP, $AVGHR);

# Souradnice

if ( $xmldoc->exists('//x:Position',$parser) == 1) {
	my @TRACKP = ($xmldoc->findnodes('//x:Trackpoint',$parser));
	foreach (@TRACKP) {
		my $TTIME = $xmldoc->findvalue('x:Time',$_);
		my $LAT = $_->getElementsByTagName("LatitudeDegrees");
		my $LON = $_->getElementsByTagName("LongitudeDegrees");
        	my $HR = $_->getElementsByTagName("Value");
		my $SP = $_->getElementsByTagName("Speed");
		next if (($LAT eq "") || ($LON eq ""));
# Pokud nastala pauza 
                if (($SP eq "") && ( length($PREDCHOZICAS) gt 0) ) {
			my $H1 = DateTime::Format::ISO8601->parse_datetime($TTIME);
                        my $H2 = DateTime::Format::ISO8601->parse_datetime($PREDCHOZICAS);
			$FLAKANI = $FLAKANI + ($H1->epoch() - $H2->epoch());
}
# Konec zpracovani pauzy

		$HR = "0" if $HR eq "";
        	push (@VYSTUP, $TTIME);
        	push (@VYSTUP, $LAT);
        	push (@VYSTUP, $LON);
        	push (@VYSTUP, $HR);
		$PREDCHOZICAS = $TTIME;
		} # End of foreach trackp	
} # End of if exist Souradnice

# Vypis do souboru
if ($FLAKANI gt 0) {
	splice(@VYSTUP,2,1, eval ($VYSTUP[2]) - $FLAKANI) if ($FLAKANI gt 0);
	printf "Odecteno $FLAKANI vterin.\n";
	} #End of if FLAKANI

my $TMPSOUBOR = $JMENO.".tmp";

if (! open(EXPORT, ">$TMPSOUBOR")){ die "Nemuzu otevrit vystup! \n $! \n";}

foreach (@VYSTUP) {
        chomp;
        print EXPORT "$_\n"; 
	} # End of Foreach VYSTUP
close EXPORT;
         
} #End of foreach (@ARGV)
