#!/bin/bash

set -eu -o pipefail

DURATION=$1
IPTYPE=$2
INFILE=$3
OUTFILE=$4

## run this script by passing three arguments:
## DURATION : provide integer value to denote the time-window size in sec
## INFILE   : locate the path of main PCAP file
## OUTFILE  : mention the output pcap name

## how to run this script:
## ./script_name DURATION INFILE OUTFILE
## e.g., ./dataset.sh 1 ../../../data/MAWI20/mawi1.pcap 1sec.pcap


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUT_DIR_PCAP="OUTPUT_DATASET/CG_PCAP"
OUT_DIR_CSV="OUTPUT_DATASET/CG_CSV"
INFILE_NAME=${DIR}/${INFILE}
SPLIT_PCAP_CMD="editcap -i ${DURATION} ${INFILE_NAME} ${OUTFILE}"
IPV4=4


mkdir -p $OUT_DIR_PCAP $OUT_DIR_CSV
cd $OUT_DIR_PCAP
echo "*** Split PCAP file into ${DURATION} sec time window"
$SPLIT_PCAP_CMD
echo "*** Done"

echo "*** Start converting each ${DURATION} sec PCAP in CSV with the required parameters"
for filename in *.pcap; #get the list of files
do
    if [ $IPTYPE == $IPV4 ]
    then
        tshark -r $filename -Y "udp" -T fields -E separator=, -e eth.src -e eth.dst -e ip.src \
        -e ip.dst -e ip.proto -e udp.srcport -e udp.dstport -e frame.len -e dtls.record.content_type -e dtls.record.length \
        -e frame.time_relative >> ${DIR}/${OUT_DIR_CSV}/${filename}.csv
    else
        tshark -r $filename -Y "udp" -T fields -E separator=, -e eth.src -e eth.dst -e ipv6.src \
        -e ipv6.dst -e ipv6.nxt -e udp.srcport -e udp.dstport -e frame.len -e dtls.record.content_type -e dtls.record.length \
        -e frame.time_relative >> ${DIR}/${OUT_DIR_CSV}/${filename}.csv
    fi
done

echo "*** Done \ Ready for testing"
