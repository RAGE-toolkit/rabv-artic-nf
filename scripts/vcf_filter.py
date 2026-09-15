from cyvcf2 import VCF, Writer
import argparse
from collections import defaultdict


def in_frame(v):
    if len(v.ALT) > 1:
        print("This code does not support multiple genotypes!")
        raise SystemExit
    ref = v.REF
    alt = v.ALT[0]
    bases = len(alt) - len(ref)
    if bases == 0:
        return True
    if bases % 3 == 0:
        return True
    return False


class NanoporeFilter:
    def __init__(self, no_frameshifts):
        self.no_frameshifts = no_frameshifts

    def check_filter(self, v):
        try:
            total_reads = float(v.INFO.get('TotalReads', 0))
            qual = v.QUAL
            strandbias = float(v.INFO.get('StrandFisherTest', 0))

            if total_reads == 0 or qual / total_reads < 3:
                return False

            if self.no_frameshifts and not in_frame(v):
                return False

            if v.is_indel:
                strand_fraction_by_strand = v.INFO.get('SupportFractionByStrand', [1.0, 1.0])
                if float(strand_fraction_by_strand[0]) < 0.5 or float(strand_fraction_by_strand[1]) < 0.5:
                    return False

            if total_reads < 20:
                return False

        except Exception as e:
            print(f"Error processing variant {v.CHROM}-{v.POS}: {e}")
            return False

        return True


class MedakaFilter:
    def __init__(self, no_frameshifts):
        self.no_frameshifts = no_frameshifts

    def check_filter(self, v):
        depth = v.INFO.get('DP', 0)
        if depth < 20:
            return False

        if self.no_frameshifts and not in_frame(v):
            return False

        if v.num_het > 0:
            return False

        return True


def go(args):
    vcf_reader = VCF(args.inputvcf)

    variants = list(vcf_reader)

    # Some callers (e.g. longshot) write VCFs with no ##contig header line.
    # Without one, cyvcf2/htslib silently drops every record written through
    # a Writer built from this header (fails with "CONTIG id=0 not present
    # in the header" on stderr, no Python exception) - so register any CHROM
    # seen in the data before creating the writers.
    seen_chroms = set()
    for v in variants:
        if v.CHROM not in seen_chroms:
            seen_chroms.add(v.CHROM)
            vcf_reader.add_to_header(f'##contig=<ID={v.CHROM}>')

    vcf_writer = Writer(args.output_pass_vcf, vcf_reader)
    vcf_writer_filtered = Writer(args.output_fail_vcf, vcf_reader)

    if args.nanopolish:
        filter = NanoporeFilter(args.no_frameshifts)
    elif args.medaka:
        filter = MedakaFilter(args.no_frameshifts)
    else:
        print("Please specify a VCF type, i.e. --nanopolish or --medaka\n")
        raise SystemExit

    group_variants = defaultdict(list)
    for v in variants:
        key = f"{v.CHROM}-{v.POS}"
        group_variants[key].append(v)

    for v in variants:
        if args.medaka:
            if v.INFO.get('DP', 0) <= 1:
                continue
            if v.QUAL < 20:
                continue

        if filter.check_filter(v):
            vcf_writer.write_record(v)
        else:
            variant_passes = False
            key = f"{v.CHROM}-{v.POS}"
            if len(group_variants[key]) > 1:
                for check_variant in group_variants[key]:
                    if filter.check_filter(check_variant):
                        variant_passes = True
                        break

            if not variant_passes:
                vcf_writer_filtered.write_record(v)
            else:
                print(f"Suppress variant {v.POS}")

    vcf_writer.close()
    vcf_writer_filtered.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--nanopolish', action='store_true')
    parser.add_argument('--medaka', action='store_true')
    parser.add_argument('--no-frameshifts', action='store_true')
    parser.add_argument('inputvcf')
    parser.add_argument('output_pass_vcf')
    parser.add_argument('output_fail_vcf')

    args = parser.parse_args()
    go(args)


if __name__ == "__main__":
    main()

