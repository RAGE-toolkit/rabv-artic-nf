//aling_trim-2.nf

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

process ALIGN_TRIM_2 {

	//errorStrategy 'ignore'

	//conda 'envs/pyvcf.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_bam
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.alignreport.txt", emit: align_report
  val "medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam", emit: primertrimmed_bam

	script:
	"""
	#set -e
  #	(
		python ${align_trim} \
		--normalise 200 \
		${params.primer_schema}/${scheme}/${version}/${scheme}.scheme.bed \
		--report ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.alignreport.txt \
		< ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.sorted.bam \
		2> ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.alignreport.er \
		| samtools sort -T ${params.output_dir}/medaka/${params.run_name}_${sampleId} \
		-o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam \
		&& samtools index ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam 
		#) || echo "align-trim-2" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
