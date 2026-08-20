FROM centos:7 AS builder

RUN rm -rf /etc/yum.repos.d/* \
    && printf '[base]\nname=CentOS-$releasever - Base - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/os/$basearch/\ngpgcheck=0\nenabled=1\n\n[updates]\nname=CentOS-$releasever - Updates - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/updates/$basearch/\ngpgcheck=0\nenabled=1\n\n[extras]\nname=CentOS-$releasever - Extras - Aliyun\nbaseurl=https://mirrors.aliyun.com/centos-vault/7.9.2009/extras/$basearch/\ngpgcheck=0\nenabled=1\n' > /etc/yum.repos.d/CentOS-Base.repo

RUN yum install -y wget bzip2 && yum clean all

# Miniforge3 bundles conda + mamba natively, CentOS 7 compatible
RUN wget -L https://github.com/conda-forge/miniforge/releases/download/23.3.1-1/Miniforge3-23.3.1-1-Linux-x86_64.sh -O /tmp/miniforge.sh \
    && bash /tmp/miniforge.sh -b -p /opt/miniforge3 \
    && rm -f /tmp/miniforge.sh

ENV PATH=/opt/miniforge3/bin:$PATH

RUN mamba config --add channels conda-forge \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/ \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/r \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/msys2 \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2 \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/menpo \
    && mamba config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch \
    && mamba config --set report_errors true \
    && mamba config --set ssl_verify false \
    && mamba config --set show_channel_urls yes \
    && mamba config --show channels


# conda-pack is a conda plugin — install with mamba, will still work as "conda pack"
RUN mamba install -n base -c conda-forge -y conda-pack && mamba clean -afy

RUN mamba create -n py39 python=3.9.20 -c conda-forge -y && mamba clean -afy

# All packages via mamba (conda-forge)
RUN mamba install -n py39 -c conda-forge -y \
    pymysql pyodbc lxml pandas pytz numpy requests pyyaml cryptography jaydebeapi \
    certifi charset-normalizer contourpy cycler docopt et_xmlfile fonttools greenlet \
    idna importlib_resources jpype1 kiwisolver matplotlib openpyxl packaging patsy \
    pillow pyparsing python-dateutil scipy seaborn six sqlalchemy statsmodels \
    typing_extensions tzdata urllib3 xlsxwriter zipp \
    fastapi uvicorn pydantic pydantic-settings pyjwt httpx python-multipart \
    python-dotenv psycopg2 \
    && mamba clean -afy

# Export locked environment
RUN mamba env export -n py39 > /opt/miniforge3/envs/py39/environment-locked.yml

# Pip-only packages (not on conda-forge)
COPY req-pip.txt /tmp/req-pip.txt
RUN /opt/miniforge3/envs/py39/bin/pip install --no-cache-dir -r /tmp/req-pip.txt

# conda pack is a conda plugin — no mamba equivalent, must stay conda
RUN conda pack -n py39 -o /tmp/py39.tgz

FROM centos:7

COPY --from=builder /tmp/py39.tgz /py39.tgz
COPY --from=builder /opt/miniforge3/envs/py39/environment-locked.yml /environment-locked.yml
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
