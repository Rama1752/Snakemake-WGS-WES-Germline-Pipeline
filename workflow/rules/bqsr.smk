if RUN_BQSR:
    rule base_recalibrator:
        input:
            bam = "results/{sample}/align/{sample}.markdup.bam",
        output:
            table = "results/{sample}/align/{sample}.recal.table",
        threads: config["threads"]["bqsr"]
        benchmark: "benchmarks/{sample}/bqsr_table.tsv"
        log: "logs/{sample}/bqsr_table.log"
        conda: "../envs/gatk.yaml"
        shell:
            'gatk --java-options "{JAVA_OPTS}" BaseRecalibrator '
            "--tmp-dir {TMPDIR} -R {REF} -I {input.bam} {INTERVAL_ARG} {KNOWN_ARG} "
            "-O {output.table} > {log} 2>&1"

    rule apply_bqsr:
        input:
            bam   = "results/{sample}/align/{sample}.markdup.bam",
            table = "results/{sample}/align/{sample}.recal.table",
        output:
            bam = "results/{sample}/align/{sample}.bqsr.bam",
            bai = "results/{sample}/align/{sample}.bqsr.bam.bai",
        threads: config["threads"]["bqsr"]
        benchmark: "benchmarks/{sample}/bqsr_apply.tsv"
        log: "logs/{sample}/bqsr_apply.log"
        conda: "../envs/gatk.yaml"
        shell:
            'gatk --java-options "{JAVA_OPTS}" ApplyBQSR '
            "--tmp-dir {TMPDIR} -R {REF} -I {input.bam} {INTERVAL_ARG} "
            "--bqsr-recal-file {input.table} -O {output.bam} > {log} 2>&1 && "
            "samtools index {output.bam}"
