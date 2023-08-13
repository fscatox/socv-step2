/**
 * File              : TopSequence.svh
 *
 * Description       : generates the stream of sequence items to feed the
 *                     driver. Tests can override the type of request
 *                     transaction through the factory.
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

`ifndef TOPSEQUENCE_SVH
`define TOPSEQUENCE_SVH

class TopSequence extends uvm_sequence#(RqstTxn);
  `uvm_object_utils(TopSequence)

  RqstTxn rqst;
  int unsigned n_txn;

  function new(string name = "TopSequence");
    super.new(name);
  endfunction

  task body();

    if (!uvm_config_db#(int unsigned)::get(null, "uvm_test_top.seq", "n_txn", n_txn))
      uvm_report_fatal("sequence", "can't get n_txn");
    else
      uvm_report_info("debug", "got n_txn", UVM_FULL);

    rqst = RqstTxn::type_id::create("rqst");

    repeat (n_txn) begin
      start_item(rqst); // initiate handshake
      uvm_report_info("debug", "start_item(): done", UVM_FULL);

      if (!rqst.randomize()) // late randomization
        uvm_report_error("randomize", "failed to randomize rqst");

      finish_item(rqst); // send to the driver
      uvm_report_info("debug", "finish_item(): done", UVM_FULL);

      // waiting for item_done()
    end

  endtask : body

endclass

`endif // TOPSEQUENCE_SVH
