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

process ALIGN_TRIM {

	errorStrategy 'ignore'

	//conda 'envs/pyvcf.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_bam
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.alignreport.txt", emit: align_report
  val "medaka/${params.run_name}_${sampleId}.trimmed.rg.sorted.bam", emit: trimmed_bam

	script:
	"""
	set -e
  (
	align_trim --normalise ${params.normalise} ${params.primer_schema}/${scheme}/${version}/${scheme}.scheme.bed --primer-match-threshold ${params.primer_match_threshold} --min-mapq ${params.min_mapq} --allow-incorrect-pairs --report ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.alignreport.tsv --amp-depth-report ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.amplicon_depths.tsv --genome-coverage-report ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId} --samfile ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.sorted.bam -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.bam \
	&& samtools sort -T ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId} ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.bam -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam \
	&& rm ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.bam \
	&& samtools index ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam \
	&& samtools view -b -r 1 ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.1.primertrimmed.rg.sorted.bam \
	&& samtools index ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.1.primertrimmed.rg.sorted.bam \
	&& samtools view -b -r 2 ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primertrimmed.rg.sorted.bam -o ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.primertrimmed.rg.sorted.bam \
	&& samtools index ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.primertrimmed.rg.sorted.bam ) || echo "align-trim-1" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
