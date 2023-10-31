#!/bin/bash
# download sequence
FILE=`readlink -e $0`
bindir=`dirname $FILE`
dbdir=`dirname $bindir`

cd $dbdir
mkdir -p $dbdir/raw/sequence/
if [ ! -s "$dbdir/raw/sequence/CAFA3_training_data.tgz" ];then
    wget https://biofunctionprediction.org/cafa-targets/CAFA3_training_data.tgz -O $dbdir/raw/sequence/CAFA3_training_data.tgz
fi

mkdir -p $dbdir/curated/sequence/
mkdir -p $dbdir/tmp
cd $dbdir/tmp
tar -xvf $dbdir/raw/sequence/CAFA3_training_data.tgz
cd $dbdir

$bindir/fasta2tsv $dbdir/tmp/CAFA3_training_data/uniprot_sprot_exp.fasta - |sort -k1,1 -u > $dbdir/tmp/uniprot_sprot_exp.tsv
$bindir/tsv2fasta $dbdir/tmp/uniprot_sprot_exp.tsv $dbdir/curated/sequence/uniprot_sprot_exp.fasta

$bindir/curate_cafa3 $dbdir/tmp/CAFA3_training_data/uniprot_sprot_exp.txt $dbdir/curated/sequence/uniprot_sprot_exp $dbdir/curated/ontology/alt_id.csv $dbdir/curated/ontology/is_a.csv


$bindir/makeblastdb -in   $dbdir/curated/sequence/uniprot_sprot_exp.fasta -dbtype prot -title uniprot_sprot_exp -parse_seqids -logfile $dbdir/tmp/makeblastdb.log
$bindir/diamond prepdb -d $dbdir/curated/sequence/uniprot_sprot_exp.fasta

$bindir/calculate_ic $dbdir/curated/sequence/uniprot_sprot_exp.F.is_a $dbdir/curated/ontology/naive.F $dbdir/curated/ontology/is_a.csv $dbdir/curated/ontology/name.csv
$bindir/calculate_ic $dbdir/curated/sequence/uniprot_sprot_exp.P.is_a $dbdir/curated/ontology/naive.P $dbdir/curated/ontology/is_a.csv $dbdir/curated/ontology/name.csv
$bindir/calculate_ic $dbdir/curated/sequence/uniprot_sprot_exp.C.is_a $dbdir/curated/ontology/naive.C $dbdir/curated/ontology/is_a.csv $dbdir/curated/ontology/name.csv

$bindir/IA.py F $dbdir/curated/ontology/is_a.csv $dbdir/curated/sequence/uniprot_sprot_exp.F.is_a $dbdir/tmp/IA.F
$bindir/IA.py P $dbdir/curated/ontology/is_a.csv $dbdir/curated/sequence/uniprot_sprot_exp.P.is_a $dbdir/tmp/IA.P
$bindir/IA.py C $dbdir/curated/ontology/is_a.csv $dbdir/curated/sequence/uniprot_sprot_exp.C.is_a $dbdir/tmp/IA.C
cat $dbdir/tmp/IA.F $dbdir/tmp/IA.P $dbdir/tmp/IA.C |sort > $dbdir/curated/ontology/IA.txt

$bindir/makeblastdb -in   $dbdir/curated/sequence/uniprot_sprot_exp.fasta -dbtype prot -title uniprot_sprot_exp -parse_seqids -logfile $dbdir/tmp/makeblastdb.log
$bindir/diamond prepdb -d $dbdir/curated/sequence/uniprot_sprot_exp.fasta
$bindir/mmseqs/bin/mmseqs createdb $dbdir/curated/sequence/uniprot_sprot_exp.fasta $dbdir/curated/sequence/uniprot_sprot_exp
$bindir/hhsuite2/scripts/kClust2db.py $dbdir/curated/sequence/uniprot_sprot_exp.fasta $dbdir/curated/sequence/uniprot_sprot_exp.hh2
