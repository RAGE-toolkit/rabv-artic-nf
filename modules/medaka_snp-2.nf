//medaka_SNP-2.nf

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

def osName = System.getProperty("os.name").toLowerCase()

process MEDAKA_SNP_2 {

	errorStrategy 'ignore'

	if (osName.contains("linux")) {
		//conda 'envs/medaka.yml'
	}

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.2.vcf", emit: vcf
	
	script:
	"""
	set -e
	(
		medaka snp ${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.hdf \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.vcf && \
		medaka tools annotate --pad 25 --RG 2 \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.vcf \
		${params.primer_schema}/${scheme}/${version}/${scheme}.reference.fasta \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.trimmed.rg.sorted.bam \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.annotate.tmp.vcf && \
		mv ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.annotate.tmp.vcf \
		${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.vcf ) || echo "medaka-snp-2" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}
