/**
 * File              : p4_adder_top.sv
 *
 * Description       : instantiates the dut and the free running clock, then
 *                     it sets up and invokes the test specified by command line
 *                     with "+UVM_TESTNAME=<test name>"
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
 * Last Modified Date: 07.08.2023
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

`ifndef P4_ADDER_TOP_SV
`define P4_ADDER_TOP_SV

program automatic p4_adder_test (p4_adder_if ifc);
  import uvm_pkg::*;

  initial begin
    uvm_config_db#(p4_adder_pkg::vif_t)::set(null, "uvm_test_top", "vif", ifc);

    run_test();
  end

endprogram

`timescale 1ns/100ps

module p4_adder_top;
  bit clk;

  /* clock generator */
  initial begin
    clk = 0;

    forever
      #5 clk = ~clk;
  end

  /* instantiations */
  p4_adder_if ifc(clk);

  p4_adder_test test_prgm(ifc);

  p4_adder#(
    .nbit(p4_adder_pkg::NBIT),
    .nbit_per_block(p4_adder_pkg::NBIT_PER_BLOCK)
  ) p4_adder_i (
    .a(ifc.a),
    .b(ifc.b),
    .cin(ifc.cin),
    .s(ifc.s),
    .cout(ifc.cout)
  );

endmodule

`endif // P4_ADDER_TOP_SV
