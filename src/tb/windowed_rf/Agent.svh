/**
 * File              : Agent.svh
 *
 * Description       : windowed rf agent. To add flexibility, it's extended from
 *                     uvm_agent and configurable in either active or passive mode
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
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

`ifndef AGENT_SVH
`define AGENT_SVH

typedef struct {
  // uvm_active_passive_enum`(is_active) is inherithed from uvm_agent class

  // interface handle for the monitor and the driver
  vif_drv_t vif_drv;
  vif_mmu_t vif_mmu;
  vif_mon_t vif_mon;

} agn_cfg_t;

class Agent extends uvm_agent;
  `uvm_component_utils(Agent)

  /* agent components */
  Monitor mon;
  Driver drv;
  Sequencer seqr;

  /* monitor out */
  uvm_analysis_port#(RspTxn) ap;

  /* agent configuration */
  agn_cfg_t cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    ap = new("ap", this);

    if (!uvm_config_db#(agn_cfg_t)::get(this, "", "agn_cfg", cfg))
      uvm_report_fatal("config_db", "can't get agn_cfg");
    else
      uvm_report_info("debug", "got agn_cfg", UVM_FULL);

    if (get_is_active() == UVM_ACTIVE) begin
      seqr = Sequencer::type_id::create("seqr", this);
      drv = Driver::type_id::create("drv", this);

      uvm_report_info("debug", "UVM_ACTIVE, create", UVM_FULL);
    end

    mon = Monitor::type_id::create("mon", this);

  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);

    mon.vif = cfg.vif_mon;
    mon.ap.connect(ap);

    if (get_is_active() == UVM_ACTIVE) begin
      drv.seq_item_port.connect(seqr.seq_item_export);
      drv.vif = cfg.vif_drv;
      drv.vif_mmu = cfg.vif_mmu;

      uvm_report_info("debug", "UVM_ACTIVE, connect", UVM_FULL);
    end

  endfunction : connect_phase

endclass

`endif // AGENT_SVH

