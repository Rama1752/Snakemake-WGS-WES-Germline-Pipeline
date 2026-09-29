# Per-sample MultiQC report, written inside each sample's own folder.
rule multiqc:
    input:
        "results/{sample}/fastqc/{sample}_R1_fastqc.zip",
        "results/{sample}/trimmed/fastqc/{sample}_trimmed_R1_fastqc.zip",
        "results/{sample}/trimmed/{sample}.json",
        "results/{sample}/align/{sample}.dup_metrics.txt",
        "results/{sample}/coverage/{sample}.mosdepth.summary.txt",
    output:
        html = "results/{sample}/multiqc/{sample}_multiqc_report.html",
    params:
        indir  = "results/{sample}",
        outdir = "results/{sample}/multiqc",
    benchmark: "benchmarks/{sample}/multiqc.tsv"
    log: "logs/{sample}/multiqc.log"
    conda: "../envs/multiqc.yaml"
    shell:
        "multiqc {params.indir} -o {params.outdir} "
        "-n {wildcards.sample}_multiqc_report --force > {log} 2>&1"