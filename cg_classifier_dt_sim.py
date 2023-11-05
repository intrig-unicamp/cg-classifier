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

from utils import ip2long
from zlib import crc32
import ipaddress
import re

import numpy as np
import pandas as pd

CG_IPG_TH_DN = 4600
CG_IPG_TH_UP = 50000

MAC_SRC_1 = 124230040217970
MAC_SRC_2 = 57344564322886
MAC_DST_1 = 176156463118100
MAC_DST_2 = 18121622349927

hashA = [62,   72,   88,   92,   102,  104,  106,  107,  109,  113,
        127,  131,  137,  139,  149,  151,  157,  163,  167,  173,
        179,  181,  191,  193,  197,  199,  211,  223,  227,  229]

hashB = [73,   3079, 617,  619,  631,  641,  643,  647,  653,  659,
        661,  673,  677,  683,  691,  701,  709,  719,  727,  733,
        739,  743,  751,  757,  761,  769,  773,  787,  797,  809]

class CG_Classifier:

    def __init__(self, filename, memory, window_size, weighting_decrease, cg):
        self.cg_count = 0
        self.cg_count_true = 0
        self.non_cg_count = 0
        self.non_cg_count_true = 0
        self.m = memory
        self.flow_tables = np.zeros((1, memory), dtype=(np.int64, 9))

        self.time_duration = 0

        with open(filename, 'r') as f:
            for line in f:
                fields = line.split(',')

                ip6Src     = fields[2]
                ip6Dst     = fields[3]
                ip4Src     = fields[5]
                ip4Dst     = fields[6]

                if not ip6Src and not ip6Dst:
                   ipSrc = ip4Src
                   ipDst = ip4Dst
                else:
                   ipSrc = ip6Src
                   ipDst = ip6Dst

                if len(fields) != 14 or not ipSrc or not ipDst:
                    continue

                if self.validate_ip_address(ipSrc) == False or self.validate_ip_address(ipDst) == False:
                    continue

                ipsource, ipdest = self.ip2IntCovertor(ipSrc, ipDst)
                flow_id = ipsource + (ipsource + ipdest)

                flow_id_ref = ipdest + (ipsource + ipdest)

                ts_c = float(fields[13])*1000000
                ts_c = int(ts_c)

                packet_size = fields[10]

                if self.isMacValid(fields[0]) == False or self.isMacValid(fields[1]) == False:
                    continue

                mac_s = self.macToInt(fields[0])
                mac_d = self.macToInt(fields[1])

                self.cloudGamingClassifier(flow_id, flow_id_ref, ts_c, packet_size, window_size, weighting_decrease,
                                           mac_s, mac_d, cg)

    def flowIdHash(self, flowId, stage):
        return (hashA[stage] * flowId + hashB[stage]) % self.m

    def isMacValid(self, mac):
        res = re.match('^((?:(?:[0-9a-f]{2}):){5}[0-9a-f]{2})$', mac.lower())
        if res is None:
            return False
        return True

    def macToInt(self, mac):
        res = re.match('^((?:(?:[0-9a-f]{2}):){5}[0-9a-f]{2})$', mac.lower())
        if res is None:
            raise ValueError('invalid mac address')
        return int(res.group(0).replace(':', ''), 16)

    def isIPv4(self, s):
        try: return str(int(s)) == s and 0 <= int(s) <= 255
        except: return False

    def validate_ip_address(self, ip_string):
        try:
            ipaddress.ip_address(ip_string)
            return True
        except ValueError:
            return False

    def ip2IntCovertor(self, ipSrc, ipDst):
        if ipSrc.count(".") == 3 and all(self.isIPv4(i) for i in ipSrc.split(".")):
            ipsource  = ip2long(ipSrc)
            ipdest    = ip2long(ipDst)
        else:
            # Convert IPv6 to 80 bits address just for simplicity
            ipsource  = int(ipaddress.ip_address(ipSrc)) >> 80
            ipdest    = int(ipaddress.ip_address(ipDst)) >> 80

        return ipsource, ipdest

    def crc32Hash(self, flowId):
        s1 = 'aaa'
        flowId = str(flowId) + s1
        return ((crc32(flowId) % (1<<32)) % self.m)

    def getPrcntDiff(self, uplink_val, downlink_val):
        if uplink_val == downlink_val:
            return 0
        try:
            return (abs(uplink_val - downlink_val) / ((uplink_val + downlink_val) / 2)) * 100.0
        except ZeroDivisionError:
            return 0

    def cloudGamingClassifier(self, flow_id, flow_id_ref, ts_c, packet_size, window_size, weighting_decrease, mac_s, mac_d, cg):
        # Convert in micro-seconds
        window_size = int(window_size) * 1000000

        if self.time_duration == 0:
            self.time_duration = ts_c

        table_slot = self.flowIdHash(flow_id, 10)
        table_flow_id, ipg_w, _, ts_last, ps_w, pkt_n, table_flow_id_ref, _, _  = self.flow_tables[0][table_slot]

        if (ts_c - self.time_duration > window_size):
            list_loc = []
            for i in range(0, self.m):
                cg_true = 0

                table_flow_id_t, ipg_w_t, ipg_w_t_last, _, ps_w_t, pkt_n_t, table_flow_id_ref_t, mac_s_t, mac_d_t = self.flow_tables[0][i]

                table_slot_ref_t = self.flowIdHash(table_flow_id_ref_t, 10)
                table_flow_id_ref_t, ipg_w_ref_t, ipg_w_ref_t_last, _, ps_w_ref_t, pkt_n_ref_t, _, _, _  = self.flow_tables[0][table_slot_ref_t]

                if table_flow_id_t == 0:
                    continue

                if (table_flow_id_t + table_flow_id_ref_t) in list_loc:
                    continue

                if pkt_n_t < 5:
                    continue

                if pkt_n_ref_t < 5:
                    continue

                if (mac_s_t == MAC_SRC_1 or mac_s_t == MAC_SRC_2 or mac_d_t == MAC_DST_1 or mac_d_t == MAC_DST_2):
                    # ipg_w_t denotes DL
                    if pkt_n_ref_t <= 61.5:
                        if ipg_w_t <= 2180:
                            if ps_w_ref_t <= 178:
                                if ps_w_t <= 909:
                                    cg_true = 1
                            else:
                                if ipg_w_ref_t <= 172066:
                                    cg_true = 1
                        else:
                            if ps_w_ref_t <= 64:
                                if ps_w_t <= 812:
                                    cg_true = 1
                    else:
                        if ps_w_ref_t <= 418:
                            if ipg_w_ref_t <= 17416:
                                if ipg_w_t <= 9361:
                                    if ps_w_ref_t > 63:
                                        if ps_w_t <= 1150:
                                            cg_true = 1
                                        else:
                                            if ipg_w_t <= 1288:
                                                if ps_w_ref_t > 100:
                                                    cg_true = 1
                            else:
                                if ipg_w_t <= 3198:
                                    cg_true = 1

                else:
                    # ipg_w_t denotes DN
                    if pkt_n_t <= 61.5:
                        if ipg_w_ref_t <= 2180:
                            if ps_w_t <= 178:
                                if ps_w_ref_t <= 909:
                                    cg_true = 1
                            else:
                                if ipg_w_t <= 172066:
                                    cg_true = 1
                        else:
                            if ps_w_t <= 64:
                                if ps_w_ref_t <= 812:
                                    cg_true = 1
                    else:
                        if ps_w_t <= 418:
                            if ipg_w_t <= 17416:
                                if ipg_w_ref_t <= 9361:
                                    if ps_w_t > 63:
                                        if ps_w_ref_t <= 1150:
                                            cg_true = 1
                                        else:
                                            if ipg_w_ref_t <= 1288:
                                                if ps_w_t > 100:
                                                    cg_true = 1
                            else:
                                if ipg_w_ref_t <= 3198:
                                    cg_true = 1

                if cg_true == 1:
                    self.cg_count += 1
                else:
                    self.non_cg_count += 1

                list_loc.append(table_flow_id_t + table_flow_id_ref_t)

                if cg is str(True):
                    self.cg_count_true += 1
                else:
                    self.non_cg_count_true += 1

                self.flow_tables[0][i][2] = self.flow_tables[0][i][1]
                self.flow_tables[0][table_slot_ref_t][2] = self.flow_tables[0][table_slot_ref_t][1]

                self.flow_tables[0][i][5] = 0
                self.flow_tables[0][table_slot_ref_t][5] = 0

            self.time_duration = 0

            return None

        #### Case I
        if table_flow_id == flow_id and table_flow_id_ref == flow_id_ref:

            ###### Update the entry ##########
            ipg_c = ts_c - ts_last

            ipg_w = (int(weighting_decrease) * ipg_w + (100-int(weighting_decrease)) * ipg_c)/100
            ps_w = (int(weighting_decrease) * ps_w + (100-int(weighting_decrease)) * int(packet_size))/100

            self.flow_tables[0][table_slot][1] = ipg_w
            self.flow_tables[0][table_slot][3] = ts_c
            self.flow_tables[0][table_slot][4] = ps_w
            self.flow_tables[0][table_slot][5] = pkt_n + 1

            return None

        # Case II
        elif table_flow_id == 0:

            # Insert new entry
            if (mac_s == MAC_SRC_1 or mac_s == MAC_SRC_2 or mac_d == MAC_DST_1 or mac_d == MAC_DST_2):
                self.flow_tables[0][table_slot] = flow_id, CG_IPG_TH_DN, CG_IPG_TH_UP, ts_c, int(packet_size), 1, flow_id_ref, mac_s, mac_d
            else:
                self.flow_tables[0][table_slot] = flow_id, CG_IPG_TH_UP, CG_IPG_TH_UP, ts_c, int(packet_size), 1, flow_id_ref, mac_s, mac_d
            return None

        else:
            return None

    def getCgResult(self):
        true_prediction = (self.cg_count / self.cg_count_true) * 100
        wrong_prediction = 100 - true_prediction

        return (true_prediction, wrong_prediction)

    def getNonCgResult(self):
        true_prediction = (self.non_cg_count / self.non_cg_count_true) * 100
        wrong_prediction = 100 - true_prediction

        return (true_prediction, wrong_prediction)
