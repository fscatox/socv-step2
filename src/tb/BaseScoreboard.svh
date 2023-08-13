/**
 * File              : BaseScoreboard.svh
 *
 * Description       : listens on the monitor analysis ports to validate DUT
 *                     responses. The RspTxn encapsulate the request data, which
 *                     is used to compute the expected response. The comparison
 *                     results are written to a file. Child classes must implement
 *                     the comparison logic.
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

`ifndef BASESCOREBOARD_SVH
`define BASESCOREBOARD_SVH

virtual class BaseScoreboard extends uvm_scoreboard;
  `uvm_component_utils(BaseScoreboard)

  uvm_analysis_imp#(RspTxn, BaseScoreboard) analysis_export;

  int unsigned n_xpected, n_total;
  int unsigned n_errors;

  bit has_cov;

  bit ok_to_end; // prevent the simulation to end before the monitor has captured the last response

  /* log comparison results to file */
  string scb_file;
  int fd;

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

    if (!uvm_config_db#(string)::get(this, "", "scb_file", scb_file))
      uvm_report_fatal("config_db", "can't get scb_file");
    else
      uvm_report_info("debug", "got scb_file", UVM_FULL);

    n_total = 0;
    n_errors = 0;

    ok_to_end = 0;

  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    fd = $fopen(scb_file, "w");

    if (fd)
      uvm_report_info("debug", "scoreboard file opened", UVM_FULL);
    else
      uvm_report_fatal("file_mgmt", "can't open scoreboard file");

    set_report_id_file("scoreboard", fd);
    set_report_severity_id_action(UVM_ERROR, "scoreboard", UVM_DISPLAY | UVM_COUNT | UVM_LOG);
    set_report_severity_id_action(UVM_INFO, "scoreboard", UVM_LOG);

    if (uvm_report_enabled(UVM_FULL))
      dump_report_state();

  endfunction : end_of_elaboration_phase

  pure virtual function void generate_prediction(RspTxn t);

  virtual function void write(RspTxn t);
    RspTxn xpected;
    $cast(xpected, t.clone()); // clone the request fields
    xpected.set_name("xpected");

    generate_prediction(xpected);

    if (!xpected.compare(t)) begin
      n_errors++;

      uvm_report_error("scoreboard", $sformatf("MISMATCH!\n %s\n %s",
        xpected.convert2string(), t.convert2string() ));
    end else
      uvm_report_info("scoreboard", "MATCH!");

    n_total++;
    uvm_report_info("debug", $sformatf("n_total: %0d", n_total), UVM_HIGH);

    if (n_total == n_xpected) begin
      ok_to_end = 1;
      uvm_report_info("debug", "ok_to_end", UVM_FULL);
    end

  endfunction : write

  virtual function void phase_ready_to_end(uvm_phase phase);
    if (!ok_to_end) begin
      phase.raise_objection(this, "scoreboard: n_total != n_xpected");

      fork begin
        wait(ok_to_end);
        uvm_report_info("debug", "phase_ready_to_end(): waked up", UVM_FULL);

        phase.drop_objection(this, "scoreboard: n_total == n_xpected");
      end join_none

    end
  endfunction : phase_ready_to_end

  virtual function void final_phase(uvm_phase phase);
    uvm_report_info("final", {"Scoreboard Summary:\n", convert2string()});

    if ((n_xpected != n_total) || n_errors)
      uvm_report_error("final", "TEST FAILED");
    else
      uvm_report_info("final", "TEST PASSED");

    $fclose(fd);
    uvm_report_info("debug", "printer file closed", UVM_FULL);

  endfunction : final_phase

  function string convert2string();
    string s;

    $sformat(s, " Transactions: %0d out of %0d\n", n_total, n_xpected);
    $sformat(s, "%s Errors      : %0d\n", s, n_errors);

    if (has_cov)
      $sformat(s, "%s Coverage    : %.2f%%\n", s, $get_coverage);

    return s;
  endfunction : convert2string

endclass

`endif // BASESCOREBOARD_SVH

