# GFFtoolkit
Extracts information from GFF and prepare them in bed format

## Required tools

This tool requires the following from kentutils, which should be downloaded from
http://hgdownload.soe.ucsc.edu/admin/exe/ or any other related source.
- gff3ToGenePred
- genePredToBed
- bedGeneParts
- tabQuery

For linux\_x86 machines either downloaded all the tools or download them individually:

Note: assumes you have `$HOME/bin` or you want these tools to be in your `$PATH`. Otherwise baby, you should skip
replace `${HOME}/bin/` in the script below with to whatever path you want.

```bash
for i in gff3ToGenePred genePredToBed bedGeneParts tabQuery
do
  rsync -aP \
     rsync://hgdownload.soe.ucsc.edu/genome/admin/exe/linux.x86_64/${i} ${HOME}/bin/
done
```
## Running GFFtoolkit

The following script will create a bed file from a sample GFF3 file within `data` directory. The output structure is
explained later on.

```bash
bash GFFtoolkit.sh -i data/gencode.v19.annotation.chr22.gff3 -o test/
```

## Input data

- Input data is a GFF3 file downloaded from gencode. You can download your own GFF3 for hg19 using the command below:

```bash
wget ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_19/gencode.v19.annotation.gff3.gz
```

## Output data

From the files above, the most important ones are:

1. **transcript_table**: A table of transcripts found in the GFF3 files with extra column information. This file can be queried
using tabQuery.
2. **gene_table**: A table of genes found in the GFF3 files with extra column information. This file can be queried
using tabQuery.
3. **gencode.v19.annotation.exons.extended**: If the input file is named the `gencode.v19.annotation.gff3` the
`GFF3\_rootname.exons.extended` is list of exons for each transcript.
4. **gencode.v19.annotation.exons.extended.simpleid**: If the input file is named the `gencode.v19.annotation.gff3` the
`GFF3\_rootname.exons.extended.simpleid` is list of exons for each transcript but strips version number from these IDs. 

Running the example above will generate a result folder within this repo. It within that path, it will generate the following files:

```
├── attrsOut
├── attrsOut_table
│   ├── attrsOut -> ../attrsOut
│   ├── gene
│   │   ├── gene_id
│   │   ├── gene_name
│   │   ├── gene_status
│   │   ├── gene_type
│   │   ├── havana_gene
│   │   ├── ID
│   │   ├── level
│   │   ├── tag
│   │   ├── transcript_id
│   │   ├── transcript_name
│   │   ├── transcript_status
│   │   └── transcript_type
│   ├── gene_table
│   ├── transcript
│   │   ├── ccdsid
│   │   ├── gene_id
│   │   ├── gene_name
│   │   ├── gene_status
│   │   ├── gene_type
│   │   ├── havana_gene
│   │   ├── havana_transcript
│   │   ├── ID
│   │   ├── level
│   │   ├── ont
│   │   ├── Parent
│   │   ├── protein_id
│   │   ├── tag
│   │   ├── transcript_exon_count
│   │   ├── transcript_id
│   │   ├── transcript_length
│   │   ├── transcript_name
│   │   ├── transcript_status
│   │   └── transcript_type
│   └── transcript_table
├── gencode.v19.annotation.chr22.bed
├── gencode.v19.annotation.chr22.exons
├── gencode.v19.annotation.chr22.exons.extended
├── gencode.v19.annotation.chr22.exons.extended.simpleid
└── gencode.v19.annotation.chr22.gp
```
