#! /usr/bin/perl

# Please type "perldoc create_top_file.pl to see the usage"

=pod

=head1 create_topo_file.pl

 aimming at eliminating OTUs in a tree file (or a topology constraint file) that do not appear in the sequence file
 generating a new tree file (or topology file) based upon the original topology constraints

 Updated 2014-01-11

=head1 HOWTO

 perl create_topo_file.pl <--input input_file> <--input_format format_of_input> <--topo_file your_tree_file> [--help]
 Note:	Only fasta and phylip format are supported now.

=head1 more information

 topology_file:	((1,2),3,4);
 sequence titles in the sequence_file:	1 2 3
 then the topology_file will be changed to ((1,2),3);
 Note:	
 	1. The topology file should not contain any space, e.g., the following format is not OK.
 		((1, 2), 3, 4);
	2. There should be a semicolon at the end of the topology file

=head1 contact
 
 If you have any suggestions, questions and/or comments about this script, please do not hesitate to e-mail me at "tomassonwss@gmail.com" or "sishuowang@hotmal.ca". Your help will be highly appreciated!

=cut

##################################################################################
use strict;
use Getopt::Long;
use 5.010;

my ($input, $input_format, $topo_file, $help);
my (%seq_title);

##################################################################################
GetOptions(
	'input=s'		=>	\$input,
	'input_format=s'	=>	\$input_format,
	'topo_file=s'		=>	\$topo_file,
	'h|help!'			=>	\$help,
) || die "illegal param!\n";
$help && &show_help();

##################################################################################
given($input_format){
	when('fasta')	{&read_fasta($input);}
	when('phylip')	{&read_phylip($input);}
}

&generate_newtopo($topo_file);

##################################################################################
sub generate_newtopo{
	my ($topo_file) = @_;
	open (my $IN, '<', "$topo_file") || die "failed to open topo_file $topo_file!\n";
	while(<$IN>){
		chomp;
		$_ =~ s/([^\(\)\,\;]+)/&replace($1,\%seq_title)/eg;
		$_ = &refine_newick_format($_);
		print $_."\n";
	}

	sub replace{
		my ($seq_name, $seq_title_href) = @_;
		if (exists $seq_title_href->{$seq_name}){
			return($seq_name);
		}
		else{
			return('');
		}
	}
}

sub refine_newick_format{
	my ($newick) = @_;
	my $k=0;
	$newick =~ s/\,{2,}/\,/g	and	++$k;	# ,,,
	$newick =~ s/\,\)/\)/g		and	++$k;	# ,)
	$newick =~ s/\(\,/\(/g		and	++$k;	# (,
	$newick =~ s/\([,]*\)//g	and	++$k;	# ()
	my $levelN;
	$levelN = qr/ \(( [^()] | (??{ $levelN }) )* \) /x;
	#print "newick:\t$newick\n";
	while($newick =~ /\(/g){
		my $string = $& . $';
		if ($string =~ /($levelN)/g){
			my $replace;
			my $parenthesis_content = $1;
			#print $parenthesis_content."\n";
			if ($parenthesis_content =~ /^\(\( (.+) \)\)$/x){	# ((taxa1,taxa2)) or ((taxa1,(taxa2,taxa3)))
				if ($parenthesis_content =~ /^\( ($levelN) \)$/x){
					my $replace = $1;
					next if $newick =~ /\Q$parenthesis_content\E\;/; 
					$newick =~ s/\Q$parenthesis_content\E/$replace/;
				}
			}
			elsif ($parenthesis_content =~ /^\( ([^,()]+) \)$/x){	# (taxa)
				my $replace = $1;
				next if $newick =~ /\Q$parenthesis_content\E\;/; 
				$newick =~ s/\Q$parenthesis_content\E/$replace/;
			}
		}
	}

	if ($k==0){
		return($newick);
	}
	else{
		&refine_newick_format($newick);
	}
}

sub read_fasta{
	my ($input) = @_;
	open (my $IN, '<', "$input") || die "failed to open the input $input!\n";
	while(<$IN>){
		chomp;
		if ($_ =~ /^>(.+)/){
			$seq_title{$1}=1
		}
	}
}

sub read_phylip{
	my ($input) = @_;
	open (my $IN, '<', "$input") || die "failed to open the input $input";
	while(<$IN>){
		chomp;
		next if $. == 1;
		if ($_ =~ /^(\S+)/){
			$seq_title{$1}=1;
		}
	}
}

sub show_help{
	system "perldoc $0";
	exit 1;
}

