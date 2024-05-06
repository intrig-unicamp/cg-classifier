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
#include "include/dt.p4"

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

    Register <bit<32>, _> (32w16384)  rTWindow;
    Register <bit<16>, _> (32w16384)  rNpkts;

    /*********** Math Unit Functions ******************/
    MathUnit<bit<16>>(MathOp_t.MUL, 1, 32) right_shift;

    /**********  Calculate Register Index ****************/
    Hash<rSize>(HashAlgorithm_t.CRC32) hTableIndex_ipv4_1;
    Hash<rSize>(HashAlgorithm_t.CRC32) hTableIndex_ipv4_2;
    Hash<rSize>(HashAlgorithm_t.CRC32) hTableIndex_ipv6_1;
    Hash<rSize>(HashAlgorithm_t.CRC32) hTableIndex_ipv6_2;

    IngressDtTable() ingress_dt_table;

    action computeRegIndex_ipv4_1() {
        meta.flow_index = hTableIndex_ipv4_1.get({hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.srcAddr, HASH_IN});
    }

    /* Required flow index also for other direction */
    action computeRegIndex_ipv4_2() {
        meta.flow_index_ref = hTableIndex_ipv4_2.get({hdr.ipv4.dstAddr, hdr.ipv4.dstAddr, hdr.ipv4.srcAddr, HASH_IN});
    }

    action computeRegIndex_ipv6_1() {
        meta.flow_index = hTableIndex_ipv6_1.get({hdr.ipv6.srcAddr, hdr.ipv6.dstAddr, hdr.ipv6.srcAddr, HASH_IN});
    }

    /* Required flow index also for other direction */
    action computeRegIndex_ipv6_2() {
        meta.flow_index_ref = hTableIndex_ipv6_2.get({hdr.ipv6.dstAddr, hdr.ipv6.dstAddr, hdr.ipv6.srcAddr, HASH_IN});
    }

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwU) rIPGwU_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
                if (value > meta.ipg) {
                    value = value - right_shift.execute(value);
                } else {
                    value = value + meta.ipg_gain;
                }
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwU) rPSwU_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
                if (value > meta.psc) {
                    value = value - right_shift.execute(value);
                } else {
                    value = value + meta.psc_gain;
                }
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwD) rIPGwD_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
                if (value > meta.ipg) {
                    value = value - right_shift.execute(value);
                } else {
                    value = value + meta.ipg_gain;
                }
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwD) rPSwD_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
                if (value > meta.psc) {
                    value = value - right_shift.execute(value);
                } else {
                    value = value + meta.psc_gain;
                }
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwU) rIPGwU_1_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                value = meta.ipg;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwU) rPSwU_1_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                value = meta.psc;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwD) rIPGwD_1_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                value = meta.ipg;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwD) rPSwD_1_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                value = meta.psc;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwU) rIPGwU_2_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwU) rPSwU_2_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rIPGwD) rIPGwD_2_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rPSwD) rPSwD_2_action = {
            void apply(inout bit<16> value, out bit<16> readvalue){
                readvalue = value;
        }
    };

    /****** Update the last noted Timestamp **********************/
    RegisterAction<bit<32>, rSize, bit<32>>(rTSlast) rTSlast_action = {
        void apply(inout bit<32> value, out bit<32> readvalue){
            if (value == 0) {
                readvalue = 0;
            } else {
                readvalue = value;
            }
            value = meta.TS;
        }
    };

    RegisterAction<bit<32>, rSize, bit<2>>(rTWindow) rTWindow_action = {
        void apply(inout bit<32> value, out bit<2> readvalue){
            readvalue = 0;
            if (meta.TSlastComp == 0) {
                value = meta.TS;
            } else {
                if (meta.TS - value > 960000) {
                    value = meta.TS;
                    readvalue = 1;
                }
            }
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rNpkts) rNpkts_action = {
        void apply(inout bit<16> value, out bit<16> readvalue){
            readvalue = value;
            if (meta.is_reset == 1) {
                value = 0;
            } else {
                value = value + 1;
            }
        }
    };

    RegisterAction<bit<16>, rSize, bit<16>>(rNpkts) rNpkts_1_action = {
        void apply(inout bit<16> value, out bit<16> readvalue){
            readvalue = value;
            if (meta.is_reset == 1) {
                value = 0;
            }
        }
    };

    /***************** mac table ***************/
    action set_sflag() {
        meta.srcAddrFlag = true;
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
        meta.dstAddrFlag = true;
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
        meta.TSlastComp  =  rTSlast_action.execute(meta.flow_index);
    }

    action set_ipg(){
        meta.ipg_temp = (bit<32>) (meta.TS - meta.TSlastComp);
    }

    action rs_ipg(){
        meta.ipg_gain = (bit<16>) (meta.ipg[15:4]);
    }

    action set_psc_ipv4(){
        meta.psc = hdr.ipv4.totalLen + ETHERNET_HDR_FCS_SIZE;
    }

    action set_psc_ipv6(){
        meta.psc = hdr.ipv6.payloadLen + ETHERNET_HDR_FCS_SIZE + L3_L4_HDR_FCS_SIZE;
    }

    action rs_ps(){
        meta.psc_gain = (bit<16>) (meta.psc[15:4]);
    }

    /*********************** Apply ************************/
    apply {

    /* For testing only */
    /* TODO(Suneet): this is used only for knowing uplink or downlink direction
     * later it can be differentiate based on incoming ports */
    macs_table.apply();
    macd_table.apply();

    meta.TS = (bit<32>) ig_intr_md.ingress_mac_tstamp[39:10];
    if (meta.is_ipv6) {
        set_psc_ipv6();
        computeRegIndex_ipv6_1();
        computeRegIndex_ipv6_2();
    } else {
        set_psc_ipv4();
        computeRegIndex_ipv4_1();
        computeRegIndex_ipv4_2();
    }
    computeTSlast();
    set_ipg();

    if (meta.ipg_temp > 65535) {
       meta.ipg = 65535;
    } else {
       meta.ipg = (bit<16>) (meta.ipg_temp);
    }
    rs_ipg();
    rs_ps();

    if (meta.srcAddrFlag || meta.dstAddrFlag) {

        if (meta.TSlastComp == 0) {
            meta.ipg = IPG_TH_DL;
            rIPGwD_1_action.execute(meta.flow_index);
            rPSwD_1_action.execute(meta.flow_index);
            rIPGwU_1_action.execute(meta.flow_index_ref);
            rPSwU_1_action.execute(meta.flow_index_ref);
        } else {
            /********** Downlink ******************/
            meta.ipgw_d = rIPGwD_action.execute(meta.flow_index);
            meta.psw_d = rPSwD_action.execute(meta.flow_index);

            /* Required uplink parameters also for DT */
            meta.ipgw_u = rIPGwU_2_action.execute(meta.flow_index_ref);
            meta.psw_u = rPSwU_2_action.execute(meta.flow_index_ref);
        }
        meta.is_reset = rTWindow_action.execute(meta.flow_index_ref);
        meta.pkts_n = rNpkts_1_action.execute(meta.flow_index_ref);
    } else {
        if (meta.TSlastComp == 0) {
            meta.ipg = IPG_TH_UL;
            rIPGwU_1_action.execute(meta.flow_index);
            rPSwU_1_action.execute(meta.flow_index);
            rIPGwD_1_action.execute(meta.flow_index_ref);
            rPSwD_1_action.execute(meta.flow_index_ref);
        } else {

            /********** Uplink ******************/
            meta.ipgw_u = rIPGwU_action.execute(meta.flow_index);
            meta.psw_u = rPSwU_action.execute(meta.flow_index);

            /* Required downlink parameters also for DT */
            meta.ipgw_d = rIPGwD_2_action.execute(meta.flow_index_ref);
            meta.psw_d = rPSwD_2_action.execute(meta.flow_index_ref);
        }
        meta.is_reset = rTWindow_action.execute(meta.flow_index);
        meta.pkts_n = rNpkts_action.execute(meta.flow_index);
    }

    if (meta.TSlastComp != 0) {
        ingress_dt_table.apply(hdr, meta, ig_intr_dprsr_md, ig_tm_md);
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
