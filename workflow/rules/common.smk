import pandas as pd
import os

samples_df = pd.read_csv(config["samples"], sep="\t", dtype=str).set_index("sample", drop=False)
SAMPLES   = samples_df["sample"].tolist()
SAMPLE_R1 = dict(zip(samples_df["sample"], samples_df["Read1"]))
SAMPLE_R2 = dict(zip(samples_df["sample"], samples_df["Read2"]))

wildcard_constraints:
    sample = "|".join(SAMPLES)

# ---- reference ----
REF = config["reference"]["fasta"]

# ---- mode switch: WES vs WGS ----
MODE = config["mode"].lower()
assert MODE in ("wes", "wgs"), f"mode must be wes|wgs, got {MODE}"
WES  = MODE == "wes"

TARGETS     = config["capture"]["targets"] if WES else ""
TARGETS_BED = config["capture"]["bed"]     if WES else ""
PADDING     = config["capture"]["padding"]
INTERVAL_ARG = f'-L "{TARGETS}" --interval-padding {PADDING}' if WES else ""

# ---- BQSR switch ----
RUN_BQSR    = config["bqsr"]["run"]
KNOWN_SITES = config["bqsr"]["known_sites"]
KNOWN_ARG   = " ".join(f"--known-sites {k}" for k in KNOWN_SITES)
if RUN_BQSR and not KNOWN_SITES:
    raise ValueError("bqsr.run is true but known_sites is empty")

# ---- filter switch ----
RUN_FILTER = config["filters"]["run"]
F = config["filters"]

# ---- scratch + java ----
TMPDIR = config.get("tmpdir", "tmp")
os.makedirs(TMPDIR, exist_ok=True)
JAVA_MEM  = config.get("java_mem", "16G")
JAVA_OPTS = f'-Xmx{JAVA_MEM} -Djava.io.tmpdir={TMPDIR} -XX:+PerfDisableSharedMem'

# ---- helpers ----
# analysis-ready BAM: recalibrated if BQSR on, else markdup
def final_bam(wc):
    return f"results/{wc.sample}/align/{wc.sample}.bqsr.bam" if RUN_BQSR \
           else f"results/{wc.sample}/align/{wc.sample}.markdup.bam"
