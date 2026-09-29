# mosdepth: target-restricted in WES, genome-wide in WGS
if WES and TARGETS_BED:
    rule mosdepth:
        input:
            bam = final_bam,
        output:
            summary = "results/{sample}/coverage/{sample}.mosdepth.summary.txt",
        threads: config["threads"]["mosdepth"]
        params:
            prefix = "results/{sample}/coverage/{sample}",
            bed = TARGETS_BED,
        benchmark: "benchmarks/{sample}/mosdepth.tsv"
        log: "logs/{sample}/mosdepth.log"
        conda: "../envs/qc.yaml"
        shell:
            "mosdepth -t {threads} --by {params.bed} --thresholds 1,10,20,30 "
            "--no-per-base {params.prefix} {input.bam} > {log} 2>&1"
else:
    rule mosdepth:
        input:
            bam = final_bam,
        output:
            summary = "results/{sample}/coverage/{sample}.mosdepth.summary.txt",
        threads: config["threads"]["mosdepth"]
        params:
            prefix = "results/{sample}/coverage/{sample}",
        benchmark: "benchmarks/{sample}/mosdepth.tsv"
        log: "logs/{sample}/mosdepth.log"
        conda: "../envs/qc.yaml"
        shell:
            "mosdepth -t {threads} --no-per-base {params.prefix} {input.bam} > {log} 2>&1"
