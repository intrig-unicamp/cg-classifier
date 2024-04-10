/*********************************************************************
* Copyright 2023 INTRIG
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*    http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
**********************************************************************/

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

#ifndef _HEADERS_
#define _HEADERS_

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

header ethernet_t {
    bit<48>   dstAddr;
    bit<48>   srcAddr;
    bit<16>   etherType;
}

header ipv4_t {
    bit<4>    version;
    bit<4>    ihl;
    bit<8>    diffserv;
    bit<16>   totalLen;
    bit<16>   identification;
    bit<3>    flags;
    bit<13>   fragOffset;
    bit<8>    ttl;
    bit<8>    protocol;
    bit<16>   hdrChecksum;
    bit<32>   srcAddr;
    bit<32>   dstAddr;
}

header ipv6_t {
    bit<4>        version;
    bit<8>        trafficClass;
    bit<20>       flowLabel;
    bit<16>       payloadLen;
    bit<8>        nextHdr;
    bit<8>        hopLimit;
    bit<128>      srcAddr;
    bit<128>      dstAddr;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<4>  res;
    bit<8>  flags;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header udp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<16> plength;
    bit<16> checksum;
}

/* Local metadata */
struct ingress_metadata_t {
    bit<32>  TS;
    bit<16>  ipgwu;
    bit<16>  pswu;
    bit<16>  ipgwd;
    bit<16>  pswd;
    bit<32>  TSlastComp;
    bool     is_cg;

    bit<16>  ipgw_d;
    bit<16>  ipgw_u;
    bit<16>  psw_d;
    bit<16>  psw_u;
    bit<16>  cn_d;
    bit<16>  cn_u;

    bit<16>  cg_c1;
    bit<16>  cg_c2;
    bit<16>  cg_c3;
    bit<16>  cg_c4;
    bit<16>  cg_c5;
    bit<16>  cg_c6;

    bool srcAddrFlag;
    bool dstAddrFlag;

    bool is_ipv6;
    bit<16> ipg;
    bit<32> ipg_temp;
    bit<2> is_reset;
    bit<16> pkts_n;
    bit<16> ipg_gain;
    bit<16> psc_gain;
    bool temp;
    bit<16> psc;
    bit<14> flow_index;
    bit<14> flow_index_ref;
}

struct header_t {
    ethernet_t   ethernet;
    ipv4_t       ipv4;
    ipv6_t       ipv6;
    udp_t        udp;
    tcp_t        tcp;
}

struct egress_metadata_t {

}


#endif