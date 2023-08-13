/**
 * File              : FullTest.svh
 *
 * Description       : extends BaseTest adding coverage and randomization
 *                     constraints to the request transactions. Notice that
 *                     with this test, "+n_txn" is the number of transactions
 *                     per test sequence.
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


`ifndef FULLTEST_SVH
`define FULLTEST_SVH

class FullTest extends BaseTest;
  `uvm_component_utils(FullTest)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure_env();
    vif_mmu_t vif_mmu;

    /* n_txn per sequence: 3 sequences in total */
    env_cfg.n_xpected *= 3;

    /* last piece of the interface */
    if (!uvm_config_db#(vif_mmu_t)::get(this, "", "vif_mmu", vif_mmu))
      uvm_report_fatal("config_db", "can't get vif_mmu");
    else
      uvm_report_info("debug", "got vif_mmu", UVM_FULL);

    env_cfg.agn_cfg.vif_mmu = vif_mmu;

    /* stimulus customization */
    RqstTxn::type_id::set_type_override(CnstRqstTxn::get_type());

    /* coverage collection */
    Coverage::type_id::set_type_override(StmCoverage::get_type());
    env_cfg.has_cov = 1;

  endfunction : configure_env

endclass

`endif // FULLTEST_SVH
