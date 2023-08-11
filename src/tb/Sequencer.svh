/**
 * File              : Sequencer.svh
 *
 * Description       : arbitrates the flow of sequence items to the driver
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 05.08.2023
 * Last Modified Date: 05.08.2023
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

`ifndef SEQUENCER_SVH
`define SEQUENCER_SVH

class Sequencer extends uvm_sequencer#(RqstTxn);
  `uvm_component_utils(Sequencer)

  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // SEQUENCER_SVH
