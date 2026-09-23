## rabv-artic-nf v2.0.0

Updated to follow the **fieldbioinformatics v1.11.2** workflow, with **Clair3** replacing medaka/longshot for variant calling.

### Highlights
- **Clair3 variant calling** per primer pool, plus calling on unmatched reads, then merged, filtered, normalised and turned into a consensus as in fieldbioinformatics v1.11.2
- **Validated**: the S4-D0 consensus is identical, base for base, to fieldbioinformatics output
- **Multi-architecture Docker images**: `rage2025/artic-nf-amd64:v2.0` (Linux x86_64) and `rage2025/artic-nf-arm64:v2.0` (Apple Silicon), chosen automatically from the host architecture

### New configurable parameters
| Parameter | Default | Purpose |
|---|---|---|
| `normalise` | 100 | Reads kept per amplicon |
| `primer_match_threshold` | 35 | Max distance (bp) between a read end and its primer site |
| `min_mapq` | 20 | Minimum mapping quality |
| `min_variant_quality` | 10 | Clair3 QUAL cutoff |
| `min_allele_frequency` | 0.6 | AF needed to enter the consensus |
| `min_mask_allele_frequency` | 0.1 | Below this AF, variant discarded |
| `min_frameshift_quality` | 50 | QUAL needed for frameshifting indels |
| `min_minor_allele_count` | 4 | Minimum alt-supporting reads |

`mask_depth` now also sets the VCF filter's minimum depth.

### Fixes
- Dorado and Guppy basecalling routes referenced undefined processes (`ALIGN_TRIM_1`, `MUSCLE`), and both now work
- Corrected reference names in `rabvSEasia` V1 `scheme.bed`

### Changes
- `main.nf` refactored: the shared analysis steps now live in one `CONSENSUS` sub-workflow
- medaka, longshot and MUSCLE modules moved to `modules/deprecated/`

### Known issues
- Consensus FASTA headers keep the reference name, because `artic_fasta_header.py` needs the `artic` package, which isn't installed in the image
- The `conda` profile has not been updated for the Clair3 modules. Use `-profile docker`.

