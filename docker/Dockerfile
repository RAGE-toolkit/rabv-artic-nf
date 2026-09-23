#Docker file version v2.0.0
#Last modified: Sep 2026

#Dockerfile for ARM64 (Mac) and AMD64 (Linux) - single file, built per-target via
#buildx's --platform flag and its auto-populated TARGETARCH build arg. Do not add
#--platform to the FROM line below - that pins the base image's arch regardless of
#what --platform the build is invoked with, which silently breaks the other arch.

#############
# Running docker file
# Mac (arm64):   docker buildx build --platform linux/arm64  -t rage2025/artic-nf-arm64:v2.0  --load .
# Linux (amd64): docker buildx build --platform linux/amd64  -t rage2025/artic-nf-amd64:v2.0  --load .
# Both in one go (build only, needs a registry to push to instead of --load):
#                docker buildx build --platform linux/arm64,linux/amd64 -t rage2025/artic-nf:v2.0 --push .
############


# Use Ubuntu 22.04 as base image - no --platform pin, buildx resolves the correct
# arch variant from the --platform flag passed to the build command
FROM ubuntu:22.04

# buildx sets this automatically per --platform target (e.g. "arm64" or "amd64")
ARG TARGETARCH

LABEL maintainer="Sandeep Kasaragod <your-email@example.com>"

ENV DEBIAN_FRONTEND=noninteractive

# Step 1: Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    curl \
    git \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    tabix \
    unzip \
    bc \
    autoconf \
    automake \
    libtool \
    pkg-config \
    samtools \
    ca-certificates \
    clang \
    cmake \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 2: Set python3.10 as default
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Step 3: Install pip packages
RUN pip install --no-cache-dir \
    numpy==1.23.5 \
    pandas \
    biopython \
    pysam \
    pyarrow \
    pyfaidx \
    cyvcf2 \
    matplotlib \
    seaborn \
    plotly

# Step 4: Install MAFFT
RUN apt-get update && apt-get install -y mafft

# Step 5: Install minimap2 (arm_neon/aarch64 build flags only apply on arm64)
RUN cd /opt && \
    git clone https://github.com/lh3/minimap2 && \
    cd minimap2 && \
    if [ "$TARGETARCH" = "arm64" ]; then make arm_neon=1 aarch64=1; else make; fi && \
    ln -s /opt/minimap2/minimap2 /usr/local/bin/minimap2

# Step 6: Install datamash
RUN cd /opt && \
    wget http://ftp.gnu.org/gnu/datamash/datamash-1.8.tar.gz && \
    tar -xzf datamash-1.8.tar.gz && \
    cd datamash-1.8 && \
    ./configure && make && make install

# Step 7: Install OpenJDK 11 (required for Nextflow)
RUN apt-get update && apt-get install -y openjdk-11-jdk

# Step 8: Install Nextflow v23.10.0
RUN curl -fsSL https://github.com/nextflow-io/nextflow/releases/download/v23.10.0/nextflow-23.10.0-all -o /usr/local/bin/nextflow && \
    chmod +x /usr/local/bin/nextflow && \
    /usr/local/bin/nextflow -version

# Step 9: Install medaka (legacy, no longer used by the pipeline as of v2.0 - kept installed
# in case an older revision of the workflow needs to run in this image)
RUN pip install medaka==1.11.3 tensorflow==2.10.1

# Step 10: Install Miniforge (conda/mamba) - align_trim, clair3 and primalbedtools are
# bioconda-only packages with no apt/pip equivalent. Miniforge names its installer by
# uname -m (aarch64/x86_64), not Docker's arm64/amd64, so map TARGETARCH to match.
# Not added to PATH here - base env's python would otherwise shadow the system
# python3.10 that every pip package above (numpy, pysam, cyvcf2, ...) is installed into.
RUN MINIFORGE_ARCH=$([ "$TARGETARCH" = "arm64" ] && echo "aarch64" || echo "x86_64") && \
    curl -fsSL -o /tmp/miniforge.sh \
      https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${MINIFORGE_ARCH}.sh && \
    bash /tmp/miniforge.sh -b -p /opt/miniforge && \
    rm /tmp/miniforge.sh

# Step 11: Install align_trim, Clair3 and primalbedtools (the fieldbioinformatics v2 backend)
# into their own env pinned to python=3.11, since clair3 requires <3.12 and Miniforge's
# base env floats to whatever the latest installer ships (currently 3.14). Only this env's
# bin/ is appended (not prepended) to PATH, so `python`/`pip` still resolve to the system
# python3.10 everywhere else in the pipeline.
# clair3 is pinned to the exact version (2.0.2) used to generate the fieldbioinformatics
# reference outputs this pipeline is validated against - Clair3's neural-network scoring
# can shift quality scores slightly between versions, which matters for the hard
# --min-variant-quality cutoff downstream.
RUN /opt/miniforge/bin/mamba create -y -n clair3env -c bioconda -c conda-forge \
     python=3.11 "align_trim>=1.2.0" "clair3==2.0.2" "primalbedtools>=1.0.0" && \
    /opt/miniforge/bin/mamba clean --all --yes
ENV PATH="${PATH}:/opt/miniforge/envs/clair3env/bin"

# run_clair3.sh internally shells out to a bare `python3` for its calling steps, which
# would resolve to the system python3.10 (no torch) given the PATH order above. Patch its
# default so it always resolves to clair3env's own python3 without needing --python=... on
# every call site.
RUN sed -i 's|default="python3"|default="/opt/miniforge/envs/clair3env/bin/python3"|' \
    /opt/miniforge/envs/clair3env/bin/run_clair3.py

# Step 12: Install fieldbioinformatics (artic_vcf_merge, artic_vcf_filter,
# artic_make_depth_mask, artic_mask, artic_fasta_header, artic_get_models)
RUN pip install --no-cache-dir "fieldbioinformatics>=2.0.0" || \
    pip install --no-cache-dir "git+https://github.com/artic-network/fieldbioinformatics.git"

# Step 13: Clone and build HTSlib
RUN git clone --branch=1.18 https://github.com/samtools/htslib.git /opt/htslib && \
    cd /opt/htslib && \
    git submodule update --init --recursive && \
    make && make install

# Step 14: Clone and build BCFtools
RUN git clone --branch=1.18 https://github.com/samtools/bcftools.git /opt/bcftools && \
    cd /opt/bcftools && \
    make && make install


# Step 15: Install MUSCLE
RUN apt-get update && apt-get install -y muscle \
		&& apt-get clean && rm -rf /var/lib/apt/lists/*

# Step 16: Final cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Default CMD
CMD ["/bin/bash"]
