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
RUN conda create -n py39 python=3.9.20 -y \
    && conda clean -afy

# Install conda-pack in base environment (used to pack py39 later)
RUN conda install -n base -y conda-pack \
    && conda clean -afy
    
RUN conda install -n py39 -y pymysql pyodbc lxml pandas pytz numpy requests pyyaml cryptography JayDeBeApi \
    && conda clean -afy

# Install ALL packages via conda-forge with pinned versions (req.txt - pip-only packages excluded)
RUN conda install -n py39 -y \
    certifi==2024.8.30 \
    charset-normalizer==3.4.0 \
    contourpy==1.3.0 \
    cycler==0.12.1 \
    docopt==0.6.2 \
    et_xmlfile==2.0.0 \
    fonttools==4.56.0 \
    greenlet==3.1.1 \
    idna==3.10 \
    importlib_resources==6.5.2 \
    jaydebeapi==1.2.3 \
    jpype1==1.3.0 \
    kiwisolver==1.4.7 \
    lxml==5.3.2 \
    matplotlib==3.9.4 \
    numpy==2.0.2 \
    openpyxl==3.1.5 \
    packaging==24.2 \
    pandas==2.2.3 \
    patsy==1.0.1 \
    pillow==11.1.0 \
    pymysql==1.1.1 \
    pyodbc==5.2.0 \
    pyparsing==3.2.2 \
    python-dateutil==2.9.0 \
    pytz==2025.1 \
    pyyaml \
    requests==2.32.3 \
    scipy==1.13.1 \
    seaborn==0.13.2 \
    six==1.17.0 \
    sqlalchemy==2.0.39 \
    statsmodels==0.14.4 \
    typing_extensions==4.12.2 \
    tzdata \
    urllib3==2.2.3 \
    xlsxwriter==3.2.3 \
    zipp==3.21.0 \
    cryptography \
    fastapi==0.115.6 \
    uvicorn==0.34.0 \
    pydantic==2.10.4 \
    pydantic-settings==2.7.0 \
    pyjwt==2.10.1 \
    httpx==0.28.1 \
    python-multipart==0.0.20 \
    python-dotenv==1.0.1 \
    psycopg2==2.9.10 \
    && conda clean -afy


COPY req-pip.txt /tmp/req-pip.txt
RUN /opt/miniconda3/envs/py39/bin/pip install --no-cache-dir -r /tmp/req-pip.txt

# Pack the conda environment into a tarball
RUN conda pack -n py39 -o /tmp/py39.tgz

# ============================
# Final runtime stage
FROM centos:7

COPY --from=builder /tmp/py39.tgz /py39.tgz
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
