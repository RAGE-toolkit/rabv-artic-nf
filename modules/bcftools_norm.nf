//bcftools_norm.nf

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

process BCFTOOLS_NORM {

	errorStrategy 'ignore'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.normalised.vcf.gz", emit: normalised_vcf

	script:
	"""
	set -e
	(
		bcftools norm --check-ref x \
		--fasta-ref ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.preconsensus.fasta \
		-O z -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.normalised.vcf.gz \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.pass.vcf.gz \
		&& tabix -f -p vcf ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.normalised.vcf.gz ) || echo "bcftools-norm" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
