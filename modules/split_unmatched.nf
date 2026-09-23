//split_unmatched.nf

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

process SPLIT_UNMATCHED {

	errorStrategy 'ignore'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_bam
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.unmatched.primertrimmed.rg.sorted.bam", emit: unmatched_bam

	script:
	"""
	set -e
  (
	samtools view -b -r unmatched ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.unmatched.primertrimmed.rg.sorted.bam \
	&& samtools index ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.unmatched.primertrimmed.rg.sorted.bam ) || echo "split-unmatched" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
