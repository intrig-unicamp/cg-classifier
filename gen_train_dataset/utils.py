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

import socket, struct

def ip2long(ip):
  """
  Convert an IP string to long
  """
  try:
  	packedIP = socket.inet_aton(ip)
  except socket.error:
  	return -1
  return struct.unpack("!L", packedIP)[0]