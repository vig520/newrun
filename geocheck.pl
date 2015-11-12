#!/bin/perl
use strict;
use warnings;
use utf8;

use Geo::Coder::Google;
use DBI;

sub GetCoords {
	my $BEH = $_[0];
	my $dbh = DBI->connect ('dbi:mysql:dbRuns','root','$$sim999CEK$$', { mysql_enable_utf8 => 1,}) or die "Nelze se pripojit do db\n";
	my $QUERY1 = $dbh->prepare("SELECT Latitude, Longitude from tblWaypoints where BehID = $BEH order by tblWaypoints.`Primary` ASC limit 1;");
	my $QUERY2 = $dbh->prepare("SELECT Latitude, Longitude from tblWaypoints where BehID = $BEH  order by tblWaypoints.`Primary` DESC limit 1;");
	$QUERY1->execute() or die "Nepovedlo se nacist data o behu!";
	$QUERY2->execute() or die "Nepovedlo se nacist data o behu!";
	my @DATA1 = $QUERY1->fetchrow_array();
	my @DATA2 = $QUERY2->fetchrow_array();
	my @VYSTUP = (@DATA1, @DATA2);	
} # end of GetCoords

sub GetLocation {
	my $COORD = "$_[0],$_[1]";
        my $geocoder = Geo::Coder::Google->new(apiver => 3, host => 'maps.google.cz', language => 'CZ', gl => 'CZ');
	my $LOC = $geocoder->reverse_geocode(latlng => $COORD); 
} # end of GetLocation
#my $dbh = DBI->connect ('dbi:mysql:dbRuns','root','$$sim999CEK$$') or die "Nelze se pripojit do db\n";

sub ParseLocation {
	my $DATA = $_[0];
	my @VYSTUP;
	my $STREET;
	my $CITY;
	my $COUNTRY;
	my $FULL = $DATA->{formatted_address} // '0';	
	push (@VYSTUP, $FULL);
	for my $component ( @{ $DATA->{address_components} } )	
	{
                        if ( grep $_ eq "route", @{$component->{types}}) {
                        	$STREET = $component->{long_name};
				}
			if ( grep $_ eq "locality", @{$component->{types}}) {
                                $CITY = $component->{long_name};
                                }
			if ( grep $_ eq "country", @{$component->{types}}) {
                                $COUNTRY = $component->{long_name};
				}	
	} #end of for
	$STREET = "0" if (! $STREET);
	$CITY = "0" if (! $CITY);
	$COUNTRY = "0" if (! $COUNTRY);
	push (@VYSTUP, $STREET, $CITY, $COUNTRY);
	@VYSTUP;
} #end of ParseLocation

sub DBUpload {
	my ($BEH, $START_REF, $FINISH_REF) = @_;
	my $dbh = DBI->connect ('dbi:mysql:dbRuns','root','$$sim999CEK$$', {mysql_enable_utf8 => 1}) or die "Nelze se pripojit do db\n";
	my $QUERY_HANDLE = $dbh->prepare("UPDATE tblRuns SET StartAddress = ?, StartStreet = ?, StartCity = ?, StartCountry = ?, FinishAddress = ?, FinishStreet = ?, FinishCity = ?, FinishCountry = ? WHERE tblRuns.`Primary` = ?;");
	$QUERY_HANDLE->execute(@$START_REF[0], @$START_REF[1], @$START_REF[2], @$START_REF[3], @$FINISH_REF[0], @$FINISH_REF[1], @$FINISH_REF[2], @$FINISH_REF[3], $BEH);
}

sub FineTuning {
	my $BEH = $_[0];
	my $dbh = DBI->connect ('dbi:mysql:dbRuns','root','$$sim999CEK$$', {mysql_enable_utf8 => 1}) or die "Nelze se pripojit do db\n";
	my $QUERY_HANDLE = $dbh->prepare("insert ignore into tblCountries (Country) select distinct StartCountry from tblRuns where StartCountry <> '0';");	
	$QUERY_HANDLE->execute();	
	$QUERY_HANDLE = $dbh->prepare("insert ignore into tblCities (City, Country) select distinct tblRuns.StartCity AS City, tblCountries.`Primary` as Country from tblRuns, tblCountries where StartCity <> \"\" and StartCity <> \"0\" and tblCountries.Country = tblRuns.StartCountry;");
        $QUERY_HANDLE->execute();
	$QUERY_HANDLE = $dbh->prepare("update tblRuns set Home = 1 where (StartStreet LIKE \"Na nové silnici\" OR StartStreet LIKE \"Kludských\" OR StartStreet LIKE \"Bártlova\" OR StartStreet LIKE \"Cirkusová\" OR StartStreet LIKE \"Na staré silnici\" OR StartStreet LIKE \"U úlů\") AND tblRuns.`Primary` = ?;");
        $QUERY_HANDLE->execute($BEH);
}


foreach (@ARGV) {
	if (! open(IMPORT, "<$_")){ die "Nemuzu otevrit vstup! \n $! \n";}
	my $INDEX = <IMPORT>;
	close IMPORT;
	my @GPS = &GetCoords($INDEX);
	my $STARTLOCATION = &GetLocation($GPS[0], $GPS[1]);
	my $FINISHLOCATION = &GetLocation($GPS[2], $GPS[3]);
	my @START = &ParseLocation($STARTLOCATION) ;
	my @FINISH = &ParseLocation($FINISHLOCATION);
	&DBUpload($INDEX, \@START, \@FINISH);		
	&FineTuning($INDEX);
	unlink $_ or die "Nepovedlo se smazat tmp soubor.\n";
}
