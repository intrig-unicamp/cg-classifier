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
import matplotlib.pyplot as plt
import ipaddress
import numpy as np
import pandas as pd
import time

from utils import ip2long

hashA =        [62,   72,   88,   92,   102,  104,  106,  107,  109,  113,
                127,  131,  137,  139,  149,  151,  157,  163,  167,  173,
                179,  181,  191,  193,  197,  199,  211,  223,  227,  229]

hashB =        [73,   3079, 617,  619,  631,  641,  643,  647,  653,  659,
                661,  673,  677,  683,  691,  701,  709,  719,  727,  733,
                739,  743,  751,  757,  761,  769,  773,  787,  797,  809]

class CG_Threshold_Cal:

    def __init__(self, filename, memory):
        self.m = memory
        self.flow_tables = [[[] for _ in range(7)] for _ in range(memory)]

        with open(filename, 'r') as f:
            for line in f:
                fields = line.split(',')
                ipSrc  = fields[0]
                if len(fields) != 9 or not ipSrc:
                    continue

                ipSrc = fields[0]
                ipDst = fields[1]

                ipsource, ipdest = self.ip2IntCovertor(ipSrc, ipDst)
                flow_id = ipsource + (ipsource + ipdest)
                flow_id_ref = ipdest + (ipsource + ipdest)

                tsc = float(fields[8])*1000000
                ts_c = int(tsc)

                dtls_length = fields[7]
                if dtls_length == "":
                    dtls_length = 0

                packet_size = fields[5]

                self.cloudGamingThresholdCal(flow_id, flow_id_ref, ts_c, packet_size, dtls_length)

    def flowIdHash(self, flowId, stage):
        return (hashA[stage] * flowId + hashB[stage]) % self.m

    def isIPv4(self, s):
        try: return str(int(s)) == s and 0 <= int(s) <= 255
        except: return False

    def ip2IntCovertor(self, ipSrc, ipDst):
        if ipSrc.count(".") == 3 and all(self.isIPv4(i) for i in ipSrc.split(".")):
            ipsource  = ip2long(ipSrc)
            ipdest    = ip2long(ipDst)
        else:
            # Convert IPv6 to 64 bits address just for simplicty
            ipsource  = int(ipaddress.ip_address(ipSrc)) >> 64
            ipdest    = int(ipaddress.ip_address(ipDst)) >> 64

        return ipsource, ipdest

    def cloudGamingThresholdCal(self, flow_id, flow_id_ref, ts_c, packet_size, dtls_length):

        table_slot = self.flowIdHash(flow_id, 10)
        table_flow_id, _, ts_last, _, pkts, dtls_length_last, table_flow_id_ref  = self.flow_tables[table_slot]

        if len(table_flow_id) == 0:

            ##### Insert new entry #######
            self.flow_tables[table_slot] = [flow_id], _, [ts_c], [int(packet_size)], [1], [int(dtls_length)], [flow_id_ref]
            return None

        elif table_flow_id[0] == flow_id and table_flow_id_ref[0] == flow_id_ref:

            ###### Update the entry ##########
            ipg_c = ts_c - ts_last[0]

            self.flow_tables[table_slot][1].append(ipg_c)
            self.flow_tables[table_slot][2][0] = ts_c
            self.flow_tables[table_slot][3].append(int(packet_size))
            self.flow_tables[table_slot][4][0] = pkts[0] + 1
            self.flow_tables[table_slot][5][0] = dtls_length_last[0] + int(dtls_length)

            return None

        else:
            return None

    def getFeatureThresholds(self):

        list_dir1 = []
        list_dir2 = []

        for i in range(0, self.m):
            if len(self.flow_tables[i][0]) != 0:
                for j in range(i + 1, self.m):

                    df_np = self.flow_tables[i][4]
                    if df_np[0] <= 500:
                        continue

                    if self.flow_tables[i][6] == self.flow_tables[j][0]:

                        # For one direction
                        df_ipg_dir1 = self.flow_tables[i][1]
                        df_ps_dir1 = self.flow_tables[i][3]

                        df_np_dir1 = self.flow_tables[i][4]
                        df_dtls_len_dir1 = self.flow_tables[i][5]
                        # df_ipg_dir1_m = sum(df_ipg_dir1) / len(df_ipg_dir1)
                        df_ipg_dir1_q = np.quantile(df_ipg_dir1, [0.25, 0.75])
                        df_ps_dir1_q = np.quantile(df_ps_dir1, [0.25, 0.75])

                        list_dir1 = [df_ipg_dir1_q[0], df_ipg_dir1_q[1], df_ps_dir1_q[0], df_ps_dir1_q[1], df_np_dir1[0], df_dtls_len_dir1[0]]

                        # For other direction
                        df_ipg_dir2 = self.flow_tables[j][1]
                        df_ps_dir2 = self.flow_tables[j][3]

                        df_np_dir2 = self.flow_tables[j][4]
                        df_dtls_len_dir2 = self.flow_tables[j][5]
                        # df_ipg_dir2_m = sum(df_ipg_dir2) / len(df_ipg_dir2)
                        df_ipg_dir2_q = np.quantile(df_ipg_dir2, [0.25, 0.75])
                        df_ps_dir2_q = np.quantile(df_ps_dir2, [0.25, 0.75])

                        list_dir2 = [df_ipg_dir2_q[0], df_ipg_dir2_q[1], df_ps_dir2_q[0], df_ps_dir2_q[1], df_np_dir2[0], df_dtls_len_dir2[0]]

        return list_dir1, list_dir2
