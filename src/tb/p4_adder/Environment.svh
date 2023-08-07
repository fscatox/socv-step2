/**
 * File              : Environment.svh
 *
 * Description       : default verification environment for the p4 adder.
 *                     Test classes can customize it with both the factory
 *                     overrides and the environment configuration object.
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

`ifndef ENVIRONMENT_SVH
`define ENVIRONMENT_SVH

typedef struct {

  agn_cfg_t agn_cfg; // agent configuration object

  int unsigned n_xpected; // from the test
  bit only_print; // no scoreboard and coverage collector

} env_cfg_t;

class Environment extends uvm_env;
  `uvm_component_utils(Environment)

  /* environment components */
  Agent agn;
  Scoreboard scb;
  Coverage cov;
  Printer prt;

  /* environment configuration */
  env_cfg_t cfg;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);

    if (!uvm_config_db#(env_cfg_t)::get(this, "", "env_cfg", cfg))
      uvm_report_fatal("config_db", "can't get env_cfg");
    else
      uvm_report_info("debug", "got env_cfg", UVM_FULL);

    uvm_config_db#(agn_cfg_t)::set(this, "agn", "agn_cfg", cfg.agn_cfg);
    uvm_config_db #(uvm_active_passive_enum)::set(this, "agn", "is_active", UVM_ACTIVE);
    uvm_config_db#(int unsigned)::set(this, "scb", "n_xpected", cfg.n_xpected);

    agn = Agent::type_id::create("agn", this);

    if (!cfg.only_print) begin
      scb = Scoreboard::type_id::create("scb", this);
      cov = Coverage::type_id::create("cov", this);

      uvm_report_info("debug", "cfg.only_print == 0, create", UVM_FULL);
    end

    prt = Printer::type_id::create("prt", this);
    uvm_report_info("debug", $sformatf("created object (%s) prt", prt.get_type_name()), UVM_FULL);

  endfunction : build_phase

  virtual function void connect_phase(uvm_phase phase);

    if (!cfg.only_print) begin
      agn.ap.connect(scb.analysis_export);
      agn.ap.connect(cov.analysis_export);

      uvm_report_info("debug", "cfg.only_print == 0, connect", UVM_FULL);
    end

    agn.ap.connect(prt.analysis_export);

  endfunction : connect_phase

endclass

`endif // ENVIRONMENT_SVH
