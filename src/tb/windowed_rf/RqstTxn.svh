/**
 * File              : RqstTxn.svh
 *
 * Description       : base request transaction translated by the driver
 *                     to pin wiggles. Tests can use the factory to override
 *                     with a child class that includes stimulus-specific
 *                     constraints
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

`ifndef RQSTTXN_SVH
`define RQSTTXN_SVH

class RqstTxn extends uvm_sequence_item;
  `uvm_object_utils(RqstTxn)

  rand bit reset;

  rand bit enable;
  rand bit rd1, rd2, wr;

  rand addr_t add_rd1, add_rd2, add_wr;
  rand data_t datain;

  rand bit call, ret;

  function new(string name = "RqstTxn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    RqstTxn rhs_;

    if (!$cast(rhs_, rhs))
      uvm_report_fatal("do_copy", "wrong rhs type");

    super.do_copy(rhs);

    this.reset = rhs_.reset;
    this.enable = rhs_.enable;
    this.rd1 = rhs_.rd1;
    this.rd2 = rhs_.rd2;
    this.wr = rhs_.wr;
    this.add_rd1 = rhs_.add_rd1;
    this.add_rd2 = rhs_.add_rd2;
    this.add_wr = rhs_.add_wr;
    this.datain = rhs_.datain;
    this.call = rhs_.call;
    this.ret = rhs_.ret;

  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    RqstTxn rhs_;

    if (!$cast(rhs_, rhs)) begin
      uvm_report_error("do_copy", "wrong rhs type");
      return 0;
    end

    return (
      super.do_compare(rhs, comparer) &&
      (this.reset == rhs_.reset) &&
      (this.enable == rhs_.enable) &&
      (this.rd1 == rhs_.rd1) &&
      (this.rd2 == rhs_.rd2) &&
      (this.wr == rhs_.wr) &&
      (this.add_rd1 == rhs_.add_rd1) &&
      (this.add_rd2 == rhs_.add_rd2) &&
      (this.add_wr == rhs_.add_wr) &&
      (this.datain == rhs_.datain) &&
      (this.call == rhs_.call) &&
      (this.ret == rhs_.ret)
    );

  endfunction : do_compare

  virtual function string convert2string();

    return {
      super.convert2string(), "\n",
      this.get_name(), "\n",
      $sformatf(" datain \t%x\n", datain),
      $sformatf(" rd1    \t%b\n", rd1),
      $sformatf(" rd2    \t%b\n", rd2),
      $sformatf(" wr     \t%b\n", wr),
      $sformatf(" add_rd1 \t%0d\n", add_rd1),
      $sformatf(" add_rd2 \t%0d\n", add_rd2),
      $sformatf(" add_wr \t%0d\n", add_wr),
      $sformatf(" call   \t%b\n", call),
      $sformatf(" ret    \t%b\n", ret),
      $sformatf(" reset  \t%b\n", reset),
      $sformatf(" enable \t%b\n", enable)
    };

   endfunction : convert2string

endclass

`endif // RQSTTXN_SVH
