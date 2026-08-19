FROM centos:7 AS builder

RUN rm -rf /etc/yum.repos.d/* \
    && printf '[base]\nname=CentOS-$releasever - Base - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/os/$basearch/\ngpgcheck=0\nenabled=1\n\n[updates]\nname=CentOS-$releasever - Updates - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/updates/$basearch/\ngpgcheck=0\nenabled=1\n\n[extras]\nname=CentOS-$releasever - Extras - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/extras/$basearch/\ngpgcheck=0\nenabled=1\n' > /etc/yum.repos.d/CentOS-Base.repo

RUN yum install -y wget bzip2 && yum clean all

RUN wget -L https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh -O /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -b -p /opt/miniconda3 \
    && rm -f /tmp/miniconda.sh

ENV PATH=/opt/miniconda3/bin:$PATH

# Install mamba into base (fast solver, CentOS 7 compatible)
RUN conda install -n base -c conda-forge -y mamba && conda clean -afy

RUN conda install -n base -c conda-forge -y conda-pack && conda clean -afy

RUN mamba create -n py39 python=3.9.20 -c conda-forge -y && conda clean -afy

# Use mamba for fast dependency solving
RUN mamba install -n py39 -c conda-forge -y \
    pymysql pyodbc lxml pandas pytz numpy requests pyyaml cryptography jaydebeapi \
    certifi charset-normalizer contourpy cycler docopt et_xmlfile fonttools greenlet \
    idna importlib_resources jpype1 kiwisolver matplotlib openpyxl packaging patsy \
    pillow pyparsing python-dateutil scipy seaborn six sqlalchemy statsmodels \
    typing_extensions tzdata urllib3 xlsxwriter zipp \
    fastapi uvicorn pydantic pydantic-settings pyjwt httpx python-multipart \
    python-dotenv psycopg2 \
    && conda clean -afy

RUN conda env export -n py39 > /opt/miniconda3/envs/py39/environment-locked.yml

COPY req-pip.txt /tmp/req-pip.txt
RUN /opt/miniconda3/envs/py39/bin/pip install --no-cache-dir -r /tmp/req-pip.txt

RUN conda pack -n py39 -o /tmp/py39.tgz

FROM centos:7

COPY --from=builder /tmp/py39.tgz /py39.tgz
COPY --from=builder /opt/miniconda3/envs/py39/environment-locked.yml /environment-locked.yml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
