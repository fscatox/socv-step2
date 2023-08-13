/**
 * File              : Monitor.svh
 *
 * Description       : recognizes the pin-level activity on the virtual
 *                     interface and turns it into a transaction that
 *                     gets broadcasted to environment components. The
 *                     monitor activates on rising edges:
 *                       - it samples the new request, applied to the dut
 *                         by the driver in the previous falling edge;
 *                       - it samples the response for the request that was
 *                         sampled the cycle before. Once the response is
 *                         available, it's broadcasted.
 *                      Request sampling is suspended while the bypass
 *                      signal is active, because the driver waits for the
 *                      register file to become available before applying
 *                      new requests, with the exception of reset operations.
 *                      In the case of a call operation, the response must be
 *                      sampled not one cycle but two cycles after the request,
 *                      which is the one during which the rf may raise spill.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 11.08.2023
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

    /* skip init */
    @(vif.mon_cb);

    forever begin

      /* first edge */
      capture(rqst2, rqst1); // rsp to rqst2, rqst1
      if (rqst2 != null) begin
        ap.write(rqst2);
        uvm_report_info("capture", {"first edge: ", rqst2.convert2string()}, UVM_HIGH);
      end

      /* second edge */
      capture(rqst1, rqst2); // rsp to rqst1, rqst2
      if (rqst1 != null) begin
        ap.write(rqst1);
        uvm_report_info("capture", {"second edge: ", rqst1.convert2string()}, UVM_HIGH);
      end

    end

  endtask : run_phase

  task capture(inout RspTxn rsp, output RspTxn rqst);
    bit reset_rqst, bypass_rqst;
    bit rqst_aborted = 0;

    rqst = null;

    /* synchronize on the sampling active edge */
    @(vif.mon_cb);

    /* new request is a reset ? */
    `ASSIGN_UNKNOWN_CHECK(reset_rqst, vif.mon_cb.reset);

    /* is there a pending request ? */
    if (rsp != null) begin
      uvm_report_info("capture", "pending request", UVM_HIGH);

      /* is it marked to be skipped ? */
      if (skip_rsp) begin
        skip_rsp = 0;
        uvm_report_info("capture", "got skip_rsp", UVM_HIGH);

        if (reset_rqst) begin
          /* send the response back marking the request as aborted */
          rqst_aborted = 1;
          uvm_report_info("capture", "skip_rsp: overridden by reset request", UVM_HIGH);
        end else begin
          rqst = rsp; // forward the previous request
          rsp = null; // discard the current response
          uvm_report_info("capture", "skip_rsp: no response, forwarding request", UVM_HIGH);
        end

      end

      /* sample the response if not forwarded */
      if (rsp != null) begin
        rsp.set_name("rsp");
        `ASSIGN_UNKNOWN_CHECK(rsp.out1, vif.mon_cb.out1);
        `ASSIGN_UNKNOWN_CHECK(rsp.out2, vif.mon_cb.out2);
        `ASSIGN_UNKNOWN_CHECK(rsp.fill, vif.mon_cb.fill);
        `ASSIGN_UNKNOWN_CHECK(rsp.spill, vif.mon_cb.spill);

        /* if it's a fill and the new request is a reset,
         * send the response back marking the request as aborted */
         rsp.aborted = rqst_aborted || (rsp.fill && reset_rqst);
       end
    end


    /* is the request being forwarded? If not, sample it */
    if (rqst == null) begin

      /* if bypass is high the driver is paused,
       * unless a reset request was issued  */
      `ASSIGN_UNKNOWN_CHECK(bypass_rqst, vif.mon_cb.bypass);

      if (reset_rqst || !bypass_rqst) begin

        uvm_report_info("capture",
          $sformatf("bypass %b, reset %b: sampling new request",
            bypass_rqst, reset_rqst), UVM_HIGH);

        /* allocate the new request */
        rqst = new("rqst");

        rqst.bypass = bypass_rqst;
        rqst.reset = reset_rqst;
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
        if (!rqst.reset && rqst.call) begin
          skip_rsp = 1;
          uvm_report_info("capture", "bypass low: call detected, setting skip_rsp", UVM_HIGH);
        end

      end else // !reset && bypass
        uvm_report_info("capture", "bypass high: no new request", UVM_HIGH);

    end

  endtask : capture

endclass

`endif // MONITOR_SVH
