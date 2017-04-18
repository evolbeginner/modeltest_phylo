#! /bin/bash

# Author: Sishuo Wang from the Department of Botany, The University of British Columbia
# E-mail: sishuowang@hotmail.ca
# Your question and/or suggestion is highly appreciated.

# Updated on 2014-11-23
# Some help information is updated.
# Updated on 2013-12-25
# Topology comparison based upon topology constraints using raxml and consel is now available


#######################################################################
para_compulsory=(input mode type)


########-----------------------------------------------------------------------------######
###					CONFIGURATION					###
###	Please indicate the paths or the executable files of the following tools here	###
########-----------------------------------------------------------------------------######
jmodeltest=~/software/phylo/jmodeltest-2.1.2/jModelTest.jar
prottest=~/software/phylo/prottest-3.2-20130103/prottest-3.2.jar
raxmlHPC_multi=~/software/phylo/RAxML_8.2.4/raxmlHPC-PTHREADS
#raxmlHPC_multi=~/software/phylo/RAxML_8.2.4/raxmlHPC-PTHREADS
raxmlHPC=~/software/phylo/RAxML_8.2.4/raxmlHPC
#raxmlHPC=~/software/phylo/RAxML_8.0.3/raxmlHPC
MFAtoPHY_path=""
consel_dir=~/software/phylo/consel/src # ignore this if consel is not going to be run
create_topo_file_perl="" # ignore this if the folder named "additional_tools" has already existed or you are not going to make comparisons of different topology constraints


########################################################################
show_help(){
	echo -e "USAGE:\t$0 <--input ALIGNMENT> <--type DNA or prot> <--mode raxml or phyml> [Options]"
	echo -e "Note:\tSome of the parameters are sensitive to the case of the words. So please be careful."
	echo -e "mandantory parameters"
	cat <<EOF
	--input			the name of the alignment file
	--type			DNA or prot
	--mode			raxml or phyml
				See README for information
EOF
	echo -e "optional parameters"
	cat <<EOF
	--outdir		the directory where the results wil be written to
				default: . (the current working directory)
	--modeltest_method	AIC or BIC (Only one of them could be specified once.)
				default: AIC
	--model			the only model that you want to use
				If specified, no model test will be performed.
	-b|--botstrap		bootstrap
	--test_model		the model(s) you are going to test
				default: all
				it should be given in the following format and no space is allowable
					'-JTT-WAG'
	--cpu_modeltest		num of threads for modeltest
				default: 2
	--modeltest_additional	the file including any additional arguments for for modeltest
				e.g.	--modeltest_additional ./additional_arguments_for_modeltest
	--phylo_additional	the file including any additional arguments for phylogenetic construction
				e.g.	--phylo_additional ./additional_arguments_for_phylo
	--cpu_phylo		num of threads for phylo (Sorry for that only raxml is supported now.)
				default: 1
	--input_format		fasta (Sorry for that only fasta is supported now.)
				default: fasta
	--topo_input		files containing topology constraint information
				e.g.	((1,2,3),4);
					((1,2),3,4);
	--topo_compare		whether or not to make comparison between different topologies
				At least two topologies should be given in the topology file (specified by "--topo_input") if this argument is specified
				default: off
	--topo_group		the file containing the groups of taxa (OTUs). The script will continue to be run if at least one taxa is found in every group. If no taxa in one group is detected, the analysis will not be performed.
				This parameter will only be activated if '--topo_compare' is specified and '--topo_input' is correctly set.
				e.g. if the content in the group file is as follows:
					taxa1 taxa2
					taxa3
					taxa4 taxa5
				     In the alignment, if only taxa1, taxa3 and taxa4 are all included, the script will continue to be run. However, if only taxa1, taxa2 and taxa3 are in the alignment, the script will be stopped.
	--create_topo_file_perl	the perl script used to create topology file based upon the sequences in the sequence file
	--force			remove outdir
	--clean			cover the old results of RAxML if the output names are same
					e.g. RAxML_info.test.fasta
				default: off (The script will not clean the old results of RAxML automatically)
	-h|--h|--help		show usage
EOF
	exit 1
}


read_param(){
while [ $# -gt 0 ]; do
	case $1 in
		--input)
			input="$2"
			shift
			;;
		--outdir)
			outdir="$2"
			shift
			;;
		--mode)
			mode="$2"
			shift
			;;
		--type)
			type="$2"
			shift
			;;
		-b|--bootstrap)
			bootstrap="$2"
			shift
			;;
		--model)
			model="$2"
			shift
			;;
		--test_model)
			test_model="$2"
			shift
			;;
		--cpu_modeltest)
			cpu_modeltest="$2"
			shift
			;;
		--cpu_phylo)
			cpu_phylo="$2"
			shift
			;;
		--modeltest_method)
			modeltest_method="$2"
			shift
			;;
		--phylo_additional)
			phylo_additional="$2"
			shift
			;;
		--modeltest_additional)
			modeltest_additional="$2"
			shift
			;;
		--force_phylip)
			force_phylip=1
			;;
		--topo_input)
			topo_input="$2"
			shift
			;;
		--topo_compare)
			topo_compare=1
			;;
		--topo_group)
			topo_group_file="$2"
			shift
			;;
		--create_topo_file_perl)
			create_topo_file_perl="$2"
			shift
			;;
		--clean)
			clean=1
			;;
		--force)
			is_force=1
			;;
		-h|--h|--help)
			show_help
			;;
		*)
			echo "Unknown option $1" >&2
			show_help
			;;
	esac
	shift
done
}


check_param(){
	local i
	[ -z $type ] && type='prot'

	for i in ${para_compulsory[@]}; do
		local p
		eval p=\$$i
		if [ -z $p ]; then
			echo -n "Arg "
			printf "\E[0;35;10m"; echo -n "$i"; printf "\E[0;0;0m"
			echo " has not been defined. Exiting ......"
			exit 1
		fi
	done
	
	case "$type" in
		DNA)
			modeltest_tool_HOME=`dirname $jmodeltest`
			if [ $mode == raxml -a -z $model ]; then
				echo -e "Phylogenetic method has to be phyml if you are analyzing DNA data and if model is not specified.\nExiting ......"
				exit 1
			fi
		;;
		prot)
			modeltest_tool_HOME=`dirname $prottest`
		;;
	esac

	[ -z $outdir ]		&&	outdir='.'
	[ ! -z $is_force ]	&&	rm -rf $outdir
	[ -z $modeltest_method ]&&	modeltest_method='AIC'
	[ -z $cpu_modeltest ]	&&	cpu_modeltest=2
	[ -z $cpu_phylo ]	&&	cpu_phylo=1
	[ -z $format ]		&&	input_format='fasta'
	[ -z $test_model ]	&&	test_model='-all-distributions'
	[ -z $clean ]		&&	clean=0

	S0_indir=`dirname $0`
	[ -z $MFAtoPHY_path]	&&	MFAtoPHY_path="$S0_indir/additional_tools"
	[ -z $create_topo_file_perl ]	&&	create_topo_file_perl="$S0_indir/additional_tools/create_topo_file.pl"
	[ -z $topo_group_check_tool ]	&&	topo_group_check_tool="$S0_indir/additional_tools/check_topo_group.py"
	
	[ ! -z $topo_compare ] && [ -z $topo_input ] && echo "Topology comparison will only be performed if --topo_input and --topo_compare are both specified" && exit 1
	if [ ! -z $topo_group_file ]; then
		if [ -z $topo_compare -o -z $topo_input ]; then
			echo "--topo_compare and --topo_input both need to be correctly specified if --topo_group_file is specified"
			exit 1
		else
			check_topo_group_return_value=`python $topo_group_check_tool $input $topo_group_file`
			a=`grep -o '[0-9]\+' <<< $check_topo_group_return_value`
			if [[ $a =~ [0-9]+ ]] ; then
				echo -e "\E[0;35;10mtopo_group_check failed at line $a\E[0;0;10m of the file $topo_group_file!"
				exit 1
			fi
		fi
	fi
	
	indir=`dirname $input`
	input_basename=`basename $input`
	outdir_basename=$outdir/$input_basename
	outdir1=$outdir/modeltest_tmp_${input_basename}

	if [ -e $outdir1 ]; then
		if [ $clean -eq 1 ]; then
			rm -rf $outdir1 && mkdir -p $outdir1
		else
			echo "outdir has exietd alread! Exiting ....."
			exit
		fi
	else
		mkdir -p $outdir1
	fi
}


prepare_modeltest(){
	cd $outdir1
	outdir_new=`pwd`
	cd - >/dev/null
	cp $input $outdir_new
	input_new=$outdir_new/$input_basename
	modeltest_out=$outdir_new/${input_basename}.modeltest
	cmd_out=$outdir_new/${input_basename}.cmd_out
	[ -f "$modeltest_additional" ] && modeltest_additional=`grep '[^ ]' "$modeltest_additional"`
	if [ "$test_model" != '-all-distributions' ]; then
		test_model=`sed 's/-/ -/g' <<< $test_model`
	fi
}


run_modeltest(){
	echo "running modeltest ......"
	local cmd
	
	cd $modeltest_tool_HOME
	case "$type" in
		DNA)
			cmd="java -jar $jmodeltest -d $input_new -g 4 -i -f -$modeltest_method -tr $cpu_modeltest\
			$modeltest_additional"
			;;
		prot)
			cmd="java -jar $prottest -i $input_new -S 0 \
			$test_model -F -$modeltest_method -threads $cpu_modeltest\
			$modeltest_additioanl"
			;;
	esac
	echo "$cmd" > $cmd_out
	$cmd > $modeltest_out
	cd - >/dev/null
}


get_best_model(){
	local i
	case $type in
		DNA)
			if [ -z $model ]; then
				if ! grep '::Best Models::' $modeltest_out; then
					echo "There is something wrong in jModelTest. Exiting ......" && exit 1
				fi
				read -a jmodeltest_result <<< `tail -1 $modeltest_out`
				best_model=${jmodeltest_result[1]}
				case $best_model in
					SYM*)
						best_model=`sed 's/^SYM/GTR/'   <<< "$best_model"` ;;
					HKY*)
						best_model=`sed 's/^HKY/HKY85/' <<< "$best_model"` ;;
				esac
				#for i in ${jmodeltest_result[@]:3:3}; do
				#	[ $i != ${jmodeltest_result[2]} ] && best_model=${best_model}"+F" && break
				#done
			else
				best_model=$model
			fi
			echo -e "The best model is:\t$best_model"
		;;
		prot)
			best_model=`grep -o "^Best model according to $modeltest_method: .\+" $modeltest_out`
			best_model=`grep -o "[^ ]\+$" <<< $best_model`
			echo -e "The best model is:\t$best_model"
		;;
	esac
	echo "$best_model" >> $cmd_out
	OLDIFS="$IFS";
	IFS='+'
	read -a model <<< "$best_model"
	IFS="$OLDIFS"
}


prepare_phylo(){
	local MFAtoPHY_cmd
	[ -f "$phylo_additional" ] && phylo_additional=`grep '[^ ]' "$phylo_additional"`
	if [ $input_format == 'fasta' ]; then
		#if which MFAtoPHY.pl > /dev/null; then
		#	MFAtoPHY_cmd="MFAtoPHY.pl"
		if [ ! -z MFAtoPHY_path ]; then
			MFAtoPHY_cmd="perl $MFAtoPHY_path/MFAtoPHY.pl"
		else
			MFAtoPHY_cmd="perl MFAtoPHY.pl"
		fi

		case $mode in
			phyml)
				$MFAtoPHY_cmd $input_new
				input_phy=${input_new}.phy
				;;
			raxml)
				if [ ! -z $force_phylip ]; then
					$MFAtoPHY_cmd $input_new
					input_phy=${input_new}.phy
				else
					input_phy=${input_new}
				fi
				;;
		esac
	else
		echo -e "Sorry, the input format is illegal. Currently only fasta is accepted\n\n"
		exit 1
	fi
	
	if [ ! -z $topo_input ]; then
		local topo_k=1
		local topo_dir="$outdir1/topo"
		mkdir $topo_dir
		while read line; do
			echo "$line" > $topo_dir/$topo_k
			perl $create_topo_file_perl --input $input_phy --topo_file $topo_dir/$topo_k --input_format phylip > $topo_dir/${topo_k}.tmp
			[ $? -ne 0 ] && exit 1
			mv $topo_dir/${topo_k}.tmp $topo_dir/${topo_k}
			topo=(${topo[@]} $topo_dir/$topo_k)
			((topo_k++))
		done < $topo_input

		for i in ${topo[@]}; do
			local basename
			basename=`basename $i`
			topo_file_basename=(${topo_file_basename[@]} $basename)
		done
	fi
}


run_phylo(){
	local FGI i cmd F G I
	echo "running phylogenetic reconstruction ......"

	evol_model=${model[0]}
	evol_model=`tr a-z A-Z <<< $evol_model`
	case $mode in
		phyml)
			local cmd_type
			[ $type == 'prot' ] && cmd_type='-d aa'
			[ $type == 'DNA' ]  && cmd_type='-d nt'
			for i in ${model[@]}; do
				case $i in
					F)	F='-f m';;
					G)	G='-a e';;
					I)	I='-v e';;
				esac
			done
			echo ${FGI[@]}
			bootstrap_arg=""
			if [ ! -z $bootstrap ]; then
				bootstrap_arg="-b $bootstrap"
			else
				bootstrap_arg=""
			fi
			cmd="phyml -i $input_phy $cmd_type -m $evol_model -c 4 $bootstrap_arg $F $G $I $phylo_additional"
			echo "$cmd" >> $cmd_out
			$cmd
		;;

		raxml)
			output=$input_basename
			############### 	bootstrap	################
			if [ ! -z $bootstrap ]; then
				bootstrap_cmd="-f a -# $bootstrap -x 123"
			else
				bootstrap_cmd="-f d"
			fi
			
			G='CAT'
			for i in ${model[@]}; do
				case $i in
					F)	F='F'		;;
					G)	G='GAMMA'	;;
					I)	I='I'		;;
				esac
			done

			case $type in
				prot)
					evol_model="PROT$G$I""$evol_model""$F"
					;;
				DNA)
					evol_model="$evol_model""$G""$I"
					;;
			esac

			if [ $cpu_phylo -eq 1 ];
				then raxml_tool=$raxmlHPC
			else
				raxml_tool="$raxmlHPC_multi -T $cpu_phylo"
			fi
			
			cmd="$raxml_tool -s $input_phy -m $evol_model -n $output $bootstrap_cmd -p 123 $phylo_additional $topo_cmd -w $outdir_new"
			echo "$cmd" >> $cmd_out
			$cmd

			topo_constraint
	esac
}


topo_constraint(){
	for i in ${!topo[@]}; do
		local topo_file
		topo_file=${topo[$i]}
		topo_file_basename=${topo_file_basename[$i]}
		echo $i
		echo ${topo_file_basename[0]}
		output=$input_basename'_'$topo_file_basename'.topo'
		[ ! -z $topo ] && topo_cmd="-g $topo_file";
		cmd="$raxml_tool -s $input_phy -m $evol_model -n $output $bootstrap_cmd -p 123 $phylo_additional $topo_cmd -w $outdir_new"
		echo "$cmd" >> $cmd_out
		$cmd
		
		run_site_log
	done
}


run_site_log(){
	local constraint_tree evol_model_site_log
	constraint_tree="$outdir_new/RAxML_bestTree."$output
	evol_model_site_log=`echo $evol_model | sed 's/CAT/GAMMA/'` # CAT -> GAMMA
	cmd="$raxml_tool -s $input_phy -m $evol_model_site_log -n ${output}.sitelog -f g -p 123 $phylo_additional -z $constraint_tree -w $outdir_new"
	echo "$cmd" >> $cmd_out
	$cmd
}


run_consel(){
	echo "running consel ......"
	local consel_outdir=$1
	local consel_infile_k=0
	local consel_infile1="$consel_outdir/consel.sitelh"
	local consel_infile2="$consel_outdir/consel"
	local consel_outfile="$consel_outdir/consel.output"
	for i in $consel_outdir/RAxML_perSiteLLs.$basename*sitelog; do
		echo -e "\n$i"
		[ $consel_infile_k -eq 0 ] && sed -ne '1p' $i > $consel_infile1 && consel_infile_k=1
		sed -ne '2p' $i >> $consel_infile1
	done

	local NO_of_topo=`expr \`wc -l $consel_infile1 | awk '{print $1}'\` - 1`
	export NO_of_topo
	perl -pi -e 'if($.==1){$_=~s/^(\s*)(\d+)/$1$ENV{'NO_of_topo'}/} else{$_=~s/(?<=tr)(\d)/++$k/e}' $consel_infile1
	export -n NO_of_topo

	export PATH=$PATH:$consel_dir
	makermt --puzzle $consel_infile1
	consel $consel_infile2
	catpv  $consel_infile2 > $consel_outfile
	rm $consel_outdir/consel.{ci,pv,rmt,vt}

	get_consel_result(){
		local consel_outfile2=$1
		perl -ne 'chomp(); @line=split/[ \|]+/; next if $line[1]!~/^\d+$/; map {print $_."\t"} @line[1..$#line]; print"\n"' $consel_outdir/consel.output > $consel_outfile2
	}
	get_consel_result $consel_outdir/$input_basename.consel.output2

}


############################################################################################################
############################################################################################################
read_param $@

check_param

prepare_modeltest

if [ ! -z $model ]; then
	echo $model >> $cmd_out
else
	run_modeltest
fi

get_best_model

prepare_phylo

run_phylo

[ ! -z $topo ] && [ ! -z $topo_compare ] && run_consel $outdir_new


