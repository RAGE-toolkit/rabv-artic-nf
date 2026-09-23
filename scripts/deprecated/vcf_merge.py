from cyvcf2 import VCF, Writer
import sys
from collections import defaultdict
from vcftagprimersites import read_bed_file


def vcf_merge(args):
    # Load BED file
    bed = read_bed_file(args.bedfile)
    primer_map = defaultdict(dict)

    # Build primer map: {PoolName: {pos: Primer_ID}}
    for p in bed:
        for n in range(p['start'], p['end'] + 1):
            primer_map[p['PoolName']][n] = p['Primer_ID']

    # Parse input VCF list (format: POOL:/path/to/file.vcf)
    first_vcf = None
    pool_map = {}
    for param in args.vcflist:
        pool_name, file_name = param.split(":")
        pool_map[file_name] = pool_name
        if not first_vcf:
            first_vcf = file_name

    # Open first VCF and declare new INFO field
    first_reader = VCF(first_vcf)
    first_reader.add_info_to_header({
        'ID': 'Pool',
        'Description': 'The pool name',
        'Type': 'String',
        'Number': '1'
    })

    writer = Writer(args.prefix + '.merged.vcf', first_reader)
    writer_primers = Writer(args.prefix + '.primers.vcf', first_reader)

    # Collect variants with pool info
    variants = []
    for file_name, pool_name in pool_map.items():
        reader = VCF(file_name)
        for v in reader:
            # Cannot set v.INFO["Pool"] directly, so store externally
            variants.append((v, pool_name))
        reader.close()

    # Sort variants
    variants.sort(key=lambda r: (r[0].CHROM, r[0].POS))

    # Write to correct output
    for v, pool in variants:
        pos = v.POS
        if pool in primer_map and pos in primer_map[pool]:
            writer_primers.write_record(v)
            print(f"found primer binding site mismatch: {primer_map[pool][pos]}", file=sys.stderr)
        else:
            writer.write_record(v)

    writer.close()
    writer_primers.close()


def main():
    import argparse

    parser = argparse.ArgumentParser(description='Merge VCFs and flag variants at primer sites.')
    parser.add_argument('prefix', help='Output file prefix')
    parser.add_argument('bedfile', help='Primer BED file')
    parser.add_argument('vcflist', nargs='+', help='VCFs to merge, format: POOL:/path/to/file.vcf')

    args = parser.parse_args()
    vcf_merge(args)


if __name__ == "__main__":
    main()

