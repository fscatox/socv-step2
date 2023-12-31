/**
 * File              : ResetSequence.svh
 *
 * Description       : generates some sequence items to feed the driver and
 *                     bring the dut registers in a known state. It's not
 *                     counted in the "+n_txn" requests.
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

`ifndef RESETSEQUENCE_SVH
`define RESETSEQUENCE_SVH

class ResetSequence extends uvm_sequence#(RqstTxn);
  `uvm_object_utils(ResetSequence)

  function new(string name = "ResetSequence");
    super.new(name);
  endfunction

  task body();

    RqstTxn reset_rqst = RqstTxn::type_id::create("reset_rqst");

    start_item(reset_rqst);
    reset_rqst.reset = 1;
    finish_item(reset_rqst);

  endtask : body

endclass

`endif // RESETSEQUENCE_SVH

