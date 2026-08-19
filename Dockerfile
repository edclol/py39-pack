FROM centos:7 AS builder

RUN rm -rf /etc/yum.repos.d/* \
    && printf '[base]\nname=CentOS-$releasever - Base - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/os/$basearch/\ngpgcheck=0\nenabled=1\n\n[updates]\nname=CentOS-$releasever - Updates - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/updates/$basearch/\ngpgcheck=0\nenabled=1\n\n[extras]\nname=CentOS-$releasever - Extras - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/extras/$basearch/\ngpgcheck=0\nenabled=1\n' > /etc/yum.repos.d/CentOS-Base.repo

# Install prerequisites
RUN yum install -y wget bzip2 && yum clean all

# Install Miniconda
RUN wget -L https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/miniconda3 \
    && rm -f /tmp/miniconda.sh

ENV PATH=/opt/miniconda3/bin:$PATH
ENV CONDA_PKGS_DIRS=/opt/miniconda3/pkgs

# Create py39 conda environment
RUN /opt/miniconda3/bin/conda create -n py39 python=3.9.20 -c conda-forge -y \
    && /opt/miniconda3/bin/conda clean -afy

# Install conda-pack in base environment (used to pack py39 later)
RUN /opt/miniconda3/bin/conda install -n base -c conda-forge -y conda-pack \
    && /opt/miniconda3/bin/conda clean -afy

# Install target packages into py39 environment via conda
RUN /opt/miniconda3/bin/conda install -n py39 -c conda-forge -y \
    pymysql \
    pyodbc \
    lxml \
    pandas \
    pytz \
    numpy \
    requests \
    pyyaml \
    cryptography \
    jaydebeapi \
    && /opt/miniconda3/bin/conda clean -afy

# Install remaining packages via pip
COPY req.txt /tmp/req.txt
RUN /opt/miniconda3/envs/py39/bin/pip install --no-cache-dir -r /tmp/req.txt

# Pack the conda environment into a tarball
RUN /opt/miniconda3/bin/conda pack -n py39 -o /tmp/py39.tgz

# ============================
# Final runtime stage
FROM centos:7

COPY --from=builder /tmp/py39.tgz /py39.tgz
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]