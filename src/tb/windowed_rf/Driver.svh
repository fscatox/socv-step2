/**
 * File              : Driver.svh
 *
 * Description       : translates incoming sequence items to pin wiggles,
 *                     communicating with the DUT through the virtual
 *                     interface
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 10.08.2023
 * Last Modified Date: 10.08.2023
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

`ifndef DRIVER_SVH
`define DRIVER_SVH

class Driver extends uvm_driver#(RqstTxn);
  `uvm_component_utils(Driver)

  vif_drv_t vif; // set by the agent
  vif_mmu_t vif_mmu;

  Mmu mmu;

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    mmu = Mmu::type_id::create("mmu", this);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    mmu.vif = vif_mmu;
  endfunction

  task run_phase(uvm_phase phase);

    RqstTxn rqst; // overwritten in each iteration

    forever begin
      seq_item_port.get_next_item(rqst);
      uvm_report_info("debug", $sformatf("got item: %s", rqst.convert2string()), UVM_FULL);

      apply_item(rqst);
      uvm_report_info("debug", $sformatf("applied item: %s", rqst.convert2string()), UVM_FULL);

      seq_item_port.item_done();
    end

  endtask : run_phase

  task apply_item(input RqstTxn rqst);

    /* synchronize on the driving active edge */
    @(vif.drv_cb);

    /* rf busy spilling/filling */
    if (!rqst.reset && vif.bypass) begin
      uvm_report_info("debug", "rf bypassed: waiting", UVM_FULL);

      @(negedge vif.bypass);
      uvm_report_info("debug", "rf bypassed: fell", UVM_FULL);

      @(vif.drv_cb);
    end

    vif.drv_cb.reset   <= rqst.reset;
    vif.drv_cb.enable  <= rqst.enable;
    vif.drv_cb.rd1     <= rqst.rd1;
    vif.drv_cb.rd2     <= rqst.rd2;
    vif.drv_cb.wr      <= rqst.wr;
    vif.drv_cb.add_rd1 <= rqst.add_rd1;
    vif.drv_cb.add_rd2 <= rqst.add_rd2;
    vif.drv_cb.add_wr  <= rqst.add_wr;
    vif.drv_cb.datain  <= rqst.datain;
    vif.drv_cb.call    <= rqst.call;
    vif.drv_cb.ret     <= rqst.ret;

  endtask : apply_item

endclass

`endif // DRIVER_SVH
