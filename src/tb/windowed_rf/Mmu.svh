/**
 * File              : Mmu.svh
 *
 * Description       : handles filling/spilling requests from the dut.
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

class Mmu;

  /* set by the driver */
  string name;
  vif_mmu_t vif;

  /* behavioral stack in main memory */
  data_t mem[$];
  const byte unsigned cycles; // cycles required to fill/spill a single register

  function new(string name, vif_mmu_t vif);
    this.name = name;
    this.vif = vif;

    if (NBIT % NBIT_MEM)
      uvm_report_warning(name, "rounding up cycles");

    cycles = $ceil(real'(NBIT) / NBIT_MEM);
    uvm_report_info("debug", $sformatf("cycles: %0d", cycles), UVM_FULL);
  endfunction : new

  task run();

    /* fsm thread handler */
    process fsm_th;
    string dump;

    forever begin

      fork // separate fsm and synchronous reset

      begin : fsm_p

        fsm_th = process::self();
        uvm_report_info("debug", "starting", UVM_FULL);

        forever begin
          @(vif.mmu_cb);

          if (vif.mmu_cb.spill) begin
            do begin

              /* consume writing cycles */
              repeat(cycles-1) begin
                @(vif.mmu_cb);
                uvm_report_info("debug", "dummy write", UVM_FULL);
              end

              /* wake up in the last one: signal it */
              vif.mmu_cb.mmu_done <= 1;

              /* move to the sampling edge */
              @(vif.mmu_cb);
              mem.push_back(vif.mmu_cb.out1);

              uvm_report_info("debug", "written", UVM_FULL);
              if ($isunknown(vif.mmu_cb.out1))
                uvm_report_warning("capture", "dut outputs unknown bits");

            end while (vif.mmu_cb.spill); // the rf may have asserted spill again

            dump = "";
            foreach (mem[i])
              $sformat(dump, " mem[%0d] \t\t = %x\n", i, mem[i]);

            uvm_report_info("debug", {"dump\n", dump}, UVM_FULL);
            uvm_report_info("debug", "dump end", UVM_FULL);
          end

          else if (vif.mmu_cb.fill) begin

            /* consume reading cycles */
            repeat(cycles-1) begin
              @(vif.mmu_cb);
              uvm_report_info("debug", "dummy read", UVM_FULL);
            end

            /* wake up in the last one: signal it */
            vif.mmu_cb.mmu_done <= 1;

            /* mmu_data becomes valid in the clock cycle after
             * the rising edge of mmu_done */
            @(vif.mmu_cb);
            vif.mmu_cb.mmu_data <= mem.pop_back();
            uvm_report_info("debug", "read", UVM_FULL);

          end
        end
      end : fsm_p

      /* in case of a reset, restart the machine */
      begin : synch_reset_p

        do
          @(vif.mmu_cb);
        while (!vif.mmu_cb.reset);

        if (fsm_th == null)
          uvm_report_fatal(name, "null thread handler");

      end : synch_reset_p

      join_any // the synchronous reset thread

      uvm_report_info("debug", "got reset", UVM_FULL);

      fsm_th.kill();
      uvm_report_info("debug", {"fsm thread: ", fsm_th.status().name()}, UVM_FULL);

      fsm_th = null;
      mem.delete();

    end

  endtask : run

endclass
