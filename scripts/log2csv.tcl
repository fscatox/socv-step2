#!/usr/bin/env tclsh
#
# File              : log2csv.tcl
# Description       : parses the printer and the scoreboard logs. The
#                     response transactions broadcasted to the printer
#                     are exported in comma-separated value format, with
#                     the outcome of the comparison by the scoreboard. To
#                     ensure repeatability, the seed of the simulation is
#                     listed at the top of the file.
# Author            : Fabio Scatozza <s315216@studenti.polito.it>
# Date              : 09.08.2023
# Last Modified Date: 14.08.2023
#
# Copyright (c) 2023
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

proc log2csv {printer_file scoreboard_file sv_seed out_file} {
  set prt_chan [open $printer_file]
  set scb_chan [open $scoreboard_file]
  set out_chan [open $out_file w]

  # start reading a block
  set print_header true
  
  # discard first line
  gets $prt_chan

  while {[gets $prt_chan prt_line] >= 0} {
    # and read until EOF or the beginning of the next block
    set block $prt_line
    while {([gets $prt_chan prt_line] >= 0) && [regexp UVM_INFO $prt_line] == 0} {
      set block "$block$prt_line"
    }

    # read the corresponding block from the scoreboard
    # discard any line that doesn't match MATCH! or MISMATCH! first
    set mismatch 0
    while { [regexp {(?:MIS)?MATCH} [gets $scb_chan] match] == 0 } {}
    if { [regexp MISMATCH $match] } {
      set mismatch 1
    } 
    set block "$block mismatch $mismatch"

    # clean the line
    regexp {rsp *(([^ ]+\s+[0-9aAbBcCdDeEfF]+ *)+)} $block match block
    regsub -all {[ \t]+} $block { } block 

    if {$print_header} {
      # print the simulation seed
      puts $out_chan $sv_seed
      # print the names of variables inside the response transaction
      puts $out_chan [join [lmap {i ii} $block {list $i}] ,]
      set print_header false
    }
    puts $out_chan [join [lmap {i ii} $block {list $ii}] ,]

  }

  close $prt_chan
  close $scb_chan
  close $out_chan

}

