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

#include "include/parser.p4"
#include "include/standard_headers.p4"
#include "include/ingress_dt.p4"

control SwitchIngress(
    inout header_t hdr,
    inout ingress_metadata_t meta,
    in ingress_intrinsic_metadata_t ig_intr_md,
    in ingress_intrinsic_metadata_from_parser_t ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    /****** Register definition **********************/
    Register <bit<16>, _> (32w16384)  rIPGwU;
    Register <bit<16>, _> (32w16384)  rPSwU;

    Register <bit<16>, _> (32w16384)  rIPGwD;
    Register <bit<16>, _> (32w16384)  rPSwD;

    Register <bit<32>, _> (32w16384)  rTSlast;
    Register <bit<32>, _> (32w16384)  rTStart;

    /************ Low Pass Filter *********************/
    Lpf<bit<16>, _> (32w16384) lpfIPGwU;
    Lpf<bit<16>, _> (32w16384) lpfPSwU;
    Lpf<bit<16>, _> (32w16384) lpfIPGwD;
    Lpf<bit<16>, _> (32w16384) lpfPSwD;

    /**********  Calculate Register Index ****************/
    Hash<rSize>(HashAlgorithm_t.CRC32) hTableIndex_1;
    Hash<rSize>(HashAlgorithm_t.CRC32) hTableIndex_2;
    bit<14>  flow_index;
    bit<14>  flow_index_ref;
    bit<16>  ipg;
    bit<16>  psc;

    IngressDtTable() ingress_dt_table;

    action computeRegIndex_1() {
        flow_index = hTableIndex_1.get({hdr.ipv4.srcAddr, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr});
    }

    action computeRegIndex_2() {
        flow_index_ref = hTableIndex_2.get({hdr.ipv4.dstAddr, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr});
    }

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwU) rIPGwU_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                if (meta.hash_meta.ipgwu != 0) {
                    value =  meta.hash_meta.ipgwu;
                }
                readvalue = value;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwU) rPSwU_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                if (meta.hash_meta.pswu != 0) {
                    value = meta.hash_meta.pswu;
                }
                readvalue = value;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwD) rIPGwD_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                if (meta.hash_meta.ipgwd != 0) {
                    value =  meta.hash_meta.ipgwd;
                }
                readvalue = value;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwD) rPSwD_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                if (meta.hash_meta.pswd != 0) {
                    value =  meta.hash_meta.pswd;
                }
                readvalue = value;
        }
    };

    /****** Update the last noted Timestamp **********************/
    RegisterAction<bit<32>, rSize, bit<32>>(rTSlast) rTSlast_action = {
        void apply(inout bit<32> value, out bit<32> readvalue){
            readvalue = value;
            value = meta.hash_meta.TS;
        }
    };

    RegisterAction<bit<32>, rSize, bool>(rTStart) rTStart_action = {
        void apply(inout bit<32> value, out bool readvalue){
            readvalue = false;
            if (value == 0) {
                value = meta.hash_meta.TS;
            } else {
                if ((meta.hash_meta.TS - value) > 0x3B9ACA00) {
                    value = meta.hash_meta.TS;
                    readvalue = true;
                }
            }
        }
    };

    /***************** mac table ***************/
    action set_sflag() {
        meta.hash_meta.srcAddrFlag = true;
    }

    table macs_table {
        key = {
            hdr.ethernet.srcAddr : exact;
        }
        actions = {
            set_sflag;
        }
        size = 10;
    }

    action set_dflag() {
        meta.hash_meta.dstAddrFlag = true;
    }

    table macd_table {
        key = {
            hdr.ethernet.dstAddr : exact;
        }
        actions = {
            set_dflag;
        }
        size = 10;
    }

    action computeTSlast() {
        meta.hash_meta.TSlastComp  =  rTSlast_action.execute(flow_index);
    }

    action drop(){
        ig_intr_dprsr_md.drop_ctl = 0x1;
    }

    action set_psc(){
        psc = hdr.ipv4.totalLen + ETHERNET_HDR_FCS_SIZE;
    }

    action set_ipg(){
        ipg = (bit<16>) (meta.hash_meta.TS - meta.hash_meta.TSlastComp);
    }

    /*********************** Apply ************************/
    apply {

    meta.hash_meta.TS = ig_intr_md.ingress_mac_tstamp[31:0];
    computeRegIndex_1();
    computeRegIndex_2();
    computeTSlast();

    set_ipg();
    set_psc();

    meta.hash_meta.srcAddrFlag = false;
    meta.hash_meta.dstAddrFlag = false;
    macs_table.apply();
    macd_table.apply();

    if (meta.hash_meta.srcAddrFlag || meta.hash_meta.dstAddrFlag) {

        if (ipg == (bit<16>) meta.hash_meta.TS) {
            ipg = IPG_TH_DL;
        }

        /********** Downlink ******************/
        meta.hash_meta.ipgwd = lpfIPGwD.execute(ipg, flow_index);
        meta.hash_meta.ipgw_d = rIPGwD_action.execute(flow_index);

        meta.hash_meta.pswd = lpfPSwD.execute(psc, flow_index);
        meta.hash_meta.psw_d = rPSwD_action.execute(flow_index);

        meta.hash_meta.ipgwu = 0;
        meta.hash_meta.ipgw_u = rIPGwU_action.execute(flow_index_ref);

        meta.hash_meta.pswu = 0;
        meta.hash_meta.psw_u = rPSwU_action.execute(flow_index_ref);
    } else {

        if (ipg == (bit<16>) meta.hash_meta.TS) {
            ipg = IPG_TH_UL;
        }

        /********** Uplink ******************/
        meta.hash_meta.ipgwu = lpfIPGwU.execute(ipg, flow_index);
        meta.hash_meta.ipgw_u = rIPGwU_action.execute(flow_index);

        meta.hash_meta.pswu = lpfPSwU.execute(psc, flow_index);
        meta.hash_meta.psw_u = rPSwU_action.execute(flow_index);

        meta.hash_meta.ipgwd = 0;
        meta.hash_meta.ipgw_d = rIPGwD_action.execute(flow_index_ref);

        meta.hash_meta.pswd = 0;
        meta.hash_meta.psw_d = rPSwD_action.execute(flow_index_ref);
    }

    meta.hash_meta.time_th = rTStart_action.execute(flow_index);

    if (meta.hash_meta.time_th) {
        ingress_dt_table.apply(hdr, meta);
    } else {
        /* For testing only */
        drop();
    }

    }
    }

    /*********************  E G R E S S   P R O C E S S I N G  ********************************************/
    control SwitchEgress(
        inout header_t hdr,
        inout egress_metadata_t meta,
        in egress_intrinsic_metadata_t eg_intr_md,
        in egress_intrinsic_metadata_from_parser_t eg_intr_from_prsr,
        inout egress_intrinsic_metadata_for_deparser_t eg_intr_md_for_dprsr,
        inout egress_intrinsic_metadata_for_output_port_t eg_intr_md_for_oport) {

        apply{ }
    }

    /********************************  S W I T C H  ********************************************************/
    Pipeline(SwitchIngressParser(),
        SwitchIngress(),
        SwitchIngressDeparser(),
        SwitchEgressParser(),
        SwitchEgress(),
        SwitchEgressDeparser()) pipe;


    Switch(pipe) main;

    /************************************* End ************************************************/