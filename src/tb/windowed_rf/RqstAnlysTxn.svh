/**
 * File              : RqstAnlysTxn.svh
 *
 * Description       : extends RqstTxn adding DUT inputs to be used for
 *                     analysis purposes but discarded for the comparison.
 *                     The scoreboard won't verify the dut-mmu interaction
 *                     cycles directly, but only through read/write
 *                     operations.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 10.08.2023
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

`ifndef RQSTANLYSTXN_SVH
`define RQSTANLYSTXN_SVH

class RqstAnlysTxn extends RqstTxn;
  `uvm_object_utils(RqstAnlysTxn)

  data_t mmu_data;
  bit mmu_done;

  function new(string name = "RqstAnlysTxn");
    super.new(name);
  endfunction

  virtual function void do_copy(uvm_object rhs);
    RqstAnlysTxn rhs_;

    if (!$cast(rhs_, rhs))
      uvm_report_fatal("do_copy", "wrong rhs type");

    super.do_copy(rhs);

    this.mmu_data = rhs_.mmu_data;
    this.mmu_done = rhs_.mmu_done;

  endfunction : do_copy

  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    RqstAnlysTxn rhs_;

    if (!$cast(rhs_, rhs)) begin
      uvm_report_error("do_copy", "wrong rhs type");
      return 0;
    end

    return super.do_compare(rhs, comparer);

  endfunction : do_compare

  virtual function string convert2string();

    return {
      super.convert2string(), "\n",
      $sformatf(" mmu_data \t%x\n", mmu_data),
      $sformatf(" mmu_done \t%b\n", mmu_done)
    };

  endfunction : convert2string

endclass

`endif // RQSTANLYSTXN_SVH
