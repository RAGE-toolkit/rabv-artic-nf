//main.nf

def currDir = System.getProperty("user.dir");

//checking if output dir exists
def res_dir = new File("${currDir}/${params.output_dir}")
if (!res_dir.exists()) {
        res_dir.mkdirs()
	}

//checking raw_file dir exists
def raw_dir = new File("${currDir}/raw_files")
if (!raw_dir.exists()) {
  raw_dir.mkdir()
	}

//checking if fastq dir exists
def fq_dir = new File("${currDir}/${params.fastq_dir}")
if (!fq_dir.exists()) {
  fq_dir.mkdir()
	}

//__________________________________________________________________________________________
// load modules
include { GUPPY_BASECALLER	} from './modules/guppy_basecaller.nf'
include { GUPPY_BARCODER	} from './modules/guppy_barcode.nf'
include { GUPPY_PLEX	} from './modules/guppy_plex.nf'
include { DORADO_BASECALLER	} from './modules/dorado_basecaller.nf'
include { DORADO_BARCODER	} from './modules/dorado_barcoder.nf'
include { PLEX_FQ_FILES	} from './modules/plex_fq_files.nf'
include { PLEX_DIRS	} from './modules/plex_dirs.nf'
include { MINIMAP2	} from './modules/minimap2.nf'
include { ALIGN_TRIM	} from './modules/align_trim.nf'
include { SPLIT_UNMATCHED	} from './modules/split_unmatched.nf'
include { CLAIR3	} from './modules/clair-1.nf'
include { CLAIR3_2	} from './modules/clair-2.nf'
include { CLAIR3_UNMATCHED	} from './modules/clair_unmatched.nf'
include	{ VCF_MERGE	} from './modules/vcf_merge.nf'
include	{ VCF_FILTER	} from './modules/vcf_filter.nf'
include { COMPRESS_AND_INDEX_VCF	} from './modules/compress_and_index_vcf.nf'
include { MAKE_DEPTH_MASK	} from './modules/make_depth_mask.nf'
include { MASK	} from './modules/mask.nf'
include { BCFTOOLS_NORM	} from './modules/bcftools_norm.nf'
include	{ BCFTOOLS_CONSENSUS	} from './modules/bcftools_consensus.nf'
include { FASTA_HEADER	} from './modules/fasta_header.nf'
include { CONCAT	} from './modules/concat.nf'
include { MAFFT	} from './modules/mafft.nf'
include	{ SUMMARY_STATS } from './modules/summary_stats.nf'
include { REPORT } from './modules/report.nf'

//__________________________________________________________________________________________
// load meta data
meta_file = "$currDir/${params.meta_file}";
extension = ".fastq"

fq_channel = channel
        .fromPath(meta_file)
        .splitCsv(header: true, sep: ",")
  .map { row -> tuple(row.sampleId, row.barcode, row.schema, row.version) }

//__________________________________________________________________________________________
println(" ");
println("Output file		:" + "${currDir}/${params.output_dir}");
println("Meta file		:" + meta_file);
println("Basecaller		:" + "${params.basecaller}");
println("Rawfile directory	:" + "${params.rawfile_dir}");
println("Rawfile type		:" + "${params.rawfile_type}");
println("Output base dir		:" + "${params.output_dir}");

def default_dorado_path = "${params.dorado_dir}/bin/dorado"
def default_dorado_model_dir = "${params.dorado_dir}/model"

def default_guppy_basecaller_path = "${params.guppy_dir}/bin/guppy_basecaller"
def default_guppy_barcoder_path = "${params.guppy_dir}/bin/guppy_barcoder"
def default_guppy_model_path = "${params.guppy_dir}/data/"

def isDoradoAvailable() {
	def process = 'which dorado'.execute()
	process.waitFor()
	return process.exitValue() == 0
	}

def isGuppyAvailable() {
	def process = 'which guppy'.execute()
	process.waitFor()
	return process.exitValue() == 0
	}

def isDoradoModelAvailable() {
	def process = ['/bin/bash', '-c', 'source ~/.bashrc && echo $DORADO_MODEL'].execute()
	process.waitFor()
	def output = process.text.trim()
	return output ? output : null
	}

def isGuppyBasecallerAvailable() {
  def process = ['/bin/bash', '-c', 'source ~/.bashrc && echo $GUPPY_BASECALLER'].execute()
  process.waitFor()
  def output = process.text.trim()
  return output ? output : null
	}

def isGuppyBarcoderAvailable() {
  def process = ['/bin/bash', '-c', 'source ~/.bashrc && echo $GUPPY_BARCODER'].execute()
  process.waitFor()
  def output = process.text.trim()
  return output ? output : null
	}

def isGuppyModelAvailable() {
  def process = ['/bin/bash', '-c', 'source ~/.bashrc && echo $GUPPY_MODEL'].execute()
  process.waitFor()
  def output = process.text.trim()
  return output ? output : null
	}

def dorado_executable = isDoradoAvailable() ? 'dorado' : default_dorado_path
def dorado_model_dir = isDoradoModelAvailable() ?: default_dorado_model_dir

def guppy_basecaller_executable = isGuppyBasecallerAvailable() ?: default_guppy_basecaller_path
def guppy_barcoder_executable = isGuppyBarcoderAvailable() ?: default_guppy_barcoder_path
def guppy_model_dir = isGuppyModelAvailable() ?: default_guppy_model_path

if ("${params.basecaller}" == "Guppy") {
  println("Basecaller path		:" + "${guppy_basecaller_executable}");
	println("Model path		:" + "${guppy_model_dir}/${params.guppy_config}");
	}
else {
  println("Basecaller path		:" +  "${dorado_executable}");
	println("Model path		:" + "${dorado_model_dir}/${params.dorado_config}");
	}

rawfile_dir = "${params.rawfile_dir}"

// make the workflow check for basecaller, exit otherwise
//__________________________________________________________________________________________
// shared steps from demultiplexed fastq to consensus, alignment and report
workflow CONSENSUS {
	take:
	fastq_dir
	samples

	main:
	MINIMAP2(input_dir=fastq_dir.collect(), samples)
	ALIGN_TRIM(input_bam=MINIMAP2.out.sorted_bam.collect(), samples)
	SPLIT_UNMATCHED(input_bam=ALIGN_TRIM.out.trimmed_bam.collect(), samples)
	CLAIR3(input_bam=ALIGN_TRIM.out.trimmed_bam.collect(), samples)
	CLAIR3_2(input_bam=ALIGN_TRIM.out.trimmed_bam.collect(), samples)
	CLAIR3_UNMATCHED(input_bam=SPLIT_UNMATCHED.out.unmatched_bam.collect(), samples)
	VCF_MERGE(input_vcf=CLAIR3.out.vcf.mix(CLAIR3_2.out.vcf, CLAIR3_UNMATCHED.out.vcf).collect(), samples)
	VCF_FILTER(input_vcf=VCF_MERGE.out.vcf.collect(), samples)
	COMPRESS_AND_INDEX_VCF(input_vcf=VCF_FILTER.out.pass_vcf.collect(), samples)
	MAKE_DEPTH_MASK(input_vcf=VCF_FILTER.out.pass_vcf.collect(), samples)
	MASK(input_vcf=MAKE_DEPTH_MASK.out.coverage_mask.collect(), samples)
	BCFTOOLS_NORM(input_vcf=MASK.out.preconsensus.mix(COMPRESS_AND_INDEX_VCF.out.vcf_gz).collect(), samples)
	BCFTOOLS_CONSENSUS(input_vcf=BCFTOOLS_NORM.out.normalised_vcf.collect(), samples)
	FASTA_HEADER(input_vcf=BCFTOOLS_CONSENSUS.out.consensus_fa.collect(), samples)
	CONCAT(input_fasta=FASTA_HEADER.out.fasta.collect())
	MAFFT(concat_fa=CONCAT.out.genome_fa.collect())
	SUMMARY_STATS(item=MAFFT.out.mafft_fa.collect())
	REPORT(summary_file=SUMMARY_STATS.out.summary)
}

workflow
{
	// only the route to demultiplexed fastq differs between input types
	if (params.rawfile_type == "fastq") {
		PLEX_DIRS(input_dir=rawfile_dir, fq_channel)
		fastq_dir = PLEX_DIRS.out
	}
	else if (params.basecaller == "Dorado") {
		DORADO_BASECALLER(fast5_or_pod5_dir="${params.rawfile_dir}")
		DORADO_BARCODER(fastq_file=DORADO_BASECALLER.out)
		PLEX_FQ_FILES(DORADO_BARCODER.out, fq_channel)
		fastq_dir = PLEX_FQ_FILES.out
	}
	else {
		GUPPY_BASECALLER(fast5_or_pod5_dir="${params.rawfile_dir}")
		GUPPY_BARCODER(fastq_file=GUPPY_BASECALLER.out)
		PLEX_DIRS(input_dir=GUPPY_BARCODER.out, fq_channel)
		fastq_dir = PLEX_DIRS.out
	}

	CONSENSUS(fastq_dir, fq_channel)
}
