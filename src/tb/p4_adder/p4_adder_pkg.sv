/**
 * File              : p4_adder_pkg.sv
 *
 * Description       : namespace for the p4 adder UVM-based testbench. The
 *                     dut generics are set at compile time defining the
 *                     macros "NBIT" and "NBIT_PER_BLOCK" by command line.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 05.08.2023
 * Last Modified Date: 08.08.2023
 *
 * Copyright (c) 2023
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

`ifndef P4_ADDER_PKG_SV
`define P4_ADDER_PKG_SV

package p4_adder_pkg;
  import uvm_pkg::*;

  `include "uvm_macros.svh"

  /* let the DUT generics be customizable at compile time by command line */
  parameter byte unsigned NBIT            = `NBIT;
  parameter byte unsigned NBIT_PER_BLOCK  = `NBIT_PER_BLOCK;

  typedef bit [NBIT-1:0] data_t; // speed up simulation, $isunknown() when reading from DUT

  /* virtual interfaces to be used by Driver and Monitor */
  typedef virtual p4_adder_if.drv vif_drv_t;
  typedef virtual p4_adder_if.mon vif_mon_t;

  /* verification classes */
  `include "RqstTxn.svh"
  `include "RspTxn.svh"
  `include "Sequencer.svh"
  `include "Driver.svh"
  `include "Monitor.svh"
  `include "Agent.svh"
  `include "Coverage.svh"
  `include "Printer.svh"
  `include "Scoreboard.svh"
  `include "Environment.svh"
  `include "RqstSequence.svh"
  `include "BaseTest.svh"

  /* tests */
  `include "CnstRqstTxn.svh"
  `include "StmCoverage.svh"
  `include "Test.svh"

endpackage

`endif // P4_ADDER_PKG_SV
