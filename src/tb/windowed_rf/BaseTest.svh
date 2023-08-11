/**
 * File              : BaseTest.svh
 *
 * Description       : extends SetupTest to manage the initialization of the
 *                     dut with a reset sequence. Once it terminates execution,
 *                     the actual testing sequence is started, which generates
 *                     a stream of fully random items, for early debugging of
 *                     the UVM testbench. The environment is kept as by
 *                     defaults, without a coverage collector.
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

`ifndef BASETEST_SVH
`define BASETEST_SVH

class BaseTest extends SetupTest;
  `uvm_component_utils(BaseTest)

  ResetSequence init_seq;
  RqstSequence seq;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    init_seq = ResetSequence::type_id::create("init_seq");
    seq = RqstSequence::type_id::create("seq");

  endfunction : end_of_elaboration_phase

  virtual function void configure_env();
    vif_mmu_t vif_mmu;

    /* last piece of the interface */
    if (!uvm_config_db#(vif_mmu_t)::get(this, "", "vif_mmu", vif_mmu))
      uvm_report_fatal("config_db", "can't get vif_mmu");
    else
      uvm_report_info("debug", "got vif_mmu", UVM_FULL);

    env_cfg.agn_cfg.vif_mmu = vif_mmu;

  endfunction : configure_env

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    init_seq.start(env.agn.seqr);
    seq.start(env.agn.seqr);

    phase.drop_objection(this);
  endtask : run_phase

endclass

`endif // BASETEST_SVH
