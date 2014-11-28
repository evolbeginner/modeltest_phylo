#! /usr/bin/perl

use strict;
use 5.010;
use File::Spec;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;

#########################################################################
my @programmes = qw(raxmlHPC raxmlHPC phyml consel puzzle);

#########################################################################
my $not_found_aref = &look_For_Programme(\@programmes);
&check_Programme($not_found_aref);

#########################################################################
sub look_For_Programme{
	my $programmes_aref = shift();
	my @programmes = @$programmes_aref;
	my %found;
	for my $ENV_path (split(/:/,$ENV{PATH})){
		for my $p (@programmes){
			$found{$p}=1 and next if (-x File::Spec->catfile($ENV_path, $p));
		}   
	
	}
	my @not_found = grep {not exists $found{$_}} @programmes;
	return (\@not_found);
}

sub check_Programme{
	my $not_found_aref = shift();
	my %error_message_programme = (
		'raxmlHPC'        => "Phylogenetic analysis using RAxML cannot be performed.",
		'raxmlHPC-PTHREAD'=> "Phylogenetic analysis using RAxML multi-threads cannot be performed.",
		'phyml'           => "Phylogenetic analysis using phyml cannot be performed.",
		'consel'          => "Topology constraint based phylogenetic analysis cannot be performed.",
		'puzzle'          => "quartet comparion cannot be performed."
	);
	foreach (@$not_found_aref){
 			print BOLD "$_ ";
			print "is not found in your ENV path.\n";
			print "\t$error_message_programme{$_}\n";
	}
}


