//clair-2.nf

nextflow.enable.dsl=2

def currDir = System.getProperty("user.dir")

//checking if medaka dir exists
def medaka_dir = new File("${currDir}/${params.output_dir}/medaka")
if (!medaka_dir.exists()) {
        medaka_dir.mkdirs()
}

meta_file = "$currDir/${params.meta_file}";

def hash = [:].withDefault { [] }

new File(meta_file).eachLine { line ->
    def (key, values) = line.split(',', 2)
    hash[key] << values
}

process CLAIR3_2 {

	errorStrategy 'ignore'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_bam
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.2.vcf", emit: vcf

	script:
	"""
	set -e
  (
	run_clair3.sh --enable_long_indel --chunk_size=10000 --haploid_sensitive --no_phasing_for_fa --bam_fn=${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.primertrimmed.rg.sorted.bam --ref_fn=${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta --output=/tmp/artic_clair3_2 --threads="${params.threads}" --platform=ont --model_path="${params.model_path}" --include_all_ctgs --enable_variant_calling_at_sequence_head_and_tail \
	&& bgzip -dc /tmp/artic_clair3_2/merge_output.vcf.gz > ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.vcf \
	&& rm -rf /tmp/artic_clair3_2 \
	&& rm ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.primertrimmed.rg.sorted.bam ) || echo "clair3-2" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
