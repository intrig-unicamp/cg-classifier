 ################################################################################
 # Copyright 2024 INTRIG
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

from ipaddress import ip_address

p4 = bfrt.cg_classifier_dt.pipe

# This function is taken from barefoot
# This function can clear all the tables and later on other fixed objects
# once bfrt support is added.
# This function can clear all the tables and later on other fixed objects
# once bfrt support is added.
def clear_all_tables(verbose=True, batching=True):
    global p4
    global bfrt

    # The order is important. We do want to clear from the top, i.e.
    # delete objects that use other objects, e.g. table entries use
    # selector groups and selector groups use action profile members

    for table_types in (['MATCH_DIRECT', 'MATCH_INDIRECT_SELECTOR'],
                        ['SELECTOR'],
                        ['ACTION_PROFILE']):
        for table in p4.info(return_info=True, print_info=False):
            if table['type'] in table_types:
                if verbose:
                    print("Clearing table {:<40} ... ".
                          format(table['full_name']), end='', flush=True)
                table['node'].clear(batch=batching)
                if verbose:
                    print('Done')
clear_all_tables()

ul_psw_ = [4020, 5020, 5921, 2020, 2998]
ul_ipgw_ = [2145, 3145]
ul_pkts_ = [24468, 9878]
dl_psw_ = [3189, 2189, 4189, 8899]
dl_ipgw_ = [4215, 1215, 2215, 3215, 3712]

################################################
# Populate uplink weighted packet size tables
################################################

p4.SwitchIngress.ingress_dt_table.ul_psw_table.add_with_ul_psw(
    psw_u_start=0, psw_u_end=65, code=4020)

p4.SwitchIngress.ingress_dt_table.ul_psw_table.add_with_ul_psw(
    psw_u_start=66, psw_u_end=100, code=5020)

p4.SwitchIngress.ingress_dt_table.ul_psw_table.add_with_ul_psw(
    psw_u_start=101, psw_u_end=178, code=5921)

p4.SwitchIngress.ingress_dt_table.ul_psw_table.add_with_ul_psw(
    psw_u_start=179, psw_u_end=418, code=2020)

p4.SwitchIngress.ingress_dt_table.ul_psw_table.add_with_ul_psw(
    psw_u_start=419, psw_u_end=65535, code=2998)

########################################
# Populate uplink weighted IPG tables
########################################

p4.SwitchIngress.ingress_dt_table.ul_ipgw_table.add_with_ul_ipgw(
    ipgw_u_start=0, ipgw_u_end=17416, code=2145)

p4.SwitchIngress.ingress_dt_table.ul_ipgw_table.add_with_ul_ipgw(
    ipgw_u_start=17417, ipgw_u_end=65535, code=3145)

########################################
# Populate uplink pkt count tables
########################################

p4.SwitchIngress.ingress_dt_table.ul_pkts_table.add_with_ul_pkts(
    pkts_n_start=15, pkts_n_end=62, code=24468)

p4.SwitchIngress.ingress_dt_table.ul_pkts_table.add_with_ul_pkts(
    pkts_n_start=63, pkts_n_end=50000, code=9878)

################################################
# Populate downlink weighted packet size tables
################################################

p4.SwitchIngress.ingress_dt_table.dl_psw_table.add_with_dl_psw(
    psw_d_start=0, psw_d_end=812, code=3189)

p4.SwitchIngress.ingress_dt_table.dl_psw_table.add_with_dl_psw(
    psw_d_start=813, psw_d_end=909, code=2189)

p4.SwitchIngress.ingress_dt_table.dl_psw_table.add_with_dl_psw(
    psw_d_start=910, psw_d_end=1150, code=4189)

p4.SwitchIngress.ingress_dt_table.dl_psw_table.add_with_dl_psw(
    psw_d_start=1151, psw_d_end=65535, code=8899)

########################################
# Populate downlink weighted IPG tables
########################################

p4.SwitchIngress.ingress_dt_table.dl_ipgw_table.add_with_dl_ipgw(
    ipgw_d_start=0, ipgw_d_end=1288, code=4215)

p4.SwitchIngress.ingress_dt_table.dl_ipgw_table.add_with_dl_ipgw(
    ipgw_d_start=1289, ipgw_d_end=2180, code=1215)

p4.SwitchIngress.ingress_dt_table.dl_ipgw_table.add_with_dl_ipgw(
    ipgw_d_start=2181, ipgw_d_end=3198, code=2215)

p4.SwitchIngress.ingress_dt_table.dl_ipgw_table.add_with_dl_ipgw(
    ipgw_d_start=3199, ipgw_d_end=9361, code=3215)

p4.SwitchIngress.ingress_dt_table.dl_ipgw_table.add_with_dl_ipgw(
    ipgw_d_start=9362, ipgw_d_end=65535, code=3712)


############################
# Populate decision tables
############################

p4.SwitchIngress.ingress_dt_table.is_non_cg_table.add_with_is_non_cg(is_reset=1, pkts_n_start=6, pkts_n_end=65535)

sum_code_ = []

for dl_ipgw in range(2, 5):
    for ul_ipg in range(0, 2):
        sum = ul_pkts_[0] + dl_ipgw_[dl_ipgw] + ul_psw_[0] + dl_psw_[0] + ul_ipgw_[ul_ipg]
        if sum in sum_code_:
            continue
        else:
            p4.SwitchIngress.ingress_dt_table.is_cg_table.add_with_is_cg(sum_code=sum, is_reset=1, pkts_n_start=6, pkts_n_end=65535)
            sum_code_.append(sum)

for dl_ipgw in range(0, 2):
    for ul_psw in range(0, 3):
        for dl_psw in range(0, 2):
            for ul_ipg in range(0, 2):
                sum = ul_pkts_[0] + dl_ipgw_[dl_ipgw] + ul_psw_[ul_psw] + dl_psw_[dl_psw] + ul_ipgw_[ul_ipg]
                if sum in sum_code_:
                    continue
                else:
                    p4.SwitchIngress.ingress_dt_table.is_cg_table.add_with_is_cg(sum_code=sum, is_reset=1, pkts_n_start=6, pkts_n_end=65535)
                    sum_code_.append(sum)

for dl_ipgw in range(0, 2):
    for ul_psw in range(3, 5):
        for ul_ipg in range(0, 2):
            for dl_psw in range(0, 4):
                sum = ul_pkts_[0] + dl_ipgw_[dl_ipgw] + ul_psw_[ul_psw] + ul_ipgw_[ul_ipg] + dl_psw_[dl_psw]
                if sum in sum_code_:
                    continue
                else:
                    p4.SwitchIngress.ingress_dt_table.is_cg_table.add_with_is_cg(sum_code=sum, is_reset=1, pkts_n_start=6, pkts_n_end=65535)
                    sum_code_.append(sum)

#######################
# 2nd half of the DT
#######################

for ul_ipg in range(0, 2):
        for dl_psw in range(0, 4):
            for dl_ipgw in range(0, 3):
                sum = ul_pkts_[1] + ul_psw_[4] + dl_ipgw_[dl_ipgw] + dl_psw_[dl_psw] + ul_ipgw_[ul_ipg]
                if sum in sum_code_:
                    continue
                else:
                    p4.SwitchIngress.ingress_dt_table.is_cg_table.add_with_is_cg(sum_code=sum, is_reset=1, pkts_n_start=6, pkts_n_end=65535)
                    sum_code_.append(sum)

for ul_psw in range(1, 4):
    for dl_psw in range(0, 3):
        for dl_ipgw in range(0, 4):
            sum = ul_pkts_[1] + ul_psw_[ul_psw] + ul_ipgw_[0] + dl_ipgw_[dl_ipgw] + dl_psw_[dl_psw]
            if sum in sum_code_:
                continue
            else:
                p4.SwitchIngress.ingress_dt_table.is_cg_table.add_with_is_cg(sum_code=sum, is_reset=1, pkts_n_start=6, pkts_n_end=65535)
                sum_code_.append(sum)

for ul_psw in range(2, 4):
    for dl_psw in range(0, 3):
        sum = ul_pkts_[1] + ul_psw_[ul_psw] + ul_ipgw_[0] + dl_ipgw_[0] + dl_psw_[3]
        if sum in sum_code_:
            continue
        else:
            p4.SwitchIngress.ingress_dt_table.is_cg_table.add_with_is_cg(sum_code=sum, is_reset=1, pkts_n_start=6, pkts_n_end=65535)
            sum_code_.append(sum)

# LPF_SPEC_TYPE: RATE or SAMPLE
# LPF_SPEC_GAIN_TIME_CONSTANT_NS (gain τ): Time Constant in nanoseconds
# LPF_SPEC_DECAY_TIME_CONSTANT_NS (decay τ): Time Constant in nanoseconds
# LPF_SPEC_OUT_SCALE_DOWN_FACTOR (N): output divided by 2**N
#
# RATE Mode:  LPF performs integration, meaning that it approximates the sum
#             of the values of the function x(t) over the time period, τ (known as Time Constant).
#             RATE uses only the "gain τ" and scale down factor.
#
#             ('RATE', 16000000, 16000000, 4) => An integrator with the time constant equal to 16ms and scaling factor 4.
#             If you feed packet bytes size to input, the lpf output will be approximately equal to the sum of the
#             packet size over the past 16 ms divided by 16, which is the data rate in bytes-per-millisecond.
#
# SAMPLE Mode:LPF approximates an EWMA of a function x(t).
#             This uses "gain τ", when x(t) > avg_previous i.e. signal gaining
#             and uses "decay τ", when x(t) < avg_previous i.e signal decay
#
#             ('SAMPLE', 1000000, 1000000, 0) => A filter with the time constant equal to 1 millisecond.
#             avg_next = ((1-alpha) * avg_previous) + (alpha * x(t_i))
#             avg_next = avg_previous + alpha * (x(t_i) - avg_previous)
#             alpha = (1- e**(-(T[i] - T[i-1])/τ))
#                   Where T[i]: is the time the current sample has arrived
#                         T[i-1]: is the time the previous sample has arrived
# spec_type = "SAMPLE"
# gain_time = float(1000000)
# decay_time = gain_time
# out_scale = 0


# TODO(suneet): Currently in the existing code, we do not use lpf to calculate EWMA
# because it might hard to fix the alpha value which can impact overall accurracy
# it is required to invesitgate further on that.
# for i in range(0, 16384):
#     p4.SwitchIngress.lpfIPGwU.add(LPF_INDEX=i, LPF_SPEC_TYPE=spec_type,
#             LPF_SPEC_GAIN_TIME_CONSTANT_NS=gain_time, LPF_SPEC_DECAY_TIME_CONSTANT_NS=decay_time)

# for i in range(0, 16384):
#     p4.SwitchIngress.lpfPSwU.add(LPF_INDEX=i, LPF_SPEC_TYPE=spec_type,
#             LPF_SPEC_GAIN_TIME_CONSTANT_NS=gain_time, LPF_SPEC_DECAY_TIME_CONSTANT_NS=decay_time)

# for i in range(0, 16384):
#     p4.SwitchIngress.lpfIPGwD.add(LPF_INDEX=i, LPF_SPEC_TYPE=spec_type,
#             LPF_SPEC_GAIN_TIME_CONSTANT_NS=gain_time, LPF_SPEC_DECAY_TIME_CONSTANT_NS=decay_time)

# for i in range(0, 16384):
#     p4.SwitchIngress.lpfPSwD.add(LPF_INDEX=i, LPF_SPEC_TYPE=spec_type,
#             LPF_SPEC_GAIN_TIME_CONSTANT_NS=gain_time, LPF_SPEC_DECAY_TIME_CONSTANT_NS=decay_time)

MAC_SRC_1 = "70:fc:8f:6a:e9:72"
MAC_SRC_2 = "34:27:92:62:e2:46"
MAC_DST_1 = "a0:36:9f:68:b7:14"
MAC_DST_2 = "10:7b:44:dc:e8:67"

p4.SwitchIngress.macs_table.add_with_set_sflag(srcAddr=MAC_SRC_1)
p4.SwitchIngress.macs_table.add_with_set_sflag(srcAddr=MAC_SRC_2)
p4.SwitchIngress.macd_table.add_with_set_dflag(dstAddr=MAC_DST_1)
p4.SwitchIngress.macd_table.add_with_set_dflag(dstAddr=MAC_DST_2)

bfrt.complete_operations()

# Final programming
print("""
**************** PROGAMMING RESULTS *****************
""")
print ("\nTable ingress_dt_table:")
p4.SwitchIngress.ingress_dt_table.is_cg_table.dump(table=True)

print ("\nTable ingress_dt_table:")
p4.SwitchIngress.ingress_dt_table.is_non_cg_table.dump(table=True)

print ("\nTable ul_psw_table:")
p4.SwitchIngress.ingress_dt_table.ul_psw_table.dump(table=True)

print ("\nTable ul_psw_table:")
p4.SwitchIngress.ingress_dt_table.ul_pkts_table.dump(table=True)

print ("\nTable ul_ipgw_table:")
p4.SwitchIngress.ingress_dt_table.ul_ipgw_table.dump(table=True)

print ("\nTable dl_psw_table:")
p4.SwitchIngress.ingress_dt_table.dl_psw_table.dump(table=True)

print ("\nTable dl_ipgw_table:")
p4.SwitchIngress.ingress_dt_table.dl_ipgw_table.dump(table=True)

print ("\nTable lpfPSwD:")
p4.SwitchIngress.macs_table.dump(table=True)

print ("\nTable lpfPSwD:")
p4.SwitchIngress.macd_table.dump(table=True)
