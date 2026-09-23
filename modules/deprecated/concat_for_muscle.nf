//concat_for_muscle.nf

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

fasta_header = "${currDir}/scripts/fasta_header.py"

process CONCAT_FOR_MUSCLE {

	errorStrategy 'ignore'

	//conda 'envs/pyvcf.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.muscle.in.fasta", emit: muscle_fa
	
	script:
	"""
	set -e
	(
		cat ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.consensus.fasta ${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta \
	> ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.muscle.in.fasta ) || echo "concat-for_muscle" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
