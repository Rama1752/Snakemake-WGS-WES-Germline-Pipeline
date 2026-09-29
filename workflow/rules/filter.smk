# Split SNP/INDEL, hard-filter each, extract PASS, merge to one filtered VCF.

rule select_snps:
    input:  vcf = "results/{sample}/variants/{sample}.vcf.gz"
    output: vcf = "results/{sample}/variants/{sample}.snps.raw.vcf.gz"
    log: "logs/{sample}/select_snps.log"
    conda: "../envs/gatk.yaml"
    shell:
        'gatk --java-options "{JAVA_OPTS}" SelectVariants --tmp-dir {TMPDIR} '
        "-R {REF} -V {input.vcf} --select-type-to-include SNP -O {output.vcf} > {log} 2>&1"

rule select_indels:
    input:  vcf = "results/{sample}/variants/{sample}.vcf.gz"
    output: vcf = "results/{sample}/variants/{sample}.indels.raw.vcf.gz"
    log: "logs/{sample}/select_indels.log"
    conda: "../envs/gatk.yaml"
    shell:
        'gatk --java-options "{JAVA_OPTS}" SelectVariants --tmp-dir {TMPDIR} '
        "-R {REF} -V {input.vcf} --select-type-to-include INDEL -O {output.vcf} > {log} 2>&1"

if RUN_FILTER:
    rule filter_snps:
        input:  vcf = "results/{sample}/variants/{sample}.snps.raw.vcf.gz"
        output: vcf = "results/{sample}/variants/{sample}.snps.filtered.vcf.gz"
        params:
            qd  = float(F["qd_snp"]),  fs  = float(F["fs_snp"]),  sor = float(F["sor_snp"]),
            mq  = float(F["mq_snp"]),  mqr = float(F["mqranksum_snp"]), rpr = float(F["readposranksum_snp"]),
        log: "logs/{sample}/filter_snps.log"
        conda: "../envs/gatk.yaml"
        shell:
            'gatk --java-options "{JAVA_OPTS}" VariantFiltration --tmp-dir {TMPDIR} '
            "-R {REF} -V {input.vcf} -O {output.vcf} "
            '--filter-name "QD2"            --filter-expression "QD < {params.qd}" '
            '--filter-name "FS60"           --filter-expression "FS > {params.fs}" '
            '--filter-name "SOR3"           --filter-expression "SOR > {params.sor}" '
            '--filter-name "MQ40"           --filter-expression "MQ < {params.mq}" '
            '--filter-name "MQRankSum"      --filter-expression "MQRankSum < {params.mqr}" '
            '--filter-name "ReadPosRankSum" --filter-expression "ReadPosRankSum < {params.rpr}" '
            "> {log} 2>&1"

    rule filter_indels:
        input:  vcf = "results/{sample}/variants/{sample}.indels.raw.vcf.gz"
        output: vcf = "results/{sample}/variants/{sample}.indels.filtered.vcf.gz"
        params:
            qd = float(F["qd_indel"]), fs = float(F["fs_indel"]), sor = float(F["sor_indel"]),
        log: "logs/{sample}/filter_indels.log"
        conda: "../envs/gatk.yaml"
        shell:
            'gatk --java-options "{JAVA_OPTS}" VariantFiltration --tmp-dir {TMPDIR} '
            "-R {REF} -V {input.vcf} -O {output.vcf} "
            '--filter-name "QD2"   --filter-expression "QD < {params.qd}" '
            '--filter-name "FS200" --filter-expression "FS > {params.fs}" '
            '--filter-name "SOR10" --filter-expression "SOR > {params.sor}" '
            "> {log} 2>&1"
else:
    rule filter_snps:
        input:  vcf = "results/{sample}/variants/{sample}.snps.raw.vcf.gz"
        output: vcf = "results/{sample}/variants/{sample}.snps.filtered.vcf.gz"
        log: "logs/{sample}/filter_snps.log"
        conda: "../envs/gatk.yaml"
        shell: "cp {input.vcf} {output.vcf} && cp {input.vcf}.tbi {output.vcf}.tbi 2> {log}"

    rule filter_indels:
        input:  vcf = "results/{sample}/variants/{sample}.indels.raw.vcf.gz"
        output: vcf = "results/{sample}/variants/{sample}.indels.filtered.vcf.gz"
        log: "logs/{sample}/filter_indels.log"
        conda: "../envs/gatk.yaml"
        shell: "cp {input.vcf} {output.vcf} && cp {input.vcf}.tbi {output.vcf}.tbi 2> {log}"

rule merge_filtered:
    input:
        snps   = "results/{sample}/variants/{sample}.snps.filtered.vcf.gz",
        indels = "results/{sample}/variants/{sample}.indels.filtered.vcf.gz",
    output:
        vcf = "results/{sample}/variants/{sample}.filtered.vcf.gz",
    log: "logs/{sample}/merge_filtered.log"
    conda: "../envs/gatk.yaml"
    shell:
        "bcftools concat -a {input.snps} {input.indels} 2> {log} "
        "| bcftools sort -Oz -o {output.vcf} 2>> {log} && "
        "tabix -p vcf {output.vcf}"
