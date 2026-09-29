# BWA-MEM alignment + coordinate sort + index (germline WGS/WES).
rule align_bwa:
    input:
        r1 = "results/{sample}/trimmed/{sample}_trimmed_R1.fastq.gz",
        r2 = "results/{sample}/trimmed/{sample}_trimmed_R2.fastq.gz",
    output:
        bam = "results/{sample}/align/{sample}.sorted.bam",
        bai = "results/{sample}/align/{sample}.sorted.bam.bai",
    threads: config["threads"]["bwa"]
    resources:
        mem_mb = config["mem_mb"]["bwa"],
    params:
        idx = config["reference"]["bwa_index"],
        rg  = r'@RG\tID:{sample}\tSM:{sample}\tLB:lib1\tPL:ILLUMINA\tPU:unit1',
        sort_threads = config["threads"]["sort"],
    benchmark: "benchmarks/{sample}/align_bwa.tsv"
    log: "logs/{sample}/align.log"
    conda: "../envs/align.yaml"
    shell:
        "bwa mem -t {threads} -R '{params.rg}' {params.idx} {input.r1} {input.r2} 2> {log} "
        "| samtools sort -@ {params.sort_threads} -m 2G -T {TMPDIR}/{wildcards.sample}_sort "
        "-o {output.bam} - && samtools index {output.bam}"
