FROM centos:7 AS builder

# Install prerequisites
RUN yum install -y wget bzip2 && yum clean all

# Install Miniconda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm -f /tmp/miniconda.sh

ENV PATH=/opt/conda/bin:$PATH

# Create py39 conda environment
RUN conda create -n py39 python=3.9.20 -c conda-forge -y && \
    conda clean -afy

# Install packages via conda (handles binary deps better)
RUN conda install -n py39 -c conda-forge -y \
    conda-pack \
    pymysql \
    pyodbc \
    lxml \
    pandas \
    pytz \
    numpy \
    requests \
    pyyaml \
    cryptography \
    jaydebeapi && \
    conda clean -afy

# Install remaining packages via pip
COPY req.txt /tmp/req.txt
RUN /opt/conda/envs/py39/bin/pip install --no-cache-dir -r /tmp/req.txt

# Pack the conda environment into a tarball
RUN conda pack -n py39 -o /tmp/py39.tgz

# ============================
# Final runtime stage
FROM centos:7

COPY --from=builder /tmp/py39.tgz /py39.tgz
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]