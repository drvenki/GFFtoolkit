#!/bin/bash
# Hassan July 4, 2018

set -euo pipefail

B_RED='\033[0;31m';
B_GRN='\033[0;32m';
B_YLW='\033[1;33m';
B_NOCOL='\033[0m';

iFlag=false
oFlag=false

if [ $# -eq 0 ]; then
  echo $"
USAGE: $0 [-i INPUTGFF -o OUTPUTPATH]

  GFFtoolkit v0.1.0 A tool to extract information from GFF3 files and prepare in bed format

  -i INPUTGFF     Input GFF3 file path
  -o OUTPUTPATH   Output path
" >&2
  exit 0
fi

while getopts ":i:o:h" opt; do
  case $opt in
    i) iFlag=true;INPUTGFF=${OPTARG};;
    o) oFlag=true;OUTPUTPATH=${OPTARG};;
    h)
      echo $"
USAGE: $0 [-i INPUTGFF -o OUTPUTPATH]

  GFFtoolkit v0.1.0 A tool to extract information from GFF3 files and prepare in bed format

  -i INPUTGFF     Input GFF3 file path
  -o OUTPUTPATH   Output path
" >&2
      exit 0
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires a argument." >&2
      exit 1
      ;;
  esac
done

shift $(($OPTIND - 1))

if ! $iFlag
then
  echo "-i missing"
  eFlag=true
fi

if ! $oFlag
then
  echo "-o missing"
  eFlag=true
fi

for i in gff3ToGenePred genePredToBed bedGeneParts tabQuery
do
  if ! hash $i 2> /dev/null
  then
    echo -ne "${B_RED}"
    echo -e "$i command was not found"
    exit 1
  fi
done

echo -ne "${B_YLW}"
[ "$OUTPUTPATH" == "./" ] && \
  echo "Changing $OUTPUTPATH to absolute path. Use absolute path next time!" && \
  OUTPUTPATH=${PWD}/${OUTPUTPATH}


# Get path to input file
ROOTFNAME=`echo $INPUTGFF | rev | cut -d "/" -f 1 | cut -d "." -f 2- | rev`
INPUTGFF=`readlink -e $INPUTGFF`

echo -ne "${B_YLW}"
echo -e "Creating $OUTPUTPATH if it doesn't exist"
mkdir -p $OUTPUTPATH

echo -ne "${B_NOCOL}"
echo -n "Converting GFF3 to BED and extracting attributes."
cd $OUTPUTPATH
gff3ToGenePred -attrsOut=attrsOut \
    -refseqHacks \
    $INPUTGFF $ROOTFNAME.gp

echo -e "${B_GRN}..done!" 
genePredToBed \
    $ROOTFNAME.gp \
    $ROOTFNAME.bed
echo -ne "${B_NOCOL}"

echo -n "Extracting exons."
bedGeneParts exons \
    $ROOTFNAME.bed \
    $ROOTFNAME.exons
echo -e "${B_GRN}..done!" 
echo -ne "${B_NOCOL}"

echo -n "Separating attributes into individual files."
mkdir -p attrsOut_table/gene;
mkdir -p attrsOut_table/transcript;
cd attrsOut_table
ln -f -s ../attrsOut .
awk -F"\t" \
    '$1~/ENSG/ {print $1,$3 >"gene/"$2;} $1~/ENST/ {print $1,$3 >"transcript/"$2}' \
    attrsOut

for i in `find . -type f`; do \
    colname=`echo $i | cut -d"/" -f 3`; \
    echo -ne "..$colname.."
    sed -i "1i ensemble_id\t$colname" $i; \
done

echo -ne "..transcript_length.."
awk '{split($11,l,","); for (i in l) s[$4]+=l[i];
      }END{
      print "ensemble_id\ttranscript_length" > "transcript/transcript_length";
      for (i in s) print i"\t"s[i] > "transcript/transcript_length"}' \
      ../$ROOTFNAME.bed
sort -k1,1 transcript/transcript_length -o transcript/transcript_length

echo -ne "..exon_count.."
awk '{n=split($11,l,","); s[$4]=(n-1);
      }END{
      print "ensemble_id\texon_count" > "transcript/transcript_exon_count";
      for (i in s) print i"\t"s[i] > "transcript/transcript_exon_count"}' \
      ../$ROOTFNAME.bed
sort -k1,1 transcript/transcript_exon_count -o transcript/transcript_exon_count

for i in `find . -type f`; do \
    sed -i "s/ /\t/g" $i; \
    sort -k1,1 $i -o $i;
done
echo -e "${B_GRN}..done!" 
echo -ne "${B_NOCOL}"

echo -n "Adding following annotation to gene table.."
outfile="gene_table"; \
mainfile="gene_id"; \
cut -f 1 gene/$mainfile > $outfile; \
filelist=`find gene/ -type f | grep -v ${mainfile}`; \
for i in $filelist; do \
    echo -ne "..$i.."
    N=`head -n1 $outfile | awk '{print NF}'`; \
    join -a 1 -a 2 -e NaN \
        -o `eval echo 1.{1..$N}| tr ' ' ','`,2.2 \
        $outfile $i \
        | tr ' ' '\t' \
        | sort -k1,1 > tmp; \
    mv tmp $outfile;
done
echo -e "${B_GRN}..done!" 
echo -ne "${B_NOCOL}"

echo -n "Adding following annotation to gene table.."
outfile="transcript_table"; \
mainfile="transcript_id"; \
cut -f 1 transcript/$mainfile > $outfile; \
filelist=`find transcript/ -type f | grep -v ${mainfile}`; \
for i in $filelist; do \
    echo -ne "..$i.."
    N=`head -n1 $outfile | awk '{print NF}'`; \
    join -a 1 -a 2 -e NaN \
        -o `eval echo 1.{1..$N}| tr ' ' ','`,2.2 \
        $outfile $i \
        | tr ' ' '\t' \
        | sort -k1,1 > tmp; \
    mv tmp $outfile;
done
echo -e "${B_GRN}..done!" 
echo -ne "${B_NOCOL}"

cd ..

echo -n "Creating exon table.."
join -1 4 -2 1 \
    -o 1.1,1.2,1.3,1.4,1.6,2.2,2.3,2.4,2.5,2.6,2.7,2.8 \
    <( sort -k4,4 ${ROOTFNAME}.exons ) \
    <( tabQuery ' select ensemble_id,gene_type,transcript_type,transcript_length,exon_count,transcript_status,gene_name,gene_id from attrsOut_table/transcript_table ' | sort -k1,1 ) \
    | tr ' ' '\t' | sort -k1,1 -k2,2n -k3,3n \
    > $ROOTFNAME.exons.extended
echo -e "${B_GRN}..done!" 
echo -ne "${B_NOCOL}"

echo -n "Removing 'chr' and id version from genes and transcript of exon table.."
awk -v OFS="\t" \
    '$1~/chr[1-9,M]/ { split($1,l,"r"); $1=l[2]; for (i=1; i<=NF; i++) { if ($i ~ /ENS[GT]000/ ) {split($i,l,"."); $i=l[1]} }; print; }' \
    $ROOTFNAME.exons.extended > $ROOTFNAME.exons.extended.simpleid
echo -e "${B_GRN}..done!" 
echo -ne "${B_NOCOL}"

echo -e "${B_GRN}Analysis Done!"
