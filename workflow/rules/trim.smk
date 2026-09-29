rule trim:
    input:
        r1 = lambda wc: SAMPLE_R1[wc.sample],
        r2 = lambda wc: SAMPLE_R2[wc.sample],
    output:
        r1   = "results/{sample}/trimmed/{sample}_trimmed_R1.fastq.gz",
        r2   = "results/{sample}/trimmed/{sample}_trimmed_R2.fastq.gz",
        html = "results/{sample}/trimmed/{sample}.html",
        json = "results/{sample}/trimmed/{sample}.json",
    threads: config["threads"]["fastp"]
    benchmark: "benchmarks/{sample}/trim.tsv"
    log: "logs/{sample}/trim.log"
    conda: "../envs/trim.yaml"
    shell:
        "fastp -i {input.r1} -I {input.r2} -o {output.r1} -O {output.r2} "
        "--detect_adapter_for_pe --trim_poly_g --thread {threads} "
        "-h {output.html} -j {output.json} > {log} 2>&1"
