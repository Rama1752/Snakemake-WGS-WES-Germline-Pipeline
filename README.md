# Germline WGS/WES Variant Calling Pipeline

## Workflow
<img src="dag.svg" alt="Pipeline DAG" width="400">
 
A reproducible [Snakemake](https://snakemake.github.io/) pipeline that takes raw
paired-end reads to a filtered VCF. Works for both whole-genome (**WGS**) and
whole-exome (**WES**) data — you switch between them with a single line in the config.
 
```
FASTQ → FastQC → fastp → BWA-MEM → MarkDuplicates → BQSR
      → HaplotypeCaller → GenotypeGVCFs → hard-filter → filtered VCF
```
 
Plus mosdepth coverage and a per-sample MultiQC report.
 
---
 
## 1. Install
 
You need **conda** (or mamba). Everything else is installed for you.
 
```bash
# clone the repo
git clone https://github.com/Rama1752/wgs-wes-germline-pipeline.git
cd wgs-wes-germline-pipeline
 
# create the environment that runs Snakemake itself
conda env create -f environment.yaml
conda activate snakemake_env
```
 
The per-tool software (BWA, GATK, fastp, etc.) is **not** installed now — Snakemake
builds those automatically the first time you run with `--use-conda`.
 
---
 
## 2. Prepare inputs
 
**a) Reference genome** (GRCh38) — must be pre-indexed:
 
```bash
bwa index genome.fa
samtools faidx genome.fa
gatk CreateSequenceDictionary -R genome.fa
```
 
You also need the BQSR known-sites VCFs (dbSNP, Mills, known-indels).
 
**b) Sample sheet** — edit `config/samples.tsv` (tab-separated). One row per sample;
the sample name must match your FASTQ file naming:
 
```
sample	Read1	Read2
patient1	/path/patient1_R1.fastq.gz	/path/patient1_R2.fastq.gz
patient2	/path/patient2_R1.fastq.gz	/path/patient2_R2.fastq.gz
```
 
**c) Config** — edit `config/config.yaml`:
 
| Setting | What to do |
|---------|-----------|
| `reference.fasta` / `bwa_index` | path to your genome |
| `mode` | `wes` or `wgs` |
| `capture.targets` / `bed` | your exome BED / interval_list (WES only) |
| `bqsr.known_sites` | paths to known-sites VCFs |
| `threads.*` | cores per tool — tune to your machine |
 
---
 
## 3. Run
 
```bash
# dry run first — shows what will happen without running it
snakemake --use-conda --cores 32 -n
 
# real run
snakemake --use-conda --cores 32 --rerun-triggers mtime --keep-going -p
```
 
That's it. The first run is slower because Snakemake builds the tool
environments once; later runs reuse them.
 
**Flag cheat-sheet:**
 
| Flag | Why |
|------|-----|
| `--use-conda` | use the pinned tool versions (reproducibility) — always include |
| `--cores N` | how many cores Snakemake may use |
| `-n` | dry run (preview only) |
| `--rerun-triggers mtime` | don't re-run everything after editing a rule |
| `--keep-going` | one failed sample doesn't stop the rest |
| `-p` | print the shell commands as they run |
 
---
 
## 4. Output
 
Everything lands under `results/<sample>/`:
 
```
results/patient1/
├── fastqc/       raw-read QC
├── trimmed/      trimmed reads + QC
├── align/        sorted, deduplicated, recalibrated BAM
├── coverage/     mosdepth coverage summary
├── variants/     patient1.filtered.vcf.gz   ← final result
└── multiqc/      per-sample MultiQC report
```
 
---
 
## Switching WGS ↔ WES
 
Just change one line in `config/config.yaml`:
 
```yaml
mode: "wes"   # exome: restricts calling to capture targets (+padding), on-target coverage
mode: "wgs"   # genome: no restriction, genome-wide coverage
```
 
Everything else stays the same.
 
---
 
## Tools
 
All versions pinned in `workflow/envs/` for reproducibility:
 
| Step | Tool |
|------|------|
| Read QC | FastQC 0.12.1, seqkit 2.8.2 |
| Trimming | fastp 0.23.4 |
| Alignment | BWA 0.7.18, samtools 1.20 |
| Dedup / BQSR / calling / filtering | GATK 4.6.1.0 |
| VCF handling | bcftools 1.20 |
| Coverage | mosdepth 0.3.8 |
| Report | MultiQC 1.25 |
 
Orchestration: Snakemake 9.27.0
 
---
 
## License
 
MIT — see [LICENSE](LICENSE).
