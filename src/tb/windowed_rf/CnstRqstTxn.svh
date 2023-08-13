/**
 * File              : CnstRqstTxn.svh
 *
 * Description       : extends RqstTxn adding constraints to ensure the
 *                     validity of the stimulus, while skewing it in such a
 *                     way to increase coverage for the testcases. Tests can
 *                     use it via factory override.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 12.08.2023
 * Last Modified Date: 12.08.2023
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

  `define CALL_RET_WEIGHT   10
  `define RESET_WEIGHT      3
  `define CALL_RET_ENHANCED 25
  `define RESET_ENHANCED    25

  /* call/return balancing:
   * count how many returns are possible */
  int unsigned can_return;

  /* consecutive operations */
  byte unsigned call_weight, ret_weight, reset_weight;
  bit call_h, ret_h, reset_h;

  function new(string name = "CnstRqstTxn");
    super.new(name);
    can_return = 0;

    call_weight  = `CALL_RET_WEIGHT;
    call_h       = 0;

    ret_weight   = `CALL_RET_WEIGHT;
    ret_h        = 0;

    reset_weight = `RESET_WEIGHT;
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
    if (reset_h) begin
      reset_h = 0;
      reset_weight = `RESET_WEIGHT;
    end else if (reset) begin
      reset_h = 1;
      reset_weight = `RESET_ENHANCED;
    end

    if (call_h) begin
      call_h = 0;
      call_weight = `CALL_RET_WEIGHT;
    end else if (!reset && call) begin
      call_h = 1;
      call_weight = `CALL_RET_ENHANCED;
    end

    if (ret_h) begin
      ret_h = 0;
      ret_weight = `CALL_RET_WEIGHT;
    end else if (!reset && !call && ret) begin
      ret_h = 1;
      ret_weight = `CALL_RET_ENHANCED;
    end

  endfunction : post_randomize

  constraint valid_ret_c {
    ret  dist {
      0 := (100-ret_weight),
      1 := (can_return ? ret_weight : 0)
    };
  }

  constraint sparingly_c {

    reset dist {
     0 := (100-reset_weight),
     1 := reset_weight
    };

    call dist {
      0 := (100-call_weight),
      1 := call_weight
    };
  }

  constraint frequently_c {

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


