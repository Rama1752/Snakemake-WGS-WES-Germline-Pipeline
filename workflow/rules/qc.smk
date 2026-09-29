rule raw_qc:
    input:
        r1 = lambda wc: SAMPLE_R1[wc.sample],
        r2 = lambda wc: SAMPLE_R2[wc.sample],
    output:
        h1 = "results/{sample}/fastqc/{sample}_R1_fastqc.html",
        h2 = "results/{sample}/fastqc/{sample}_R2_fastqc.html",
        z1 = "results/{sample}/fastqc/{sample}_R1_fastqc.zip",
        z2 = "results/{sample}/fastqc/{sample}_R2_fastqc.zip",
    threads: config["threads"]["fastqc"]
    params: outdir = "results/{sample}/fastqc"
    benchmark: "benchmarks/{sample}/raw_qc.tsv"
    log: "logs/{sample}/raw_qc.log"
    conda: "../envs/qc.yaml"
    shell:
        "fastqc -t {threads} --dir {TMPDIR} {input.r1} {input.r2} "
        "-o {params.outdir} > {log} 2>&1"

rule trimmed_qc:
    input:
        r1 = "results/{sample}/trimmed/{sample}_trimmed_R1.fastq.gz",
        r2 = "results/{sample}/trimmed/{sample}_trimmed_R2.fastq.gz",
    output:
        h1 = "results/{sample}/trimmed/fastqc/{sample}_trimmed_R1_fastqc.html",
        h2 = "results/{sample}/trimmed/fastqc/{sample}_trimmed_R2_fastqc.html",
        z1 = "results/{sample}/trimmed/fastqc/{sample}_trimmed_R1_fastqc.zip",
        z2 = "results/{sample}/trimmed/fastqc/{sample}_trimmed_R2_fastqc.zip",
    threads: config["threads"]["fastqc"]
    params: outdir = "results/{sample}/trimmed/fastqc"
    benchmark: "benchmarks/{sample}/trimmed_qc.tsv"
    log: "logs/{sample}/trimmed_qc.log"
    conda: "../envs/qc.yaml"
    shell:
        "fastqc -t {threads} --dir {TMPDIR} {input.r1} {input.r2} "
        "-o {params.outdir} > {log} 2>&1"
