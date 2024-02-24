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
        inout ingress_metadata_t meta) {

    bit<16> sum_code = 0;

    /*************************************/
    /* uplink packet size moving average */
    /*************************************/
    action ul_psw(bit<16> code) {
        sum_code = sum_code + code;
    }

    table ul_psw_table {
        key = {
            meta.hash_meta.psw_u  : range;
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
    action ul_ipgw(bit<16> code) {
        sum_code = sum_code + code;
    }

    table ul_ipgw_table {
        key = {
            meta.hash_meta.ipgw_u  : range;
        }
        actions = {
            ul_ipgw;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    /***************************************/
    /* downlink packet size moving average */
    /***************************************/
    action dl_psw(bit<16> code) {
        sum_code = sum_code + code;
    }

    table dl_psw_table {
        key = {
            meta.hash_meta.psw_d  : range;
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
    action dl_ipgw(bit<16> code) {
        sum_code = sum_code + code;
    }

    table dl_ipgw_table {
        key = {
            meta.hash_meta.ipgw_d  : range;
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
        meta.hash_meta.is_cg = true;
    }

    table is_cg_table {
        key = {
            sum_code  : exact;
        }
        actions = {
            is_cg;
            @defaultonly NoAction;
        }
        const default_action = NoAction;
        size = 1024;
    }

    apply {
        /***** Uplink *******/
        ul_psw_table.apply();
        ul_ipgw_table.apply();

        /***** Downlink *****/
        dl_ipgw_table.apply();
        dl_psw_table.apply();

        is_cg_table.apply();
    }
}
