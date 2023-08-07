/**
 * File              : Driver.svh
 *
 * Description       : translates incoming sequence items to pin wiggles,
 *                     communicating with the DUT through the virtual
 *                     interface
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 05.08.2023
 * Last Modified Date: 05.08.2023
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

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    RqstTxn rqst; // overwritten in each iteration

    forever begin
      seq_item_port.get_next_item(rqst);

      uvm_report_info("debug", $sformatf("got item: %s", rqst.convert2string()), UVM_FULL);

      apply_item(rqst);
      seq_item_port.item_done();
    end
  endtask : run_phase

  task apply_item(input RqstTxn rqst);

    /* synchronize on the driving active edge */
    @(vif.drv_cb);

    vif.drv_cb.a <= rqst.a;
    vif.drv_cb.b <= rqst.b;
    vif.drv_cb.cin <= rqst.cin;

  endtask : apply_item

endclass

`endif // DRIVER_SVH
