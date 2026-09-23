//guppy_plex.nf

nextflow.enable.dsl=2

def currDir = System.getProperty("user.dir");

script_path = "${projectDir}/scripts/plex.py"
process PLEX_DIRS {
	//conda 'envs/biopython.yml'

	label 'plex_dirs'

	publishDir "${projectDir}/${params.fastq_dir}", mode: 'copy'

	input:
	val input_dir
	tuple val(sample_id), val(item), val(scheme), val(version)

	output:
	val "${params.fastq_dir}", emit: fastq

	script:

	"""
	python $script_path \
		--skip-quality-check \
		--min-length ${params.seq_len} \
		--max-length ${params.seq_max_len} \
		--directory ${input_dir}/${item} \
		--output "${projectDir}/${params.fastq_dir}/${sample_id}_${item}${params.fq_extension}"
	"""
}