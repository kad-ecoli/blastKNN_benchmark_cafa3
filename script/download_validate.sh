#!/bin/bash
# download sequence
FILE=`readlink -e $0`
bindir=`dirname $FILE`
dbdir=`dirname $bindir`

cd $dbdir
mkdir -p $dbdir/raw/sequence/
if [ ! -s "$dbdir/raw/sequence/CAFA3_targets.tgz" ];then
    wget https://biofunctionprediction.org/cafa-targets/CAFA3_targets.tgz -O $dbdir/raw/sequence/CAFA3_targets.tgz
fi
if [ ! -s "$dbdir/raw/sequence/supplementary_data.tar.gz" ];then
    wget https://figshare.com/ndownloader/files/17519846 -O $dbdir/raw/sequence/supplementary_data.tar.gz
fi


mkdir -p $dbdir/curated/sequence/
mkdir -p $dbdir/tmp
cd $dbdir/tmp
tar -xvf $dbdir/raw/sequence/CAFA3_targets.tgz
tar -xvf $dbdir/raw/sequence/supplementary_data.tar.gz
tar -xvf $dbdir/tmp/supplementary_data/cafa3/benchmark20171115.tar
cd $dbdir

cat $dbdir/tmp/benchmark20171115/groundtruth/leafonly_MFO.txt|sed 's/$/\tF/g' >  $dbdir/tmp/leafonly.txt
cat $dbdir/tmp/benchmark20171115/groundtruth/leafonly_BPO.txt|sed 's/$/\tP/g' >> $dbdir/tmp/leafonly.txt
cat $dbdir/tmp/benchmark20171115/groundtruth/leafonly_CCO.txt|sed 's/$/\tC/g' >> $dbdir/tmp/leafonly.txt
cat $dbdir/tmp/Target\ files/target*.fasta |cut -f1 -d' ' | $bindir/fasta2tsv - - |sort -u -k1,1 | $bindir/tsv2fasta - $dbdir/tmp/target.fasta

mkdir -p $dbdir/curated/sequence/
$bindir/curate_cafa3 $dbdir/tmp/leafonly.txt $dbdir/curated/sequence/validate $dbdir/curated/ontology/alt_id.csv $dbdir/curated/ontology/is_a.csv

$bindir/combineFPC.py $dbdir/curated/sequence/validate.list $dbdir/curated/sequence/validate.F.is_a $dbdir/curated/sequence/validate.P.is_a $dbdir/curated/sequence/validate.C.is_a $dbdir/curated/sequence/validate.3.is_a

cat $dbdir/tmp/target.fasta | $bindir/fasta2tsv - - |sort -u -k1,1 | $bindir/tsv2fasta - - | 
$bindir/fasta2miss $dbdir/curated/sequence/validate.list $dbdir/tmp/target.fasta $dbdir/tmp/miss.list $dbdir/curated/sequence/validate.fasta
