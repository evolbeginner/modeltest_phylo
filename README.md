#####################################################################
1.	Type "modeltest_phylo_DNA.sh.no_phylip -h (or -help)" to see the usage of the script.
	Before starting to run the script, please make sure that all of the information in the CONFIGURATION section in the script modeltest_phylo_DNA2.sh is correct. Ortherwise, please change them (the full path must be given for jmodeltest and prottest).

2.	The script should be run finely in both Linux and MACS.
	Before starting analyzing your data, please type "perl check_requirements.pl" to check whether necessary software have been correctly installed. If not, please install the corresponding software accoreding to actual demand.
	The following software are needed to do analyses for DNA or/and amino acids sequences
	ProtTest 3.2 (for amino acids, "https://code.google.com/p/prottest3/")
	jmodeltest-2.1 (for DNA, "https://code.google.com/p/jmodeltest2/")
	phyml 3.0 (for DNA or amino acids, "https://code.google.com/p/phyml/")
	RAxML 7.3.9 (for amino acids only, "http://sco.h-its.org/exelixis/software.html")
	Perl 5.010 or later version ("http://www.perl.org/get.html")
	python 2.3 or later version ("http://www.python.org/about/")
	Note:
		1)	Earlier (or later) versions of any of these software may work finely but could lead to failure.
		2)	There is another simpler Linux version whose name is "modeltest_phylo_DNA.sh" (sorry for that the usage and the instruction of it is not well documented).

	Optional requirements:
	consel (for topology comparison, http://www.is.titech.ac.jp/~shimo/prog/consel/)
	create_topo_file.pl (supposed to be found in the directory "additional_tools")

3.	For phyml users, it is needed to convert the file format before phyml is run.
	So you need to have a file named "$input.phy" under the outdir (output directory).
	e.g., if your alignment file's name is "test.fasta", the name of the phylip format file should be "test.fasta.phy". This could be done by adding something in the script which is very easy. Otherwise, I recommend to use the script "MFAtoPHY.pl" to help you do it (see section 5 for more details).

4.	For RAxML users, check if your version can read fasta file (the latest version seems to be able to do it 201308).
	If so, you do not need to add the argument "--force_phylip" in the command line.
	Otherwise, you need to indicate "--force_phylip" in the command line. Using this argument the script will finish the format conversion automatically. Similar to phyml, you can either convert the file format yourself or use the script recommended (MFAtoPHY.pl, see section 5 for more details).

5.	How to use MFAtoPHY.pl to enable the automatic conversion of alignment format?
	This script was originally downloaded from http://cogeme.ex.ac.uk/tmp/ariadne/phylogeny/MFAtoPHY.pl
	You can do it by any of the following ways.
	1)	Add it to the environment veriable.
		e.g.    export PATH=$PATH:PATH_TO_MFAtoPHY.pl
	2)	Put it in your current working directory.
	3)	Indicate its full path in the CONFIGURATION part of the script
	The script is able to choose a proper way itself.

6.	There will be something wrong if the following argument is given
		"--mode raxml --type DNA"
	This is because the model for DNA substitution is too few. So if you want to do analysis for DNA sequences, please use "--mode phyml --type DNA"

7.	You can give additional arguments by giving the argument --modeltest_additional or --phylo_additional. You need to give the corresponding file name that includes additional arguments of the corresponding analysis. See the example/example_additional_file for more details. If the same arguments are given more than once (e.g. raxmlHPC -f a -f i), only the latest one will be considered in the real analysis.

8.	Topology comparison based on topology constraints can be performed if "--topo_input" is specified. A file containing at least 2 topologies should be included in this file. Detailed information of how to prepare for this file can be got by typing "perldoc create_topo_file.pl".

9.	The original commands for
		modeltest
		phylogenetic construction
		the result of the best model
	will be shown in the file *.cmd_out in the result folder

10.	If you are going to analyze many alignemnts, you can put them in the same folder. Then run the following command (this is a very simple way without choosing any optional arguments) to have a test
		for i in PATH_TO_THE_FOLDER/*; do
			[ ! -f $i ] && continue;
			PATH_TO_SCRIPT/modeltest_phylo_DNA2.sh --input $i --mode raxml --type prot;
		done

11.	If you have any questions, suggestions about new functions or want to report bugs, please send e-mail to
	"sishuowang@hotmail.ca" or "tomassonwss@gmail.com"
	Your help will be highly appreciated.

