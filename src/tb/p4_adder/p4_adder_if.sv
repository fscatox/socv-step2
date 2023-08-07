/**
 * File              : p4_adder_if.sv
 *
 * Description       : bundles the dut wires encapsulating synchronization
 *                     information for the verification environment
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 05.08.2023
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

`ifndef P4_ADDER_IF_SV
`define P4_ADDER_IF_SV

interface p4_adder_if (input bit clk);

  p4_adder_pkg::data_t a, b, s;
  bit cin, cout;

  /* drive the request 0ns after the rising edge */
  clocking drv_cb @(posedge clk);
    output a, b, cin;
  endclocking

  modport drv (clocking drv_cb);

  /* sample request and response 1step before the rising edge */
  clocking mon_cb @(posedge clk);
    input a, b, cin, s, cout;
  endclocking

  modport mon (clocking mon_cb);

endinterface

`endif // P4_ADDER_IF_SV
