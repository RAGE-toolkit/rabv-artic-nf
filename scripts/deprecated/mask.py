#!/usr/bin/env python

from Bio import SeqIO
import sys
from cyvcf2 import VCF
import pandas as pd
import argparse

def read_3col_bed(fn):
    # Read the primer scheme into a pandas DataFrame
    bedfile = pd.read_csv(fn, sep='\t', header=None,
                          names=['chrom', 'start', 'end'],
                          dtype={'chrom': str, 'start': int, 'end': int},
                          usecols=(0, 1, 2),
                          skiprows=0)
    return bedfile

def go(args):
    seqs = {rec.id: rec for rec in SeqIO.parse(open(args.reference), "fasta")}
    cons = {k: list(seqs[k].seq) for k in seqs}

    bedfile = read_3col_bed(args.maskfile)
    for _, region in bedfile.iterrows():
        for n in range(region['start'], region['end']):
            cons[region['chrom']][n] = 'N'

    for record in VCF(args.maskvcf):
        for n in range(0, len(record.REF)):
            cons[record.CHROM][record.POS - 1 + n] = 'N'

    with open(args.output, 'w') as fh:
        for k in seqs:
            fh.write(f">{k}\n")
            fh.write("".join(cons[k]) + '\n')

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('reference')
    parser.add_argument('maskfile')
    parser.add_argument('maskvcf')
    parser.add_argument('output')
    args = parser.parse_args()
    go(args)

if __name__ == "__main__":
    main()

