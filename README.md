# Germline WGS/WES Variant Calling Pipeline

Reproducible Snakemake pipeline: FASTQ → QC → alignment → variant calling → filtered VCF.
Supports whole-genome (WGS) and whole-exome (WES) via a single config switch.

## Workflow
FastQC → fastp → BWA-MEM → MarkDuplicates → BQSR → HaplotypeCaller →
GenotypeGVCFs → hard-filter → filtered VCF, with mosdepth coverage and a
per-sample MultiQC report.

## Requirements
- Snakemake 9.27.0
- conda / mamba
- GRCh38 reference with `.fai` + `.dict`, BWA index, and known-sites VCFs for BQSR

## Tools (pinned in workflow/envs/)
FastQC 0.12.1 · seqkit 2.8.2 · mosdepth 0.3.8 · fastp 0.23.4 · BWA 0.7.18 ·
samtools 1.20 · GATK 4.6.1.0 · bcftools 1.20 · MultiQC 1.25

## Setup
    conda env create -f environment.yaml
    conda activate snakemake_env
    cp config/samples.example.tsv config/samples.tsv   # then edit
    # edit config/config.yaml: reference paths, mode (wes|wgs), targets, known-sites

## Usage
    # dry run
    snakemake -s workflow/Snakefile --use-conda --cores 32 -n

    # real run
    snakemake -s workflow/Snakefile --use-conda --cores 32 \
        --resources mem_mb=200000 --rerun-triggers mtime --keep-going -p

Always pass `--use-conda` (reproducibility) and `--rerun-triggers mtime`
(avoids full re-runs after edits).

## Configuration (config/config.yaml)
| Key | Purpose |
|-----|---------|
| `mode` | `wes` (targets + padding) or `wgs` (genome-wide) |
| `bqsr.run` | toggle base recalibration |
| `filters.run` | toggle hard filtering |
| `threads.<tool>` | per-tool thread counts |
| `mem_mb.<tool>` | memory caps for heavy rules |

## Output
    results/<sample>/
    ├── fastqc/       raw read QC
    ├── trimmed/      trimmed reads + QC
    ├── align/        sorted, dedup, recalibrated BAM
    ├── coverage/     mosdepth summary
    ├── variants/     <sample>.filtered.vcf.gz  (final)
    └── multiqc/      per-sample MultiQC report

## License
MIT
