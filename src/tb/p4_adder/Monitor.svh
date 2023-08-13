/**
 * File              : Monitor.svh
 *
 * Description       : recognizes the pin-level activity on the virtual
 *                     interface and turns it into a transaction that
 *                     gets broadcasted to environment components
 *                     (every request generates a response)
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 05.08.2023
 * Last Modified Date: 13.08.2023
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

`ifndef MONITOR_SVH
`define MONITOR_SVH

class Monitor extends uvm_monitor;
  `uvm_component_utils(Monitor)

  vif_mon_t vif; // set by the agent
  uvm_analysis_port#(RspTxn) ap; // to broadcast dut responses

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    RspTxn rsp;

    @(vif.mon_cb); // skip first cycle

    forever begin
      capture(rsp); // allocate a new transaction

      uvm_report_info("debug", $sformatf("captured: %s", rsp.convert2string()), UVM_HIGH);

      ap.write(rsp); // non-blocking but the transaction won't be overwritten
    end
  endtask : run_phase

  task capture(output RspTxn rsp);

    /* allocate the transaction (no factory)*/
    rsp = new("rsp");

    /* synchronize on the sampling active edge */
    @(vif.mon_cb);

    `ASSIGN_UNKNOWN_CHECK(rsp.a, vif.mon_cb.a);
    `ASSIGN_UNKNOWN_CHECK(rsp.b, vif.mon_cb.b);
    `ASSIGN_UNKNOWN_CHECK(rsp.cin, vif.mon_cb.cin);
    `ASSIGN_UNKNOWN_CHECK(rsp.s, vif.mon_cb.s);
    `ASSIGN_UNKNOWN_CHECK(rsp.cout, vif.mon_cb.cout);

  endtask : capture

endclass

`endif // MONITOR_SVH
