//compress_and_index_vcf.nf

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

process COMPRESS_AND_INDEX_VCF {

	errorStrategy 'ignore'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.pass.vcf.gz", emit: vcf_gz

	script:
	"""
	set -e
	(
		bgzip -kf ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.pass.vcf \
		&& tabix -f -p vcf ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.pass.vcf.gz ) || echo "compress-and-index-vcf" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
