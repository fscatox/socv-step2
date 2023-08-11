/**
 * File              : RspTxn.svh
 *
 * Description       : response transaction extracted from the DUT by the
 *                     monitor. The "bypass" field is used by the monitor
 *                     to determine when the sequence resumes execution. In
 *                     case of call and ret operations, out1 and out2 are not
 *                     taken into account for the comparison, unless reset is
 *                     high.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 10.08.2023
 * Last Modified Date: 10.08.2023
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

class RspTxn extends RqstAnlysTxn;
  `uvm_object_utils(RspTxn)

  data_t out1, out2;
  bit bypass;
  bit fill, spill;

  function new(string name = "RspTxn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    RspTxn rhs_;

    if (!$cast(rhs_, rhs))
      uvm_report_fatal("do_copy", "wrong rhs type");

    super.do_copy(rhs);

    this.out1 = rhs_.out1;
    this.out2 = rhs_.out2;
    this.bypass = rhs_.bypass;
    this.fill = rhs_.fill;
    this.spill = rhs_.spill;

  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    bit ret = super.do_compare(rhs, comparer);
    RspTxn rhs_;

    if (!$cast(rhs_, rhs)) begin
      uvm_report_error("do_copy", "wrong rhs type");
      return 0;
    end

    ret = ret && (this.spill == rhs_.spill) && (this.fill == rhs_.fill);

    if (reset || (!call && !ret))
      ret = ret && (this.out1 == rhs_.out1) && (this.out2 == rhs_.out2);

    return ret;

  endfunction : do_compare

  virtual function string convert2string();

    return {
      super.convert2string(), "\n",
      $sformatf(" out1 \t%x\n", out1),
      $sformatf(" out2 \t%x\n", out2),
      $sformatf(" bypass \t%b\n", bypass),
      $sformatf(" fill \t%b\n", fill),
      $sformatf(" spill \t%b\n", spill)
    };

   endfunction : convert2string

endclass

`endif // RSPTXN_SVH
