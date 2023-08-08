/**
 * File              : StmCoverage.svh
 *
 * Description       : extends Coverage adding coverage for the testcases of
 *                     the p4 adder verification plan.
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

`ifndef STMCOVERAGE_SVH
`define STMCOVERAGE_SVH

class StmCoverage extends Coverage;
  `uvm_component_utils(StmCoverage)

  covergroup cnst_rqst_txn_cg;

    a_cp : coverpoint txn.a {

      bins zeros  = { 0 };
      bins others = { [1:{NBIT{1'b1}}-1] };
      bins ones   = { {NBIT{1'b1}} };

      /* don't count the coverpoint alone */
      type_option.weight = 0;

    }

    b_cp : coverpoint txn.b {

      bins zeros  = { 0 };
      bins others = { [1:{NBIT{1'b1}}-1] };
      bins ones   = { {NBIT{1'b1}} };

      /* don't count the coverpoint alone */
      type_option.weight = 0;

    }

    cin_cp : coverpoint txn.cin {

      /* don't count the coverpoint alone */
      type_option.weight = 0;

    }

    a_cp_cross_b_cp : cross a_cp, b_cp {

      /* testcase 1.1 */
      bins one_zeros   = (binsof(a_cp.zeros) &&
                           (binsof(b_cp.others) || binsof(b_cp.ones))) || // a zeros, b not
                         (binsof(b_cp.zeros) &&
                           (binsof(a_cp.others) || binsof(a_cp.ones)));   // b zeros, a not

      /* testcase 1.2 */
      bins both_zeros  = binsof(a_cp.zeros) && binsof(b_cp.zeros);

      /* testcase 2.1 */
      bins one_ones    = (binsof(a_cp.ones) &&
                           (binsof(b_cp.zeros) || binsof(b_cp.others))) || // a ones, b not
                         (binsof(b_cp.ones) &&
                           (binsof(a_cp.zeros) || binsof(a_cp.others)));   // b ones, a not

      /* testcase 2.2 */
      bins both_ones   = binsof(a_cp.ones) && binsof(b_cp.ones);

      /* testcase 3 */
      bins both_others = binsof(a_cp.others) && binsof(b_cp.others);
    }

    /* cross of a cross is an enhancement to the LRM */
    a_cp_b_cp_cross_cin_cp : cross a_cp, b_cp, cin_cp {

      /* testcase 4 */
      bins both_zeros_ncin = binsof(a_cp.zeros) && binsof(b_cp.zeros) &&
                             binsof(cin_cp) intersect { 0 };

      /* testcase 5 */
      bins both_ones_cin   = binsof(a_cp.ones) && binsof(b_cp.ones) &&
                             binsof(cin_cp) intersect { 1 };

      ignore_bins others   = (binsof(cin_cp) intersect { 0 } &&
                               (binsof(b_cp.others) || binsof(b_cp.ones))) ||
                             (binsof(cin_cp) intersect { 1 } &&
                               (binsof(a_cp.zeros) || binsof(a_cp.others))) ||
                             ((binsof(a_cp.others) || binsof(a_cp.ones)) &&
                               (binsof(b_cp.zeros) || binsof(b_cp.others)));
    }

    cout_cp : coverpoint txn.cout {

      /* testcase 6 */
      bins ovfw          = { 1 };

      ignore_bins others = { 0 };

    }

  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);

    /* instantiate the embedded covergroup */
    cnst_rqst_txn_cg = new();

  endfunction : new

  virtual function void sample();
    cnst_rqst_txn_cg.sample();
  endfunction : sample

endclass

`endif // STMCOVERAGE_SVH

