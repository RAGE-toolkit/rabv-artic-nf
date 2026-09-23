//vcf_merge.nf

nextflow.enable.dsl=2

//def currDir = System.getProperty("user.dir")
def currDir = workflow.projectDir

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

vcf_merge = "${currDir}/scripts/vcf_merge.py"

process VCF_MERGE {

	errorStrategy 'ignore'

	//conda 'envs/pyvcf.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.merged.vcf.gz.tbi", emit: vcf
	
	script:
	"""
	set -e
	(
		/opt/miniforge/envs/clair3env/bin/python3 "${vcf_merge}" "${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}" \
		"${params.primer_schema}/${scheme}/${version}/${scheme}.scheme.bed" \
		"2:${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.2.vcf" \
		"1:${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.1.vcf" \
		"unmatched:${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.unmatched.vcf" \
		2> "${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.primersitereport.txt" && \
		bgzip -f "${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.merged.vcf" && \
		tabix -f -p vcf "${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.merged.vcf.gz" ) || echo "vcf_merge" "${sampleId}" >> ${currDir}/${params.output_dir}/medaka/failed_samples.txt
	"""
	}

