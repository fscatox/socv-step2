/**
 * File              : CnstRqstTxn.svh
 *
 * Description       : extends RqstTxn adding constraints to skew the stimulus
 *                     in such a way to increase coverage for the testcases.
 *                     Tests can use it via factory override.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 08.08.2023
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

`ifndef CNSTRQSTTXN_SVH
`define CNSTRQSTTXN_SVH

class CnstRqstTxn extends RqstTxn;
  `uvm_object_utils(CnstRqstTxn)

  function new(string name = "CnstRqstTxn");
    super.new(name);
  endfunction

  constraint ab_dist_c {
    a dist { // skew a towards the boundaries
      0                       := 1,
      [1 : {NBIT{1'b1}} - 1]  :/ 1, // spread
      {NBIT{1'b1}}            := 1
    };
    b dist {
      0                       := 1,
      [1 : {NBIT{1'b1}} - 1]  :/ 1, // spread
      {NBIT{1'b1}}            := 1
    };
  };

endclass

`endif  // CNSTRQSTTXN_SVH

