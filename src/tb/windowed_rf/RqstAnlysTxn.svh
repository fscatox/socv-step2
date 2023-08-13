/**
 * File              : RqstAnlysTxn.svh
 *
 * Description       : extends RqstTxn adding monitor-to-scoreboard analysis
 *                     fields required for late-correction of scoreboard
 *                     predictions. This is because the behavioral DUT that
 *                     generates the predictions is instantiated in the
 *                     scoreboard and runs at each incoming response. Instead,
 *                     a reset request can cut short pending call/return
 *                     operations. In addition, mmu outputs are sampled as
 *                     part of the request to the DUT, but having made the
 *                     choice to have a single analysis communication channel
 *                     from the monitor to scoreboard, printer and coverage
 *                     collector, there's no way to separate requests from
 *                     response samples, which would be necessary to properly
 *                     examine the mmu/dut interaction. That being said, once
 *                     having made sure that the behavioral mmu implemented in
 *                     the testbench complies to the specifications, errors
 *                     in the DUT due to the interaction with the mmu would
 *                     still be caught, even though without additional info to
 *                     help designers. That is, the scoreboard doesn't verify
 *                     the dut-mmu interaction cycles directly, but only
 *                     through read/write operations and fill/spill signals.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 10.08.2023
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

`ifndef RQSTANLYSTXN_SVH
`define RQSTANLYSTXN_SVH

class RqstAnlysTxn extends RqstTxn;
  `uvm_object_utils(RqstAnlysTxn)

  data_t mmu_data;
  bit mmu_done;

  bit aborted;

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
    this.aborted = rhs_.aborted;

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
      $sformatf(" mmu_done \t%b\n", mmu_done),
      $sformatf(" aborted  \t%b\n", aborted)
    };

  endfunction : convert2string

endclass

`endif // RQSTANLYSTXN_SVH
