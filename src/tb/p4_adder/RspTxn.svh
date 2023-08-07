/**
 * File              : RspTxn.svh
 *
 * Description       : response transaction extracted from the DUT by the
 *                     monitor
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 05.08.2023
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

`ifndef RSPTXN_SVH
`define RSPTXN_SVH

class RspTxn extends RqstTxn;
  `uvm_object_utils(RspTxn)

  p4_adder_pkg::data_t s;
  bit cout;

  function new(string name = "RspTxn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    RspTxn rhs_;

    if (!$cast(rhs_, rhs))
      uvm_report_fatal("do_copy", "wrong rhs type");

    super.do_copy(rhs);

    this.s = rhs_.s;
    this.cout = rhs_.cout;

  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    RspTxn rhs_;

    if (!$cast(rhs_, rhs)) begin
      uvm_report_error("do_copy", "wrong rhs type");
      return 0;
    end

    return (
      super.do_compare(rhs, comparer) &&
      (this.s == rhs_.s) &&
      (this.cout == rhs_.cout));

  endfunction : do_compare

  virtual function string convert2string();
    return $sformatf("%s\n %s\n s \t%x\n cout \t%b\n",
      super.convert2string(), this.get_name(), s, cout);
   endfunction : convert2string

endclass

`endif // RSPTXN_SVH
