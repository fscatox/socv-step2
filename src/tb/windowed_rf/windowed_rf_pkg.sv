/**
 * File              : windowed_rf_pkg.sv
 *
 * Description       : namespace for the windowed register file UVM-based
 *                     testbench. The dut and mmu generics are set at compile
 *                     time defining the following macros by command line.
 *                       - "NBIT"      the parallelism of the rf
 *                       - "NBIT_MEM"  the minimum addressable width of the
 *                                     main memory
 *                       - "NGLOBALS"  global registers per window
 *                       - "NLOCALS"   local registers per window
 *                       - "NWINDOWS"  number of windows
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 09.08.2023
 * Last Modified Date: 09.08.2023
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

`ifndef WINDOWED_RF_PKG_SV
`define WINDOWED_RF_PKG_SV

package windowed_rf_pkg;
  import uvm_pkg::*;

  `include "uvm_macros.svh"

  /* let the DUT generics be customizable at compile time by command line */
  parameter byte unsigned NBIT     = `NBIT;
  parameter byte unsigned NBIT_MEM = `NBIT_MEM;
  parameter byte unsigned NGLOBALS = `NGLOBALS;
  parameter byte unsigned NLOCALS  = `NLOCALS;
  parameter byte unsigned NWINDOWS = `NWINDOWS;

  typedef bit [NBIT-1:0] data_t;
  typedef bit [$clog2(NGLOBALS+3*NLOCALS)-1:0] addr_t;

  /* to improve simulation performance, 2-state data types are used,
   * whereas the dut is mapped to SystemVerilog 4-state data types */
  `define ASSIGN_UNKNOWN_CHECK(lhs, rhs) \
    do begin \
      lhs = rhs; \
      if ($isunknown(rhs)) \
        uvm_report_warning("capture", "dut outputs unknown bits"); \
    end while (0)

  /* virtual interfaces to be used by Driver and Monitor */
  typedef virtual windowed_rf_if.drv vif_drv_t;
  typedef virtual windowed_rf_if.mmu vif_mmu_t;
  typedef virtual windowed_rf_if.mon vif_mon_t;

  /* verification classes */
  `include "RqstTxn.svh"
  `include "RqstAnlysTxn.svh"
  `include "RspTxn.svh"
  `include "../Sequencer.svh"
  `include "Mmu.svh"
  `include "Driver.svh"
  `include "Monitor.svh"
  `include "Agent.svh"
  `include "../Coverage.svh"
  `include "../Printer.svh"
  `include "BehWindowedRf.svh"
  `include "../BaseScoreboard.svh"
  `include "Scoreboard.svh"
  `include "../Environment.svh"
  `include "ResetSequence.svh"
  `include "../RqstSequence.svh"
  `include "../SetupTest.svh"
  `include "BaseTest.svh"

  /* tests */

endpackage

`endif // WINDOWED_RF_PKG_SV
