/**
 * File              : TopSequence.svh
 *
 * Description       : assembles the desired stream of sequence items by
 *                     configuring and calling sub-sequences for FullTest.
 *                     This class is test-specific, and additional tests can
 *                     override it with the factory.
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

  ResetSequence reset_seq;
  TestSequence#(10,0,0,0)    a_seq; // no repeated call/ret, no reset
  TestSequence#(25,0,5,0)    b_seq; // no repeated call/ret/reset, sparingly reset
  TestSequence#(30,40,30,20) c_seq; // possibly repeated call/ret/reset

  function new(string name = "TopSequence");
    super.new(name);
  endfunction

  task body();
    reset_seq = ResetSequence::type_id::create("reset_seq");
    a_seq = TestSequence#(10,0,0,0)::type_id::create("a_seq");
    b_seq = TestSequence#(25,0,5,0)::type_id::create("b_seq");
    c_seq = TestSequence#(30,40,30,20)::type_id::create("c_seq");

    reset_seq.start(m_sequencer, this);
    a_seq.start(m_sequencer, this);
    b_seq.start(m_sequencer, this);
    c_seq.start(m_sequencer, this);

  endtask : body

endclass

`endif // TOPSEQUENCE_SVH
