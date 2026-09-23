//make_depth_mask.nf

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

make_depth_mask = "${currDir}/scripts/make_depth_mask.py"

process MAKE_DEPTH_MASK {

	errorStrategy 'ignore'
	//conda 'envs/pyvcf.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.coverage_mask.txt", emit: coverage_mask
	
	script:
	"""
	set -e
	(
		python ${make_depth_mask} \
		--depth ${params.mask_depth} \
		${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.coverage_mask.txt ) || echo "make-depth-mask" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
