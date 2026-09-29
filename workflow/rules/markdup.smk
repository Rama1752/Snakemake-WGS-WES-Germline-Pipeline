rule markdup:
    input:
        bam = "results/{sample}/align/{sample}.sorted.bam",
    output:
        bam = "results/{sample}/align/{sample}.markdup.bam",
        bai = "results/{sample}/align/{sample}.markdup.bam.bai",
        metrics = "results/{sample}/align/{sample}.dup_metrics.txt",
    threads: config["threads"]["markdup"]
    benchmark: "benchmarks/{sample}/markdup.tsv"
    log: "logs/{sample}/markdup.log"
    conda: "../envs/gatk.yaml"
    shell:
        'gatk --java-options "{JAVA_OPTS}" MarkDuplicates '
        "--TMP_DIR {TMPDIR} -I {input.bam} -O {output.bam} -M {output.metrics} > {log} 2>&1 && "
        "samtools index {output.bam}"
