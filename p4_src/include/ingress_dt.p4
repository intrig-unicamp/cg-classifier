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

//============================================================================
// Ingress dt table
//============================================================================

control IngressDtTable(inout header_t hdr,
        inout ingress_metadata_t meta) {

    bit<16> ig_ul_psw_1_var = 0;
    bit<16> ig_ul_psw_2_var = 0;
    bit<16> ig_ul_psw_3_var = 0;
    bit<16> ig_ul_psw_4_var = 0;
    bit<16> ig_ul_psw_5_var = 0;
    bit<16> ig_ul_ipgw_1_var = 0;
    bit<16> ig_ul_ipgw_2_var = 0;
    bit<16> ig_dl_psw_1_var = 0;
    bit<16> ig_dl_psw_2_var = 0;
    bit<16> ig_dl_psw_3_var = 0;
    bit<16> ig_dl_ipgw_1_var = 0;
    bit<16> ig_dl_ipgw_2_var = 0;
    bit<16> ig_dl_ipgw_3_var = 0;
    bit<16> ig_dl_ipgw_4_var = 0;
    bit<16> ig_cg_c1;
    bit<16> ig_cg_c2;
    bit<16> ig_cg_c3;
    bit<16> ig_cg_c4;
    bit<16> ig_cg_c5;
    bit<16> ig_cg_c6;
    bit<16> ig_cg_c7;

    /*************************************/
    /* uplink packet size moving average */
    /*************************************/
    action ig_ul_psw_1(bit<16> val) {
        ig_ul_psw_1_var = val;
    }

    action ig_ul_psw_1_def() {
        ig_ul_psw_1_var = 8;
    }

    table ig_ul_psw_table_1 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_ul_psw_1;
            @defaultonly ig_ul_psw_1_def;
        }
        default_action = ig_ul_psw_1_def;
        size = 200;
    }

    action ig_ul_psw_2(bit<16> val) {
        ig_ul_psw_2_var = val;
    }

    action ig_ul_psw_2_def() {
        ig_ul_psw_2_var = 8;
    }

    table ig_ul_psw_table_2 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_ul_psw_2;
            @defaultonly ig_ul_psw_2_def;
        }
        default_action = ig_ul_psw_2_def;
        size = 100;
    }

    action ig_ul_psw_3(bit<16> val) {
        ig_ul_psw_3_var = val;
        ig_cg_c3 = val + ig_ul_ipgw_2_var;
    }

    action ig_ul_psw_3_def() {
        ig_ul_psw_3_var = 8;
        ig_cg_c3 = 8 + ig_ul_ipgw_2_var;
    }

    table ig_ul_psw_table_3 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_ul_psw_3;
            @defaultonly ig_ul_psw_3_def;
        }
        default_action = ig_ul_psw_3_def;
        size = 500;
    }

    action ig_ul_psw_4(bit<16> val) {
        ig_ul_psw_4_var = val;
    }

    action ig_ul_psw_4_def() {
        ig_ul_psw_4_var = 8;
    }

    table ig_ul_psw_table_4 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_ul_psw_4;
            @defaultonly ig_ul_psw_4_def;
        }
        default_action = ig_ul_psw_4_def;
        size = 100;
    }

    action ig_ul_psw_5(bit<16> val) {
        ig_ul_psw_5_var = val;
    }

    action ig_ul_psw_5_def() {
        ig_ul_psw_5_var = 8;
    }

    table ig_ul_psw_table_5 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_ul_psw_5;
            @defaultonly ig_ul_psw_5_def;
        }
        default_action = ig_ul_psw_5_def;
        size = 100;
    }

    /*************************************/
    /* uplink ipg moving average */
    /*************************************/
    action ig_ul_ipgw_1(bit<16> val) {
        ig_ul_ipgw_1_var = val;
    }

    action ig_ul_ipgw_1_def() {
        ig_ul_ipgw_1_var = 8;
    }

    table ig_ul_ipgw_table_1 {
        key = {
            meta.hash_meta.ipgw_u  : exact;
        }
        actions = {
            ig_ul_ipgw_1;
            @defaultonly ig_ul_ipgw_1_def;
        }
        default_action = ig_ul_ipgw_1_def;
        size = 15000;
    }

    action ig_ul_ipgw_2(bit<16> val) {
        ig_ul_ipgw_2_var = val;
    }

    action ig_ul_ipgw_2_def() {
        ig_ul_ipgw_2_var = 8;
    }

    table ig_ul_ipgw_table_2 {
        key = {
            meta.hash_meta.ipgw_u  : exact;
        }
        actions = {
            ig_ul_ipgw_2;
            @defaultonly ig_ul_ipgw_2_def;
        }
        default_action = ig_ul_ipgw_2_def;
        size = 15000;
    }

    /*******************************/
    /* downlink ipg moving average */
    /*******************************/
    action ig_dl_ipgw_1(bit<16> val) {
        ig_dl_ipgw_1_var = val;
        ig_cg_c1 = val + ig_ul_psw_1_var;
        ig_cg_c2 = val + ig_ul_psw_2_var;
    }

    action ig_dl_ipgw_1_def() {
        ig_dl_ipgw_1_var = 8;
        ig_cg_c1 = 8 + ig_ul_psw_1_var;
        ig_cg_c2 = 8 + ig_ul_psw_2_var;
    }

    table ig_dl_ipgw_table_1 {
        key = {
            meta.hash_meta.ipgw_d  : exact;
        }
        actions = {
            ig_dl_ipgw_1;
            @defaultonly ig_dl_ipgw_1_def;
        }
        default_action = ig_dl_ipgw_1_def;
        size = 2200;
    }

    action ig_dl_ipgw_2(bit<16> val) {
        ig_dl_ipgw_2_var = val;
    }

    action ig_dl_ipgw_2_def() {
        ig_dl_ipgw_2_var = 8;
    }

    table ig_dl_ipgw_table_2 {
        key = {
            meta.hash_meta.ipgw_d  : exact;
        }
        actions = {
            ig_dl_ipgw_2;
            @defaultonly ig_dl_ipgw_2_def;
        }
        default_action = ig_dl_ipgw_2_def;
        size = 10000;
    }

    action ig_dl_ipgw_3(bit<16> val) {
        ig_dl_ipgw_3_var = val;
        ig_cg_c4 = val + ig_ul_psw_4_var;
    }

    action ig_dl_ipgw_3_def() {
        ig_dl_ipgw_3_var = 8;
        ig_cg_c4 = 8 + ig_ul_psw_4_var;
    }

    table ig_dl_ipgw_table_3 {
        key = {
            meta.hash_meta.ipgw_d  : exact;
        }
        actions = {
            ig_dl_ipgw_3;
            @defaultonly ig_dl_ipgw_3_def;
        }
        default_action = ig_dl_ipgw_3_def;
        size = 1500;
    }

    action ig_dl_ipgw_4(bit<16> val) {
        ig_dl_ipgw_4_var = val;
        ig_cg_c5 = ig_dl_psw_3_var + val;
        ig_cg_c6 = ig_cg_c3 + ig_cg_c4;
    }

    action ig_dl_ipgw_4_def() {
        ig_dl_ipgw_4_var = 8;
        ig_cg_c5 = ig_dl_psw_3_var + 8;
        ig_cg_c6 = ig_cg_c3 + ig_cg_c4;
    }

    table ig_dl_ipgw_table_4 {
        key = {
            meta.hash_meta.ipgw_d  : exact;
        }
        actions = {
            ig_dl_ipgw_4;
            @defaultonly ig_dl_ipgw_4_def;
        }
        default_action = ig_dl_ipgw_4_def;
        size = 3200;
    }

    /***************************************/
    /* downlink packet size moving average */
    /***************************************/
    action ig_dl_psw_1(bit<16> val) {
        ig_dl_psw_1_var = val;
        ig_cg_c7 = ig_cg_c5 + ig_cg_c6;
    }

    action ig_dl_psw_1_def() {
        ig_dl_psw_1_var = 8;
        ig_cg_c7 = ig_cg_c5 + ig_cg_c6;
    }

    table ig_dl_psw_table_1 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_dl_psw_1;
            @defaultonly ig_dl_psw_1_def;
        }
        default_action = ig_dl_psw_1_def;
        size = 1000;
    }

    action ig_dl_psw_2(bit<16> val) {
        ig_dl_psw_2_var = val;
        meta.hash_meta.cg_c1 = ig_cg_c1 + ig_dl_psw_1_var;
        meta.hash_meta.cg_c2 = ig_cg_c1 + ig_ul_ipgw_1_var;
        meta.hash_meta.cg_c3 = ig_cg_c2 + ig_dl_psw_2_var;
    }

    action ig_dl_psw_2_def() {
        ig_dl_psw_2_var = 8;
        meta.hash_meta.cg_c1 = ig_cg_c1 + ig_dl_psw_1_var;
        meta.hash_meta.cg_c2 = ig_cg_c1 + ig_ul_ipgw_1_var;
        meta.hash_meta.cg_c3 = ig_cg_c2 + ig_dl_psw_2_var;
    }

    table ig_dl_psw_table_2 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_dl_psw_2;
            @defaultonly ig_dl_psw_2_def;
        }
        default_action = ig_dl_psw_2_def;
        size = 1000;
    }

    action ig_dl_psw_3(bit<16> val) {
        ig_dl_psw_3_var = val;
        meta.hash_meta.cg_c4 = ig_cg_c6 + ig_dl_psw_3_var;
        meta.hash_meta.cg_c5 = ig_cg_c7 + ig_ul_psw_5_var;
        meta.hash_meta.cg_c6 = ig_ul_psw_3_var + ig_dl_ipgw_2_var;
    }

    action ig_dl_psw_3_def() {
        ig_dl_psw_3_var = 8;
        meta.hash_meta.cg_c4 = ig_cg_c6 + ig_dl_psw_3_var;
        meta.hash_meta.cg_c5 = ig_cg_c7 + ig_ul_psw_5_var;
        meta.hash_meta.cg_c6 = ig_ul_psw_3_var + ig_dl_ipgw_2_var;
    }

    table ig_dl_psw_table_3 {
        key = {
            meta.hash_meta.psw_u  : exact;
        }
        actions = {
            ig_dl_psw_3;
            @defaultonly ig_dl_psw_3_def;
        }
        default_action = ig_dl_psw_3_def;
        size = 1200;
    }

    /**********************************/
    /******* detect cg ****************/
    /**********************************/

    action ig_is_cg() {
        meta.hash_meta.is_cg = true;
    }

    table ig_is_cg_table {
        key = {
            meta.hash_meta.cg_c1  : exact;
            meta.hash_meta.cg_c2  : exact;
            meta.hash_meta.cg_c3  : exact;
            meta.hash_meta.cg_c4  : exact;
            meta.hash_meta.cg_c5  : exact;
            meta.hash_meta.cg_c6  : exact;
        }
        actions = {
            ig_is_cg;
        }
        size = 100;
    }

    apply {
        /*********Uplink *********/
        ig_ul_psw_table_1.apply();
        ig_ul_psw_table_2.apply();
        ig_ul_psw_table_3.apply();
        ig_ul_psw_table_4.apply();
        ig_ul_psw_table_5.apply();

        ig_ul_ipgw_table_1.apply();
        ig_ul_ipgw_table_2.apply();

        /*********Downlink ********/
        ig_dl_ipgw_table_1.apply();
        ig_dl_ipgw_table_2.apply();
        ig_dl_ipgw_table_3.apply();
        ig_dl_ipgw_table_4.apply();

        ig_dl_psw_table_1.apply();
        ig_dl_psw_table_2.apply();
        ig_dl_psw_table_3.apply();

        ig_is_cg_table.apply();
    }
}
