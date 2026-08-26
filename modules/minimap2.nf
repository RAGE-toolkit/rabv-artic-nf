//medaka.nf

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

process MINIMAP2 {

	//conda 'envs/minimap2.yml' 

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_dir
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}", emit: consensus
	val "medaka/${params.run_name}_${sampleId}.sorted.bam", emit: sorted_bam

	script:
	"""
	minimap2 -a -x map-ont -t ${params.threads} \
	${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta \
	${currDir}/raw_files/fastq/${sampleId}_${item}.fastq |\
	samtools view -bS -F 4 - |\
	samtools sort -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.sorted.bam &&\
	samtools index ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.sorted.bam
	"""
	}

