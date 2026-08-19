#!/bin/bash

# 130机器上

cd /home/uploaddata_provice_compare

source /data/soft/py39/bin/activate

export JPYPE_JVM_VERBOSE=1

export JAVA_HOME=/data/soft/jdk1.8.0_381
export PATH=$JAVA_HOME/bin:$PATH
export CLASSPATH=.:$JAVA_HOME/lib/dt.jar:$JAVA_HOME/lib/tools.jar

java -version
python3 main.py
