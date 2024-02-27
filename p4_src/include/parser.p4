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

/****************Parser********************/

#include <core.p4>
#if __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif
#include "standard_headers.p4"
#include "constants.p4"

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser TofinoIngressParser(
        packet_in pkt,
        out ingress_intrinsic_metadata_t ig_intr_md) {
    state start {
        pkt.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        // Parse resubmitted packet here.
        transition reject;
    }

    state parse_port_metadata {
#if __TARGET_TOFINO__ == 2
       //pkt.advance(192);
       pkt.advance(PORT_METADATA_SIZE);
#else
       //pkt.advance(64);
       pkt.advance(PORT_METADATA_SIZE);
#endif
       transition accept;
     }
}

parser TofinoEgressParser(
        packet_in pkt,
        out egress_intrinsic_metadata_t eg_intr_md) {
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------

parser SwitchIngressParser(
        packet_in packet,
        out header_t hdr,
        out ingress_metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

   state start {
        ig_md = {
            TS = 0,
            ipgwu = 0,
            pswu = 0,
            ipgwd = 0,
            pswd = 0,
            TSlastComp = 0,
            is_cg = false,
            ipgw_d = 0,
            ipgw_u = 0,
            psw_d = 0,
            psw_u = 0,
            cn_d = 0,
            cn_u = 0,
            cg_c1 = 0,
            cg_c2 = 0,
            cg_c3 = 0,
            cg_c4 = 0,
            cg_c5 = 0,
            cg_c6 = 0,

            srcAddrFlag = false,
            dstAddrFlag = false,

            is_ipv6 = false,
            ipg = 0,
            ipg_temp = 0,
            is_reset = 0,
            pkts_n = 0,
            ipg_gain = 0,
            psc_gain = 0,
            temp = false,
            psc = 0,
            flow_index = 0,
            flow_index_ref = 0
        };
        packet.extract(ig_intr_md);
        transition select(ig_intr_md.resubmit_flag) {
            1 : parse_resubmit;
            0 : parse_port_metadata;
        }
    }

    state parse_resubmit {
        transition parse_ethernet;
    }

    state parse_port_metadata {
        packet.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

   state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: accept;
        }
    }

   state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            IPPROTO_UDP  : parse_udp;
            IPPROTO_TCP  : parse_tcp;
            default      : accept;
        }
    }

    state parse_ipv6 {
        ig_md.is_ipv6 = true;
        packet.extract(hdr.ipv6);
        transition select(hdr.ipv6.nextHdr) {
            IPPROTO_UDP  : parse_udp;
            IPPROTO_TCP  : parse_tcp;
            default      : accept;
        }
    }

   state parse_tcp {
        packet.extract(hdr.tcp);
        transition accept;
    }

   state parse_udp {
        packet.extract(hdr.udp);
        transition accept;
       }
  }


// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------

control SwitchIngressDeparser(
        packet_out packet,
        inout header_t hdr,
        in ingress_metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_dprsr_md) {

    apply {

        /*packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.udp);*/

        packet.emit(hdr);
  }
}

// ---------------------------------------------------------------------------
// Egress Parser
// ---------------------------------------------------------------------------

parser SwitchEgressParser(
        packet_in packet,
        out header_t hdr,
        out egress_metadata_t eg_md,
        out egress_intrinsic_metadata_t eg_intr_md) {

 	TofinoEgressParser() tofino_parser;

	state start {
        tofino_parser.apply(packet, eg_intr_md);
        transition accept;
    }
}


// ---------------------------------------------------------------------------
// Egress Deparser
// ---------------------------------------------------------------------------
control SwitchEgressDeparser(
        packet_out packet,
        inout header_t hdr,
        in egress_metadata_t eg_md,
        in egress_intrinsic_metadata_for_deparser_t eg_dprsr_md) {
       //Checksum<bit<16>>(HashAlgorithm_t.CSUM16) ipv4_checksum;

    apply {

    }

}