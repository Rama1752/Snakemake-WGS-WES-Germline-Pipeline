rule haplotype_caller:
    input:
        bam = final_bam,
    output:
        gvcf = "results/{sample}/variants/{sample}.g.vcf.gz",
    threads: config["threads"]["haplotypecaller"]
    benchmark: "benchmarks/{sample}/haplotypecaller.tsv"
    log: "logs/{sample}/haplotypecaller.log"
    conda: "../envs/gatk.yaml"
    shell:
        'gatk --java-options "{JAVA_OPTS}" HaplotypeCaller '
        "--tmp-dir {TMPDIR} -R {REF} -I {input.bam} {INTERVAL_ARG} "
        "-O {output.gvcf} -ERC GVCF --native-pair-hmm-threads {threads} > {log} 2>&1"

rule genotype_gvcfs:
    input:
        gvcf = "results/{sample}/variants/{sample}.g.vcf.gz",
    output:
        vcf = "results/{sample}/variants/{sample}.vcf.gz",
    threads: config["threads"]["genotypegvcfs"]
    benchmark: "benchmarks/{sample}/genotypegvcfs.tsv"
    log: "logs/{sample}/genotypegvcfs.log"
    conda: "../envs/gatk.yaml"
    shell:
        'gatk --java-options "{JAVA_OPTS}" GenotypeGVCFs '
        "--tmp-dir {TMPDIR} -R {REF} -V {input.gvcf} {INTERVAL_ARG} "
        "-O {output.vcf} > {log} 2>&1"
