/**
 * File              : windowed_rf_top.sv
 *
 * Description       : instantiates the dut and the free running clock, then
 *                     it sets up and invokes the test specified by command line
 *                     with "+UVM_TESTNAME=<test name>"
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 11.08.2023
 * Last Modified Date: 12.08.2023
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

`ifndef WINDOWED_RF_TOP_SV
`define WINDOWED_RF_TOP_SV

program automatic windowed_rf_test (windowed_rf_if ifc);
  import uvm_pkg::*;

  initial begin
    uvm_config_db#(windowed_rf_pkg::vif_drv_t)::set(null, "uvm_test_top", "vif_drv", ifc.drv);
    uvm_config_db#(windowed_rf_pkg::vif_mmu_t)::set(null, "uvm_test_top", "vif_mmu", ifc.mmu);
    uvm_config_db#(windowed_rf_pkg::vif_mon_t)::set(null, "uvm_test_top", "vif_mon", ifc.mon);

    run_test();
  end

endprogram

`timescale 1ns/100ps

module windowed_rf_top;
  bit clk;

  /* clock generator */
  initial begin
    clk = 1;

    forever
      #5 clk = ~clk;
  end

  /* instantiations */
  windowed_rf_if ifc(clk);

  windowed_rf_test test_prgm(ifc);

  windowed_rf#(

    .M(windowed_rf_pkg::NGLOBALS),
    .N(windowed_rf_pkg::NLOCALS),
    .F(windowed_rf_pkg::NWINDOWS),
    .width_data(windowed_rf_pkg::NBIT)

  ) windowed_rf_i (

    .clk(ifc.clk),
    .reset(ifc.reset),
    .enable(ifc.enable),

    .rd1(ifc.rd1),
    .rd2(ifc.rd2),
    .wr(ifc.wr),

    .add_rd1(ifc.add_rd1),
    .add_rd2(ifc.add_rd2),
    .add_wr(ifc.add_wr),

    .datain(ifc.datain),
    .out1(ifc.out1),
    .out2(ifc.out2),

    .call(ifc.call),
    .ret(ifc.ret),
    .bypass(ifc.bypass),

    .fill(ifc.fill),
    .spill(ifc.spill),

    .mmu_done(ifc.mmu_done),
    .mmu_data(ifc.mmu_data)
  );

endmodule

`endif // WINDOWED_RF_TOP_SV

