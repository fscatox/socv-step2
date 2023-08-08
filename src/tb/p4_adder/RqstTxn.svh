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
 * Date              : 05.08.2023
 * Last Modified Date: 08.08.2023
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

  rand data_t a, b;
  rand bit cin;

  function new(string name = "RqstTxn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    RqstTxn rhs_;

    if (!$cast(rhs_, rhs))
      uvm_report_fatal("do_copy", "wrong rhs type");

    super.do_copy(rhs);

    this.a = rhs_.a;
    this.b = rhs_.b;
    this.cin = rhs_.cin;

  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    RqstTxn rhs_;

    if (!$cast(rhs_, rhs)) begin
      uvm_report_error("do_copy", "wrong rhs type");
      return 0;
    end

    return (
      super.do_compare(rhs, comparer) &&
      (this.a == rhs_.a) &&
      (this.b == rhs_.b) &&
      (this.cin == rhs_.cin));

  endfunction : do_compare

  virtual function string convert2string();
    return $sformatf("%s\n %s\n a \t%x\n b \t%x\n cin \t%b\n",
      super.convert2string(), this.get_name(), a, b, cin);
   endfunction : convert2string

endclass

`endif // RQSTTXN_SVH
