//longshot.nf

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

align_trim = "${currDir}/scripts/align_trim.py"

process LONGSHOT {

	errorStrategy 'ignore'

	//conda 'envs/longshot.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.merged.longshot.vcf", emit: vcf

	script:
	"""
	set -e
	(
		longshot -P 0 \
		-F \
		-A \
		--no_haps \
		--bam ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam \
		--ref ${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta \
		--out ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.merged.longshot.vcf \
		--potential_variants ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.merged.vcf.gz ) || echo "longshot" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
