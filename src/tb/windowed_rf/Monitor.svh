/**
 * File              : Monitor.svh
 *
 * Description       : recognizes the pin-level activity on the virtual
 *                     interface and turns it into a transaction that
 *                     gets broadcasted to environment components
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 11.08.2023
 * Last Modified Date: 11.08.2023
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
  uvm_analysis_port#(RspTxn) ap; // to broadcast responses (includes response)

  /* timing exception */
  bit skip_rsp;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    ap = new("ap", this);
  endfunction

  task run_phase(uvm_phase phase);
    RspTxn rqst1, rqst2;
    skip_rsp = 0;

    forever begin

      /* first edge */
      capture(rqst2, rqst1); // rsp to rqst2, rqst1
      if (rqst2 != null) begin
        ap.write(rqst2);
        uvm_report_info("capture", {"first edge: ", rqst2.convert2string()}, UVM_FULL);
      end

      /* second edge */
      capture(rqst1, rqst2); // rsp to rqst1, rqst2
      if (rqst1 != null) begin
        ap.write(rqst1);
        uvm_report_info("capture", {"second edge: ", rqst1.convert2string()}, UVM_FULL);
      end

    end

  endtask : run_phase

  task capture(inout RspTxn rsp, output RspTxn rqst);

    /* synchronize on the sampling active edge */
    @(vif.mon_cb);

    /* is there a pending request ? */
    if (rsp != null) begin
      rsp.set_name("rsp");
      `ASSIGN_UNKNOWN_CHECK(rsp.out1, vif.mon_cb.out1);
      `ASSIGN_UNKNOWN_CHECK(rsp.out2, vif.mon_cb.out2);
      `ASSIGN_UNKNOWN_CHECK(rsp.fill, vif.mon_cb.fill);
      `ASSIGN_UNKNOWN_CHECK(rsp.spill, vif.mon_cb.spill);
    end

    if (skip_rsp) begin
      skip_rsp = 0;
      rqst = rsp; // forward the previous request
      rsp = null; // discard the current response
    end else begin

      /* allocate the new request */
      rqst = new("rqst");

      /* if bypass is high the driver is paused */
      `ASSIGN_UNKNOWN_CHECK(rqst.bypass, vif.mon_cb.bypass);

      if (!rqst.bypass) begin
        `ASSIGN_UNKNOWN_CHECK(rqst.reset, vif.mon_cb.reset);
        `ASSIGN_UNKNOWN_CHECK(rqst.enable, vif.mon_cb.enable);
        `ASSIGN_UNKNOWN_CHECK(rqst.rd1, vif.mon_cb.rd1);
        `ASSIGN_UNKNOWN_CHECK(rqst.rd2, vif.mon_cb.rd2);
        `ASSIGN_UNKNOWN_CHECK(rqst.wr, vif.mon_cb.wr);
        `ASSIGN_UNKNOWN_CHECK(rqst.add_rd1, vif.mon_cb.add_rd1);
        `ASSIGN_UNKNOWN_CHECK(rqst.add_rd2, vif.mon_cb.add_rd2);
        `ASSIGN_UNKNOWN_CHECK(rqst.add_wr, vif.mon_cb.add_wr);
        `ASSIGN_UNKNOWN_CHECK(rqst.datain, vif.mon_cb.datain);
        `ASSIGN_UNKNOWN_CHECK(rqst.call, vif.mon_cb.call);
        `ASSIGN_UNKNOWN_CHECK(rqst.ret, vif.mon_cb.ret);
        `ASSIGN_UNKNOWN_CHECK(rqst.mmu_data, vif.mon_cb.mmu_data);
        `ASSIGN_UNKNOWN_CHECK(rqst.mmu_done, vif.mon_cb.mmu_done);

        /* if the call generates a spill, an additional cycle is required to
         * sample the response. In case of a ret, the fill can be sampled the
         * subsequent cycle. In either case, the problem of skipping request
         * sampling while the bypass is high is handled in the else branch */
        if (rqst.call)
          skip_rsp = 1;

      end else begin
        /* no request */
        rqst = null;
        uvm_report_info("capture", "bypass high: no request", UVM_FULL);
      end

    end

  endtask : capture

endclass

`endif // MONITOR_SVH
