/**
 * File              : BehWindowedRf.svh
 *
 * Description       : the windowed rf is modelled as a stack of register
 *                     sets (as explained in the SPARC Architecture Manual),
 *                     whereas spill and fill are generated treating the
 *                     stack as a circular buffer, with two pointers to
 *                     detect the corresponding full and empty conditions.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 11.08.2023
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

`ifndef BEHWINDOWEDRF_SVH
`define BEHWINDOWEDRF_SVH

class BehWindowedRf extends uvm_component;
  `uvm_component_utils(BehWindowedRf)
  typedef data_t [NLOCALS] subset_t;

  /* storage */
  subset_t stack[$];
  data_t [NGLOBALS] globals;
  data_t out1, out2; // current outputs

  /* mngmt */
  int signed locals_idx;
  int signed cwp, swp; // circular buffer

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    reset();
  endfunction

  function void reset();
    /* initial value for bit is 'b0 */
    subset_t zero_subset;
    out1 = 0;
    out2 = 0;

    stack = {zero_subset, zero_subset, zero_subset};
    foreach (globals[i])
      globals[i] = 0;

    /* initial window */
    locals_idx = 1; // 0 -> in, 1 -> locals -> 2-> out
    cwp = 0;
    swp = NWINDOWS-1;

    uvm_report_info("debug", "reset done", UVM_HIGH);

  endfunction : reset

  /* returns 1 for spill */
  function bit call();
    subset_t zero_subset;
    uvm_report_info("debug",
      $sformatf("call: @ locals_idx %0d, cwp %0d, swp %0d", locals_idx, cwp, swp), UVM_HIGH);

    /* add local and out */
    locals_idx += 2;
    stack.push_back(zero_subset);
    stack.push_back(zero_subset);

    /* circular mgmt */
    cwp = (cwp + 1) % NWINDOWS;

    if (cwp == swp) begin
      swp = (swp + 1) % NWINDOWS;
      uvm_report_info("debug", "spill", UVM_HIGH);
      return 1;
    end

    uvm_report_info("debug",
      $sformatf("call: now locals_idx %0d, cwp %0d, swp %0d", locals_idx, cwp, swp), UVM_FULL);
    return 0;
  endfunction : call

  /* returns 1 for fill */
  function bit ret();
    uvm_report_info("debug",
      $sformatf("ret: @ locals_idx %0d, cwp %0d, swp %0d", locals_idx, cwp, swp), UVM_HIGH);

    /* remove local and out */
    locals_idx -= 2;
    if (locals_idx > 0) begin
      void'(stack.pop_back());
      void'(stack.pop_back());

      if (fill_mgmt(1)) begin
        uvm_report_info("debug", "fill", UVM_HIGH);
        return 1;
      end

    end else
      uvm_report_error("ret", "too many return");

    uvm_report_info("debug",
      $sformatf("ret: now locals_idx %0d, cwp %0d, swp %0d", locals_idx, cwp, swp), UVM_HIGH);
    return 0;

  endfunction : ret

  /* compute whether a fill is going to occurr */
  function bit fill_mgmt(bit update = 0);
    int signed local_cwp = cwp;
    int signed local_swp = swp;
    bit ret = 0;

    /* circular mgmt */
    local_cwp = (local_cwp - 1) % NWINDOWS;
    if (local_cwp < 0)
      local_cwp += NWINDOWS;

    if (local_cwp == local_swp) begin
      local_swp = (local_swp - 1) % NWINDOWS;
      if (local_swp < 0)
        local_swp += NWINDOWS;

      ret = 1;
    end

    if (update) begin
      cwp = local_cwp;
      swp = local_swp;
    end

    return ret;

  endfunction : fill_mgmt

  function void update(RspTxn t);
    t.fill = 0;
    t.spill = 0;

    /* reset has highest priority */
    if (t.reset)
      reset();

    /* call wins over ret and both win over enable */
    else if (t.call) begin
      if (t.aborted) begin
        uvm_report_info("debug", "aborting call", UVM_HIGH);
        t.spill = 0;
      end else
        t.spill = call();
    end

    else if (t.ret) begin
      if (t.aborted) begin
        t.fill = fill_mgmt();
        uvm_report_info("debug", "aborting ret", UVM_HIGH);
      end else
        t.fill = ret();
    end

    /* normal operation */
    else if (t.enable) begin
      /* read before write */
      if (t.rd1)
        out1 = read(t.add_rd1);

      if (t.rd2)
        out2 = read(t.add_rd2);

      if (t.wr)
        write(t.datain, t.add_wr);
    end

    t.out1 = out1;
    t.out2 = out2;

  endfunction : update

/*
   Addressing convention:
     Windowed Register Address  Register Address
       in[0] - in[N-1]            r[M+2*N] - r[M+3*N-1]
       local[0] - local[N-1]      r[M+N] - r[M+2*N-1]
       out[0] - out[N-1]          r[M] - r[M+N-1]
       global[0] - global[M-1]    r[0] - r[M-1]

   Mapping into the register file:

     |---------|
     | LOCAL 1 | M+2*N*F-1
     |         |
     |---------|
     |  IN  2  |
     | (OUT 1) |
     |---------|
     | LOCAL 2 |
     |         |
     |---------|
     |  IN  3  |
     | (OUT 2) |
     |---------|
     | LOCAL 3 |
     |         |
     |---------|
          .
          .
          .
     |---------|
     |  IN  0  | M+3*N-1
     |(OUT F-1)|
     |---------| M+2*N
     | LOCAL 0 | M+2*N-1
     |         |
     |---------| M+N
     |  IN  1  | M+N-1
     | (OUT 0) |
     |---------| M
     |         | M-1
     | GLOBALS |
     |         |
     |---------| 0
*/

  function bit decode(input addr_t addr,
                       output bit is_global,
                       output int unsigned stack_idx, output byte unsigned off);

    uvm_report_info("debug", $sformatf("addr: %0d", addr), UVM_FULL);
    is_global = 0;
    stack_idx = locals_idx;

    if (addr < NGLOBALS) begin
      is_global = 1;
      off = addr;
      uvm_report_info("debug", $sformatf("global: %0d", off), UVM_FULL);
      return 0;
    end

    if (addr < NGLOBALS + NLOCALS) begin
      off = addr-NGLOBALS;
      stack_idx++;
      uvm_report_info("debug",
        $sformatf("out: stack_idx %0d, off %0d", stack_idx, off), UVM_FULL);
      return 0;
    end

    if (addr < NGLOBALS + 2*NLOCALS) begin
      off = addr-(NGLOBALS+NLOCALS);
      uvm_report_info("debug",
        $sformatf("local: stack_idx %0d, off %0d", stack_idx, off), UVM_FULL);
      return 0;
    end

    if ({1'b0, addr} < NGLOBALS + 3*NLOCALS) begin
      off = addr-(NGLOBALS+2*NLOCALS);
      stack_idx--;
      uvm_report_info("debug",
        $sformatf("in: stack_idx %0d, off %0d", stack_idx, off), UVM_FULL);
      return 0;
    end

    uvm_report_error("decode", "out of range addr", UVM_FULL);
    return 1;

  endfunction : decode

  function data_t read(addr_t addr);
    bit is_global;
    int unsigned stack_idx;
    byte unsigned off;
    data_t ret;

    if (decode(addr, is_global, stack_idx, off))
      return 0;

    if (is_global)
      ret = globals[off];
    else
      ret = stack[stack_idx][off];

    uvm_report_info("debug", $sformatf("read: %x", ret), UVM_FULL);
    return ret;

  endfunction : read

  function void write(data_t data, addr_t addr);
    bit is_global;
    int unsigned stack_idx;
    byte unsigned off;

    if (decode(addr, is_global, stack_idx, off))
      return;

    if (is_global)
      globals[off] = data;
    else
      stack[stack_idx][off] = data;

    uvm_report_info("debug", $sformatf("written: %x", data), UVM_FULL);

  endfunction : write

  function string convert2string();
    string s = {get_name(), "\n"};

    foreach (globals[i])
      $sformat(s, "%s globals[%0d]: %x\n", s, i, globals[i]);

    foreach (stack[i,j])
      $sformat(s, "%s stack[%0d][%0d]: %x\n", s, i, j, stack[i][j]);

    return s;
  endfunction : convert2string

endclass

`endif // BEHWINDOWEDRF_SVH
