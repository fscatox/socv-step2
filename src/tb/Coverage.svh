/**
 * File              : Coverage.svh
 *
 * Description       : base coverage collector abstract class. Tests must use
 *                     the factory to override with a child class that
 *                     includes stimulus-specific covergroups and implements
 *                     the "sample()" callback
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
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

`ifndef COVERAGE_SVH
`define COVERAGE_SVH

virtual class Coverage extends uvm_subscriber#(RspTxn);
  `uvm_component_utils(Coverage)

  RspTxn txn;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void write(RspTxn t);

    // grab the object
    txn = t;
    uvm_report_info("debug", $sformatf("write(): grabbed %s", txn.convert2string()), UVM_FULL);

    // sample local transaction
    sample();
    uvm_report_info("debug", "write(): sampled", UVM_HIGH);

  endfunction : write

  /* implemented by child classes to trigger the sampling of covergroups */
  pure virtual function void sample();

endclass

`endif // COVERAGE_SVH

