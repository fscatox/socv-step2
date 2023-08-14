/**
 * File              : CnstRqstTxn.svh
 *
 * Description       : extends RqstTxn adding constraints to ensure the
 *                     validity of the stimulus. Before randomizing
 *                     an object, a "profile" must have been set by calling
 *                     "set_profile()" with the following arguments:
 *                       - call_ret_weight, weight for call/ret operations
 *                       - call_ret_enhanced, weight for the call/ret
 *                         operation after having already issued it
 *                       - reset_weight
 *                       - reset_enhanced
 *                     Tests can use it via factory override.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 12.08.2023
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

`ifndef CNSTRQSTTXN_SVH
`define CNSTRQSTTXN_SVH

class CnstRqstTxn extends RqstTxn;
  `uvm_object_utils(CnstRqstTxn)

  /* randomization "profile" */
  byte unsigned CALL_RET_WEIGHT,
                RESET_WEIGHT;

  byte unsigned CALL_RET_ENHANCED,
                RESET_ENHANCED;

  /* call/return balancing:
   * count how many returns are possible */
  int unsigned can_return;

  /* consecutive operations */
  byte unsigned call_weight, ret_weight, reset_weight;
  bit call_h, ret_h, reset_h;


  function void set_profile(
    byte unsigned call_ret_weight,
    byte unsigned call_ret_enhanced,
    byte unsigned reset_weight,
    byte unsigned reset_enhanced);

    CALL_RET_WEIGHT = call_ret_weight;
    CALL_RET_ENHANCED = call_ret_enhanced;
    RESET_WEIGHT = reset_weight;
    RESET_ENHANCED = reset_enhanced;

    uvm_report_info("randomize", {
      "profile:\n",
      $sformatf(" call_ret_weight:  \t%0d\n", CALL_RET_WEIGHT),
      $sformatf(" call_ret_enhanced:\t%0d\n", CALL_RET_ENHANCED),
      $sformatf(" reset_weight:     \t%0d\n", RESET_WEIGHT),
      $sformatf(" reset_enhanced:   \t%0d\n", RESET_ENHANCED)}, UVM_HIGH);

    /* initialization */
    call_weight  = CALL_RET_WEIGHT;
    ret_weight   = CALL_RET_WEIGHT;
    this.reset_weight = RESET_WEIGHT;

  endfunction : set_profile

  function new(string name = "CnstRqstTxn");
    super.new(name);
    can_return = 0;

    call_h       = 0;
    ret_h        = 0;
    reset_h      = 0;
  endfunction

  function void post_randomize();

    /* balance */
    if (reset)
      can_return = 0;
    else begin // could be both call and ret, but call wins
      uvm_report_info("debug",
        $sformatf("can_return = %0d + %b - %b", can_return, call, (ret && !call)), UVM_HIGH);

      can_return += call;
      can_return -= (ret && !call);
    end

    /* op repetition */
    if (reset_h) begin  // twice in a row?
      reset_h = 0;
      reset_weight = RESET_WEIGHT;
    end else if (reset) begin
      reset_h = 1;
      reset_weight = RESET_ENHANCED; // change weight to make it more likely
    end

    if (call_h) begin
      call_h = 0;
      call_weight = CALL_RET_WEIGHT;
    end else if (!reset && call) begin
      call_h = 1;
      call_weight = CALL_RET_ENHANCED;
    end

    if (ret_h) begin
      ret_h = 0;
      ret_weight = CALL_RET_WEIGHT;
    end else if (!reset && !call && ret) begin
      ret_h = 1;
      ret_weight = CALL_RET_ENHANCED;
    end

  endfunction : post_randomize

  constraint valid_ret_c {
    ret  dist {
      0 := (100-ret_weight),
      1 := (can_return ? ret_weight : 0)
    };
  }

  constraint frequency_c {

    call dist {
      0 := (100-call_weight),
      1 := call_weight
    };

    reset dist {
      0 := (100-reset_weight),
      1 := reset_weight
    };

    enable dist {
      0 := 3,
      1 := 7
    };

    /* target ins and outs frequently */
    add_rd1 dist {
      [NGLOBALS+2*NLOCALS : NGLOBALS+3*NLOCALS-1] := 2, // ins
      [NGLOBALS+NLOCALS   : NGLOBALS+2*NLOCALS-1] := 1, // locals
      [NGLOBALS           : NGLOBALS+NLOCALS-1]   := 2, // outs
      [0                  : NGLOBALS-1]           := 1  // globals
    };
    add_rd2 dist {
      [NGLOBALS+2*NLOCALS : NGLOBALS+3*NLOCALS-1] := 2,
      [NGLOBALS+NLOCALS   : NGLOBALS+2*NLOCALS-1] := 1,
      [NGLOBALS           : NGLOBALS+NLOCALS-1]   := 2,
      [0                  : NGLOBALS-1]           := 1
    };
    add_wr dist {
      [NGLOBALS+2*NLOCALS : NGLOBALS+3*NLOCALS-1] := 2,
      [NGLOBALS+NLOCALS   : NGLOBALS+2*NLOCALS-1] := 1,
      [NGLOBALS           : NGLOBALS+NLOCALS-1]   := 2,
      [0                  : NGLOBALS-1]           := 1
    };

  }

  constraint no_writing_zero_c {
    !(datain inside {0});
  }

endclass

`endif  // CNSTRQSTTXN_SVH


