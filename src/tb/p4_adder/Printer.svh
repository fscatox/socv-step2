/**
 * File              : Printer.svh
 *
 * Description       : listens on the monitor analysis ports and prints the
 *                     broadcasted transactions. Quiet tests can be developed
 *                     by overriding with the BitBucket child class
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 06.08.2023
 * Last Modified Date: 06.08.2023
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

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void write(RspTxn t);

    uvm_report_info("printer", t.convert2string());

  endfunction : write

endclass

class BitBucket extends Printer;
  `uvm_component_utils(BitBucket)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void write(RspTxn t);
  endfunction : write

endclass

`endif // PRINTER_SVH

