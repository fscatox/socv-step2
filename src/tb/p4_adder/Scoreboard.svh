/**
 * File              : Scoreboard.svh
 *
 * Description       : extends BaseScoreboard specifying an analysis
 *                     communication target and a predictor. A prediction
 *                     function is called inside the write() method of the
 *                     analysis implementation.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
 * Last Modified Date: 11.08.2023
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

`ifndef SCOREBOARD_SVH
`define SCOREBOARD_SVH

class Scoreboard extends BaseScoreboard;
  `uvm_component_utils(Scoreboard)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
  endfunction

  virtual function void generate_prediction(RspTxn t);

    // compute addition
    {t.cout, t.s} = t.a + t.b + t.cin;

    uvm_report_info("debug", $sformatf("generate_prediction(): %s", t.convert2string()), UVM_FULL);

  endfunction : generate_prediction

endclass

`endif // SCOREBOARD_SVH

