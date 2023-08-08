/**
 * File              : Test.svh
 *
 * Description       : extends BaseTest adding coverage and randomization
 *                     constraints to the request transactions.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 08.08.2023
 * Last Modified Date: 08.08.2023
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

`ifndef TEST_SVH
`define TEST_SVH

class Test extends BaseTest;
  `uvm_component_utils(Test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void configure_env();

    /* stimulus customization */
    RqstTxn::type_id::set_type_override(CnstRqstTxn::get_type());

    /* coverage collection */
    Coverage::type_id::set_type_override(StmCoverage::get_type());
    env_cfg.has_cov = 1;

  endfunction

endclass

`endif // TEST_SVH
