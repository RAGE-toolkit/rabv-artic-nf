//muscle.nf

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

process MUSCLE {

	maxForks 1

	errorStrategy 'ignore'

	//conda 'envs/muscle.yml'

	publishDir "${currDir}/${params.output_dir}", mode: 'copy'

	input:
	val input_vcf
	tuple val(sampleId), val(item), val(scheme), val(version)

	output:
	val "medaka/${params.run_name}_${sampleId}.muscle.out.fasta", emit: muscle_op_fasta
	
	script:
	"""
	# Check muscle version
	version=\$(muscle -version 2>&1 | head -n 1)

	if echo "\$version" | grep -q "3.8"; then
		echo "Using MUSCLE v3 syntax"
		muscle -in ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.muscle.in.fasta \
		 -out ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.muscle.out.fasta
	else
		echo "Using MUSCLE v5 syntax"
		muscle -align ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.muscle.in.fasta \
		-output ${currDir}/${params.output_dir}/medaka/${params.run_name}_${sampleId}.muscle.out.fasta
  fi
	"""
	}
