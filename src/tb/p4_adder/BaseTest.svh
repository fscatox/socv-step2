/**
 * File              : BaseTest.svh
 *
 * Description       : handles the default configuration of the environment
 *                     and the common duties of child tests.
 *                       - the number of request transactions can be set
 *                         by command line with "+n_txn=<txn number>";
 *                         otherwise, it defaults to 100
 *                       - the printer file can be set by command line with
 *                         "+printer_file=<file path>"; otherwise it defaults
 *                         to printer.log
 *                       - the scoreboard file can be set by command line with
 *                         "+scoreboard_file=<file path>"; otherwise it defaults
 *                         to scoreboard.log
 *                       - to make the test quiet, pass the flag "+quiet"
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
 * Last Modified Date: 07.08.2023
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

  RqstSequence seq;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    seq = RqstSequence::type_id::create("seq");

  endfunction : end_of_elaboration_phase

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    seq.start(env.agn.seqr);

    phase.drop_objection(this);
  endtask : run_phase

endclass

`endif // BASETEST_SVH
