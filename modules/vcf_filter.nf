//vcf_filter.nf

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

vcf_filter = "${currDir}/scripts/vcf_filter.py"

process VCF_FILTER {

	errorStrategy 'ignore'

	//conda 'envs/tabix.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.pass.vcf", emit: pass_vcf
	val "medaka/${params.run_name}_${sampleId}.fail.vcf", emit: fail_vcf
	
	script:
	"""
	set -e
	(
		python ${vcf_filter} --min-depth ${params.mask_depth} --min-variant-quality ${params.min_variant_quality} --min-allele-frequency ${params.min_allele_frequency} --min-mask-allele-frequency ${params.min_mask_allele_frequency} --min-frameshift-quality ${params.min_frameshift_quality} --min-minor-allele-count ${params.min_minor_allele_count} \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.merged.vcf.gz \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.pass.vcf \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.fail.vcf \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.ignore.vcf ) || echo "vcf_filter" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
