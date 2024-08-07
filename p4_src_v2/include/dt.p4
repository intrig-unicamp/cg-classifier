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

#include "standard_headers.p4"

//=============================================================================
// Ingress dt table
//=============================================================================

control IngressDtTable(inout header_t hdr,
        inout ingress_metadata_t meta,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_tm_md) {

    Register <bit<8>, _> (32w16384) rIsCG;
    bit<3> code_ul_psw = 0;
    bit<3> code_ul_ipgw = 0;
    bit<3> code_ul_pkts = 0;
    bit<3> code_dl_psw = 0;
    bit<3> code_dl_ipgw = 0;
    bit<16> cg_code = 0;

    RegisterAction<bit<8>, rSize, bit<8>>(rIsCG) rIsCG_action = {
            void apply(inout bit<8> value, out bit<8> readvalue){
                if (meta.is_cg) {
                    value = 1;
                } else if (meta.is_non_cg) {
                    value = 0;
                }
                readvalue = value;
        }
    };

    action drop(){
        ig_intr_dprsr_md.drop_ctl = 0x1;
    }

    /*************************************/
    /* uplink packet size moving average */
    /*************************************/
    action ul_psw(bit<3> code) {
        code_ul_psw = code;
    }

    table ul_psw_table {
        key = {
            meta.psw_u  : range;
        }
        actions = {
            ul_psw;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    /*************************************/
    /* uplink ipg moving average */
    /*************************************/
    action ul_ipgw(bit<3> code) {
        code_ul_ipgw = code;
    }

    table ul_ipgw_table {
        key = {
            meta.ipgw_u  : range;
        }
        actions = {
            ul_ipgw;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    /*************************************/
    /* uplink number of packets */
    /*************************************/
    action ul_pkts(bit<3> code) {
        code_ul_pkts = code;
    }

    table ul_pkts_table {
        key = {
            meta.pkts_n : range;
        }
        actions = {
            ul_pkts;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    /***************************************/
    /* downlink packet size moving average */
    /***************************************/
    action dl_psw(bit<3> code) {
        code_dl_psw = code;
    }

    table dl_psw_table {
        key = {
            meta.psw_d  : range;
        }
        actions = {
            dl_psw;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    /*******************************/
    /* Downlink IPG moving average */
    /*******************************/
    action dl_ipgw(bit<3> code) {
        code_dl_ipgw = code;
    }

    table dl_ipgw_table {
        key = {
            meta.ipgw_d  : range;
        }
        actions = {
            dl_ipgw;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    /**********************************/
    /******* Detect CG ****************/
    /**********************************/
    action is_cg() {
        meta.is_cg = true;
    }

    table is_cg_table {
        key = {
            cg_code  : exact;
            meta.is_reset : exact;
            meta.pkts_n : range;
        }
        actions = {
            is_cg;
        }
        size = 1024;
    }

    action is_non_cg() {
        meta.is_non_cg = true;
    }

    table is_non_cg_table {
        key = {
            meta.is_reset : exact;
            meta.pkts_n : range;
        }
        actions = {
            is_non_cg;
            /* For testing only */
            @defaultonly drop;
        }
        const default_action = drop;
        size = 1024;
    }

    action set_code() {
        cg_code[2:0] = code_ul_psw;
        cg_code[5:3] = code_ul_ipgw;
        cg_code[8:6] = code_ul_pkts;
        cg_code[11:9] = code_dl_psw;
        cg_code[14:12] = code_dl_ipgw;
    }

    apply {
        /***** Uplink *******/
        ul_psw_table.apply();
        ul_ipgw_table.apply();
        ul_pkts_table.apply();

        /***** Downlink *****/
        dl_ipgw_table.apply();
        dl_psw_table.apply();

        set_code();
        is_cg_table.apply();

        if (meta.is_cg == false) {
            is_non_cg_table.apply();
        }

        meta.r_is_cg = rIsCG_action.execute(meta.flow_index);

        if (meta.r_is_cg == 1) {
            ig_tm_md.ucast_egress_port = 129;
        } else {
            ig_tm_md.ucast_egress_port = 128;
        }
    }
}
