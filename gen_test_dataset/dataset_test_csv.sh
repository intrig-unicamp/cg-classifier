 ################################################################################
 # Copyright 2023 INTRIG
 #
 # Licensed under the Apache License, Version 2.0 (the "License");
 # you may not use this file except in compliance with the License.
 # You may obtain a copy of the License at
 #
 #     http://www.apache.org/licenses/LICENSE-2.0
 #
 # Unless required by applicable law or agreed to in writing, software
 # distributed under the License is distributed on an "AS IS" BASIS,
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 # See the License for the specific language governing permissions and
 # limitations under the License.
 ################################################################################

#!/bin/bash

set -eu -o pipefail

ISCG=$1
INFILEDIR=$2


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUT_DIR_CG_CSV="OUTPUT_DATASET/CG_TEST_CSV"
OUT_DIR_NONCG_CSV="OUTPUT_DATASET/NON_CG_TEST_CSV"
INFILE_DIR=${DIR}/${INFILEDIR}

mkdir -p $OUT_DIR_CG_CSV
mkdir -p $OUT_DIR_NONCG_CSV
cd $INFILE_DIR

for filename in *.pcap; #get the list of files
do
    if [ $ISCG == 1 ]
    then
        tshark -r $filename -Y "udp" -T fields -E separator=, -e eth.src -e eth.dst -e ipv6.src \
        -e ipv6.dst -e ipv6.nxt -e ip.src -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport -e frame.len -e dtls.record.content_type -e dtls.record.length \
        -e frame.time_relative >> ${DIR}/${OUT_DIR_CG_CSV}/${filename}.csv
    else
        tshark -r $filename -Y "udp" -T fields -E separator=, -e eth.src -e eth.dst -e ipv6.src \
        -e ipv6.dst -e ipv6.nxt -e ip.src -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport -e frame.len -e dtls.record.content_type -e dtls.record.length \
        -e frame.time_relative >> ${DIR}/${OUT_DIR_NONCG_CSV}/${filename}.csv
    fi

done
