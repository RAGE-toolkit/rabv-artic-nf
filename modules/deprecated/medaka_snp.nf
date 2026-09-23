//medaka-2.nf

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

process MEDAKA_2 {

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_hdf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${sampleId}.2.hdf", emit: hdf
	
	script:
	"""
	medaka consensus \
--model ${params.medaka_model} \
--threads ${params.threads} \
--chunk_len 800 \
--chunk_ovlp 400 \
--RG 2 ${currDir}/${params.output_dir}/medaka/${sampleId}.trimmed.rg.sorted.bam \
${currDir}/${params.output_dir}/medaka/${sampleId}.2.hdf
	"""
	}
