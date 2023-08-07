/**
 * File              : Printer.svh
 *
 * Description       : listens on the monitor analysis port and prints the
 *                     broadcasted transactions to the screen and to a file.
 *                     Quiet tests, which don't display transaction on the
 *                     screen, can be developed by overriding the Printer
 *                     class with the BitBucket child class.
 *
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

`ifndef PRINTER_SVH
`define PRINTER_SVH

class Printer extends uvm_subscriber#(RspTxn);
  `uvm_component_utils(Printer)

  /* log transactions to file */
  string prt_file;
  int fd;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);

    if (!uvm_config_db#(string)::get(this, "", "prt_file", prt_file))
      uvm_report_fatal("config_db", "can't get prt_file");
    else
      uvm_report_info("debug", "got prt_file", UVM_FULL);

  endfunction : build_phase

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    fd = $fopen(prt_file, "w");

    if (fd)
      uvm_report_info("debug", "printer file opened", UVM_FULL);
    else
      uvm_report_fatal("file_mgmt", "can't open printer file");

    set_report_id_file("printer", fd);
    set_report_id_action("printer", UVM_DISPLAY | UVM_LOG);

    if (uvm_report_enabled(UVM_FULL))
      dump_report_state();

  endfunction : end_of_elaboration_phase

  virtual function void final_phase(uvm_phase phase);

    $fclose(fd);
    uvm_report_info("debug", "printer file closed", UVM_FULL);

  endfunction : final_phase

  virtual function void write(RspTxn t);

    uvm_report_info("printer", t.convert2string());

  endfunction : write

endclass

class BitBucket extends Printer;
  `uvm_component_utils(BitBucket)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);

    // disable display for printer messages
    set_report_id_action("printer", UVM_LOG);

    if (uvm_report_enabled(UVM_FULL))
      dump_report_state();

  endfunction : end_of_elaboration_phase


endclass

`endif // PRINTER_SVH

