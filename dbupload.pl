#!/bin/perl
use strict;
use warnings;
use utf8;

use DBI;

my $dbh = DBI->connect ('dbi:mysql:dbRuns','root','$$sim999CEK$$') or die "Nelze se pripojit do db\n";

foreach (@ARGV) {
my $VSTUP = $_;
if (! open(IMPORT, "<$VSTUP")){ die "Nemuzu otevrit vstup! \n $! \n";}

chomp(my $DATUM = <IMPORT>);
chomp(my $DISTANCE = <IMPORT>);
chomp(my $CAS = <IMPORT>);
chomp(my $AVG_HR = <IMPORT>);
my $QUERY = "insert into tblRuns (Date, Distance, Duration, AvgHeartRate) values ('".$DATUM."', '".$DISTANCE."', '".$CAS."', '".$AVG_HR."');";
my $QUERY_HANDLE = $dbh->prepare($QUERY);
$QUERY_HANDLE->execute() or die "Nepodarilo se vlozit beh!";

#GPS data part
my $INDEX = $QUERY_HANDLE->{mysql_insertid};
my $QUERY2 = $dbh->prepare(q{insert into tblWaypoints (BehID, Moment, Latitude, Longitude, HR) values (?, ?, ?, ?, ?)});

#print $QUERY."\n";
#print $INDEX."\n";
if (! eof(IMPORT)) {
while (1) { 
chomp(my $DATUM = <IMPORT>); 
chomp(my $LATITUDE = <IMPORT>); 
chomp (my $LONGITUDE = <IMPORT>);
chomp (my $HR = <IMPORT>);
#my $QUERY = "insert into tblWaypoints (BehID, Moment, Latitude, Longitude) values ('".$INDEX."', '".$DATUM."', '".$LATITUDE."', '".$LONGITUDE."');";
$QUERY2->execute($INDEX, $DATUM, $LATITUDE, $LONGITUDE, $HR);
#print $QUERY."\n";
last if eof(IMPORT);
}
}
close IMPORT;
if (! open(IMPORT, ">$VSTUP")){ die "Nemuzu otevrit soubor pro zapis indexu! \n $! \n";}
print IMPORT $INDEX;
close IMPORT;
}
$dbh->disconnect;
