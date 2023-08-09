# File              : autocompile.tcl
# Description       : determines the compile order for a list of hdl
#                     sources by executing the compilation command 
#                     for each one of them in order, then repeating
#                     for any compiles that fail until there are no
#                     more compile errors.
# Author            : Fabio Scatozza <s315216@studenti.polito.it>
# Date              : 09.08.2023
# Last Modified Date: 09.08.2023
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

proc autocompile {compile_command hdl_sources} {
  set n_success true
  set n_remaining [llength $hdl_sources]

  while { $n_success && $n_remaining } {
    set hdl_failed {}
    set n_failed   0
    set n_success  0

    foreach hdl $hdl_sources {

      if { 1 == [catch { {*}$compile_command $hdl }] } {
        lappend hdl_failed $hdl
        incr n_failed
      } else {
        incr n_success
      }

    }

    set n_remaining $n_failed
    set hdl_sources $hdl_failed
  }

  # 0 for success
  return [expr {!!$n_remaining}]
}

