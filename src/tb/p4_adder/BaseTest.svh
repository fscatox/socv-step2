/**
 * File              : BaseTest.svh
 *
 * Description       : handles the default configuration of the environment
 *                     and the common duties of child tests.
 *                       - the number of request transactions can be set
 *                         by command line with "+n_txn=<txn number>";
 *                         otherwise, it defaults to 100
 *                       - to make the test quiet, pass the flag "+quiet"
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
 * Last Modified Date: 06.08.2023
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

class BaseTest extends uvm_test;
  `uvm_component_utils(BaseTest)

  Environment env;
  env_cfg_t env_cfg;

  RqstSequence seq;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);

    configure_env();
    uvm_config_db#(env_cfg_t)::set(this, "env", "env_cfg", env_cfg);
    uvm_config_db#(int unsigned)::set(this, "seq", "n_txn", env_cfg.n_xpected);

    if($value$plusargs("quiet")) begin
      Printer::type_id::set_type_override(BitBucket::get_type());
      uvm_report_info("debug", "got +quiet, done printer override", UVM_FULL);
    end

    env = Environment::type_id::create("env", this);

  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    seq = RqstSequence::type_id::create("seq", this);

    uvm_report_info("debug", "End of elaboration hierarchy:", UVM_FULL);
    if (uvm_report_enabled(UVM_FULL))
      uvm_top.print_topology();

    uvm_report_info("debug", "End of elaboration config db:", UVM_FULL);
    if (uvm_report_enabled(UVM_FULL))
      uvm_config_db#(int)::dump();

  endfunction : end_of_elaboration_phase

  virtual function void start_of_simulation_phase(uvm_phase phase);

    uvm_report_info("debug", "Start of simulation factory:", UVM_FULL);
    if (uvm_report_enabled(UVM_FULL))
      uvm_factory::get().print();

  endfunction : start_of_simulation_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    seq.start(env.agn.seqr);
    phase.drop_objection(this);
  endtask : run_phase

  /* configuration for the environment and the agent */
  virtual function void configure_env();
    vif_t vif;

    /* pass the interface down the hierarchy */
    if (!uvm_config_db#(vif_t)::get(this, "", "vif", vif))
      uvm_report_fatal("config_db", "can't get vif");
    else
      uvm_report_info("debug", "got vif", UVM_FULL);

    env_cfg.agn_cfg.vif_mon = vif.mon;
    env_cfg.agn_cfg.vif_drv = vif.drv;

    /* determine the number of request transactions */
    if (!$value$plusargs("n_txn=%d", env_cfg.n_xpected)) begin
      env_cfg.n_xpected = 100;
      uvm_report_info("debug", "no +n_txn arg", UVM_FULL);
    end else
      uvm_report_info("debug", $sformatf("got +n_txn=%0d", env_cfg.n_xpected), UVM_FULL);

    /* by default: no scoreboard, no coverage collector */
    env_cfg.only_print = 1;

  endfunction : configure_env

endclass

`endif // BASETEST_SVH
