/**
 * File              : Scoreboard.svh
 *
 * Description       : listens on the monitor analysis ports and validates DUT
 *                     responses. The RspTxn encapsulate the request data,
 *                     which is used to compute the expected response.
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

`ifndef SCOREBOARD_SVH
`define SCOREBOARD_SVH

class Scoreboard extends uvm_scoreboard;
  `uvm_component_utils(Scoreboard)

  int unsigned n_xpected, n_total;
  int unsigned n_errors;

  bit has_cov;

  uvm_analysis_imp#(RspTxn, Scoreboard) analysis_export;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    analysis_export = new("analysis_export", this);

    if (!uvm_config_db#(int unsigned)::get(this, "", "n_xpected", n_xpected))
      uvm_report_fatal("config_db", "can't get n_xpected");
    else
      uvm_report_info("debug", "got n_xpected", UVM_FULL);

    if (!uvm_config_db#(bit)::get(this, "", "has_cov", has_cov))
      uvm_report_fatal("config_db", "can't get has_cov");
    else
      uvm_report_info("debug", "got has_cov", UVM_FULL);

    n_total = 0;
    n_errors = 0;

  endfunction : build_phase

  virtual function void write(RspTxn t);
    RspTxn xpected;
    $cast(xpected, t.clone()); // clone the request fields
    xpected.set_name("xpected");

    generate_prediction(xpected);

    if (!xpected.compare(t)) begin
      n_errors++;

      uvm_report_error("scoreboard", $sformatf("MISMATCH!\n Expected: %s\n Actual: %s",
        xpected.convert2string(), t.convert2string() ));
    end

    n_total++;
    uvm_report_info("debug", $sformatf("n_total: %0d", n_total), UVM_FULL);

  endfunction : write

  virtual function void final_phase(uvm_phase phase);
    uvm_report_info("final", {"Scoreboard Summary:\n", convert2string()});

    if ((n_xpected != n_total) || n_errors)
      uvm_report_error("final", "TEST FAILED");
    else
      uvm_report_info("final", "TEST PASSED");

  endfunction : final_phase

  function void generate_prediction(RspTxn t);

    // compute addition
    {t.cout, t.s} = t.a + t.b + t.cin;

    uvm_report_info("debug", $sformatf("generate_prediction(): %s", t.convert2string()), UVM_FULL);

  endfunction : generate_prediction

  function string convert2string();
    string s;

    $sformat(s, " Transactions: %0d out of %0d\n", n_total, n_xpected);
    $sformat(s, "%s Errors      : %0d\n", s, n_errors);

    if (has_cov)
      $sformat(s, "%s Coverage    : %.2f%%\n", s, $get_coverage);

    return s;
  endfunction : convert2string

endclass

`endif // SCOREBOARD_SVH

