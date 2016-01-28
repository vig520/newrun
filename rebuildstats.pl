#!/bin/perl
use strict;
use warnings;
use utf8;

use DBI;

my $dbh = DBI->connect ('dbi:mysql:dbRuns','root','$$sim999CEK$$', { mysql_enable_utf8 => 1,}) or die "Nelze se pripojit do db.\n";

my $QUERY = $dbh->prepare("TRUNCATE `tblStats`;");
$QUERY->execute() or die "Nepovedlo se vyprazdnit tabulku tblStats!";

$QUERY = $dbh->prepare("select ROUND(SUM(Distance)/1000, 2) AS TotalDistance, COUNT(tblRuns.`Primary`) AS Behu, ROUND(SUM(Duration)) AS Doba, MAX(tblRuns.`Primary`) AS Top from tblRuns;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 1!";
my @DATA = $QUERY->fetchrow_array();
my @SQL;
push @SQL, 'TotalDistance',$DATA[0];
push @SQL, 'PocetBehu',$DATA[1];
push @SQL, 'DobaInSec',$DATA[2];
push @SQL, 'LastRun',$DATA[3];


$QUERY = $dbh->prepare("select distinct YEAR(convert_tz(Date, 'UTC','CET')) AS Datum, COUNT(*) AS Pocet from tblRuns group by 1;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 2!";
while (@DATA =  $QUERY->fetchrow_array) {
	push @SQL, 'BehuRoku.'.$DATA[0],$DATA[1];
}

$QUERY = $dbh->prepare("select StartCountry, count(StartCountry) AS Kolikrat from tblRuns where StartCountry <> 'NULL' group by StartCountry;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 3!";
while (@DATA =  $QUERY->fetchrow_array) {
	push @SQL, 'Zeme.'.$DATA[0],$DATA[1];
}

$QUERY = $dbh->prepare("select count(Home) as Home from tblRuns where Home = 1;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 4!";
while (@DATA =  $QUERY->fetchrow_array) {
        push @SQL, 'Home',$DATA[0];
}

$QUERY = $dbh->prepare("select ROUND(SUM(Distance/1000),2) AS ThisMonthDistance, Monthname(CURDATE()) AS Mesic from tblRuns where Year(convert_tz(Date, 'UTC','CET')) = Year(CURDATE()) and Month(convert_tz(Date, 'UTC','CET')) = Month(CURDATE());");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 5!";
while (@DATA =  $QUERY->fetchrow_array) {
        push @SQL, 'ThisMonthMileage',$DATA[0];
	push @SQL, 'ThisMonthName',$DATA[1];
}

$QUERY = $dbh->prepare("select ROUND(SUM(Distance/1000),2) AS LastMonthDistance, MONTHNAME(DATE_ADD(CURDATE(), INTERVAL -1 MONTH)) AS MinulyMesic from tblRuns where Year(convert_tz(Date, 'UTC','CET')) = Year(DATE_ADD(CURDATE(), INTERVAL -1 MONTH)) and MONTHNAME(convert_tz(Date, 'UTC','CET')) = MONTHNAME(DATE_ADD(CURDATE(), INTERVAL -1 MONTH));");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 6!";
while (@DATA =  $QUERY->fetchrow_array) {
        push @SQL, 'LastMonthMileage',$DATA[0];
        push @SQL, 'LastMonthName',$DATA[1];
}
$QUERY = $dbh->prepare("SET \@nextDate = CURRENT_DATE;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 7!";
$QUERY = $dbh->prepare("SET \@RowNum = 1;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 7!";
$QUERY = $dbh->prepare("SELECT  \@RowNum := IF(\@NextDate = Date(tblRuns.Date), \@RowNum + 1, 1) AS RowNumber, DATE_FORMAT((tblRuns.Date), '%d. %m. %Y') AS Datum, tblRuns.`Primary`, DATE_ADD(Date(tblRuns.Date), INTERVAL (\@RowNum*(-1))+1 DAY) AS StartDate, \@NextDate := DATE_ADD(Date(tblRuns.Date), INTERVAL 1 DAY) AS NextDate FROM tblRuns ORDER BY RowNumber DESC LIMIT 1;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 7!";
while (@DATA =  $QUERY->fetchrow_array) {
        push @SQL, 'DniPoSobe',$DATA[0];
        push @SQL, 'SerieKonci',$DATA[1];
	push @SQL, 'PosledniBehSerie',$DATA[2];
	push @SQL, 'SerieZacina',$DATA[3];
	my $QUERY2 = $dbh->prepare("select tblRuns.`Primary`, DATE_FORMAT((tblRuns.Date), '%d. %m. %Y') from tblRuns where Date(tblRuns.Date) =\"".$DATA[3]."\";");
	$QUERY2->execute() or die "Nepovedlo se nacist statistiky 8!";
	while (my @DATA2 =  $QUERY2->fetchrow_array) {
		push @SQL, 'PrvniBehSerie',$DATA2[0];		
	}
}
$QUERY = $dbh->prepare("select IFNULL(Home, 2) AS Status, COUNT(IFNULL(Home, 2)) AS Pocet from tblRuns where IFNULL(StartAddress, 2) <> 2 group by Home order by Status;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 9!";

while (@DATA =  $QUERY->fetchrow_array) {
	if ($DATA[0] eq 1) {
		push @SQL, 'BehuDoma',$DATA[1]; }
	if ($DATA[0] eq 2) {
                push @SQL, 'BehuJinde',$DATA[1]; } 
}

$QUERY = $dbh->prepare("select DATE_FORMAT(convert_tz(Date, 'UTC','CET'), '%m/%Y') AS Mesic, SUM(Distance/1000) AS Vzdalenost from tblRuns group by Mesic order by Vzdalenost DESC LIMIT 1;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 10!";
while (@DATA =  $QUERY->fetchrow_array) {
	push @SQL, 'TopMesic',$DATA[0];
	push @SQL, 'TopMesicKM',$DATA[1];
}

$QUERY = $dbh->prepare("select distinct YEAR(convert_tz(Date, 'UTC','CET')) AS Rok, ROUND(SUM(Distance/1000), 2) AS Distance, ROUND(SUM(Distance/1000)/COUNT(Distance), 2) AS AvgDistance, ROUND(SUM(Duration/3600), 2) AS Hours, SUM(Duration) AS SecForPace from tblRuns group by Rok;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 11!";
while (@DATA =  $QUERY->fetchrow_array) {
        push @SQL, $DATA[0].'.Distance',$DATA[1];
	push @SQL, $DATA[0].'.AvgDistance',$DATA[2];
	push @SQL, $DATA[0].'.Hours',$DATA[3];
	push @SQL, $DATA[0].'.SecForPace',$DATA[4];
}

$QUERY = $dbh->prepare("select distinct YEAR(convert_tz(Date, 'UTC','CET')) AS Rok, ROUND(SUM(Distance/1000), 2) AS Distance, SUM(Duration) AS SecForPace from tblRuns where YEAR(Date) = 2010 AND StartAddress IS NOT NULL;");
$QUERY->execute() or die "Nepovedlo se nacist statistiky 12!";
while (@DATA =  $QUERY->fetchrow_array) {
	push @SQL, $DATA[0].'.Distance.'.$DATA[0],$DATA[1];
	push @SQL, $DATA[0].'.SecForPace.'.$DATA[0],$DATA[2];
}

$QUERY = $dbh->prepare(q{INSERT INTO tblStats (Nazev, Hodnota1) VALUES (?, ?)});

for ( my $i=0; $i<@SQL; $i=$i+2 ) {
#	print $SQL[$i].", ".$SQL[$i+1]."\n";
	$QUERY->execute($SQL[$i], $SQL[$i+1]);
}
$dbh->disconnect;
