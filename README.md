# Germline WGS/WES Variant Calling Pipeline
 
## Workflow
![Pipeline DAG](dag.svg)
 
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
 
## 2. Reference data
 
This pipeline needs a **GRCh38 reference** and **known-sites VCFs** for BQSR.
The recommended source is the **GATK Resource Bundle** (Broad public bucket) —
the reference and known-sites there all use `chr`-style naming (`chr1`, `chrM`)
and are mutually compatible, so no renaming is needed.
 
Bucket: `gs://gcp-public-data--broad-references/hg38/v0/`
([docs](https://gatk.broadinstitute.org/hc/en-us/articles/360035890811-Resource-bundle)).
The base URL is not browsable in a browser, but `wget` on a full file path works.
 
**Reference genome:**
```bash
BASE=https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0
wget $BASE/Homo_sapiens_assembly38.fasta \
     $BASE/Homo_sapiens_assembly38.fasta.fai \
     $BASE/Homo_sapiens_assembly38.dict
bwa index Homo_sapiens_assembly38.fasta          # build the BWA index
```
 
**Known-sites (for BQSR):**
```bash
BASE=https://storage.googleapis.com/gcp-public-data--broad-references/hg38/v0
wget $BASE/Homo_sapiens_assembly38.dbsnp138.vcf \
     $BASE/Homo_sapiens_assembly38.dbsnp138.vcf.idx \
     $BASE/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz \
     $BASE/Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi \
     $BASE/Homo_sapiens_assembly38.known_indels.vcf.gz \
     $BASE/Homo_sapiens_assembly38.known_indels.vcf.gz.tbi
```
 
**Exome targets (WES only)** — get the BED from your capture-kit vendor, then:
```bash
gatk BedToIntervalList -I targets.bed \
    -SD Homo_sapiens_assembly38.dict -O targets.interval_list
```
 
### ⚠️ Contig naming must match
 
The **reference, known-sites, and target BED must all use the same contig
naming**, or BQSR/calling will fail or silently produce nothing (e.g. GATK
can't match `chr1` in known-sites against `1` in your BAM).
 
| Source | Contig names |
|--------|--------------|
| UCSC / Broad bundle | `chr1`, `chr2`, `chrM` |
| Ensembl | `1`, `2`, `MT` |
| RefSeq | `NC_000001.11`, ... |
 
Using the Broad bundle above, everything already matches — nothing to do.
If you use a **different reference** (e.g. Ensembl), rename the known-sites to
match it first. Example (`chr` → Ensembl):
```bash
# mapping file: old <tab> new  (chr1  1 ... chrM  MT)
printf 'chr1\t1\nchr2\t2\nchrM\tMT\n' > chr_map.txt   # ... add all contigs
 
bcftools annotate --rename-chrs chr_map.txt \
    known_sites.vcf.gz -Oz -o known_sites.renamed.vcf.gz
tabix -p vcf known_sites.renamed.vcf.gz
```
Check your reference's naming with: `cut -f1 genome.fa.fai | head`
 
---
 
## 3. Prepare inputs
 
**a) Sample sheet** — edit `config/samples.tsv` (tab-separated). One row per sample;
the sample name must match your FASTQ file naming:
 
```
sample	Read1	Read2
patient1	/path/patient1_R1.fastq.gz	/path/patient1_R2.fastq.gz
patient2	/path/patient2_R1.fastq.gz	/path/patient2_R2.fastq.gz
```
 
**b) Config** — edit `config/config.yaml`:
 
| Setting | What to do |
|---------|-----------|
| `reference.fasta` / `bwa_index` | path to your genome |
| `mode` | `wes` or `wgs` |
| `capture.targets` / `bed` | your exome BED / interval_list (WES only) |
| `bqsr.known_sites` | paths to known-sites VCFs |
| `threads.*` | cores per tool — tune to your machine |
 
---
 
## 4. Run
 
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
 
## Output
 
Results are organized per sample under `results/<sample>/`:
 
```text
results/sample/
├── fastqc/                          # raw-read QC
│   ├── sample_R1_fastqc.html
│   └── sample_R2_fastqc.html
├── trimmed/                         # trimmed reads + post-trim QC
│   ├── sample_trimmed_R1.fastq.gz
│   ├── sample_trimmed_R2.fastq.gz
│   ├── sample.html                  # fastp report
│   └── fastqc/
│       └── sample_trimmed_R1_fastqc.html
├── align/                           # alignment, dedup, recalibration
│   ├── sample.sorted.bam
│   ├── sample.markdup.bam
│   ├── sample.dup_metrics.txt
│   └── sample.bqsr.bam              # analysis-ready BAM
├── coverage/                        # mosdepth coverage
│   └── sample.mosdepth.summary.txt
├── variants/
│   ├── sample.g.vcf.gz              # gVCF (HaplotypeCaller)
│   ├── sample.vcf.gz                # genotyped
│   └── sample.filtered.vcf.gz       # ← final filtered VCF
└── multiqc/
    └── sample_multiqc_report.html   # per-sample QC summary
```
 
Alongside `results/`, the pipeline also writes:
- `logs/<sample>/`      — per-rule logs
- `benchmarks/<sample>/` — per-rule runtime & memory
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
 
