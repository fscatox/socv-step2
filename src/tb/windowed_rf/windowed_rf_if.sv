/**
 * File              : windowed_rf_if.sv
 *
 * Description       : bundles the dut wires encapsulating synchronization
 *                     information for the verification environment
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

`ifndef WINDOWED_RF_IF_SV
`define WINDOWED_RF_IF_SV

interface windowed_rf_if (input bit clk);

  /* 2R, 1W synchronous ports, read-before-write */
  bit reset; // synchronous, write through
  bit enable; // gates rd1, rd2, wr
  bit rd1, rd2, wr;

  windowed_rf_pkg::addr_t add_rd1, add_rd2, add_wr;
  windowed_rf_pkg::data_t datain, out1, out2;

  /* execution flow control */
  bit call, ret;
  bit bypass; // 1'b0 when available for external operations

  /* interface to mmu */
  bit fill, spill;
  bit mmu_done;
  windowed_rf_pkg::data_t mmu_data;

  /* drive the request 0ns after the falling edge
   * (the windowed_rf samples at the next rising edge) */
  clocking drv_cb @(negedge clk);

    output reset, enable,
           rd1, rd2, wr,
           add_rd1, add_rd2, add_wr,
           datain,
           call, ret;

  endclocking

  modport drv (
    clocking drv_cb,

    /* non-sampled, the driver must know when the rf is busy spilling/filling */
    input bypass
  );

  /* mmu fsm */
  clocking mmu_cb @(posedge clk);

    input  reset,
           fill, spill,
           out1;

    output mmu_data,
           mmu_done;

  endclocking

  modport mmu (clocking mmu_cb);

  /* sample request 1step before the rising edge */
  clocking mon_cb @(posedge clk);

    /* request */
    input reset, enable,
          rd1, rd2, wr,
          add_rd1, add_rd2, add_wr,
          datain,
          call, ret,
          bypass; // sampled with the request: if high, the request is void

    /* response */
    input out1, out2,
          fill, spill;

    /* analysis */
    input mmu_data,
          mmu_done;

  endclocking

  modport mon (clocking mon_cb);

endinterface

`endif // WINDOWED_RF_IF_SV
