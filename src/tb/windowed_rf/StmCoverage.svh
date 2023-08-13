/**
 * File              : StmCoverage.svh
 *
 * Description       : extends Coverage adding coverage for the testcases of
 *                     the windowed rf verification plan.
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

`ifndef STMCOVERAGE_SVH
`define STMCOVERAGE_SVH

class StmCoverage extends Coverage;
  `uvm_component_utils(StmCoverage)

  /* encoding for the port involved in the read-before-write event */
  typedef enum {
    RBW_1, RBW_2, RBW_BOTH, NO_RBW
  } rbw_port_t;

  covergroup cnst_rqst_txn_cg;

    /* testcase 1
     * notice: call, return and reset can mask read and write operations */
    execute_rw_cp : coverpoint txn.get_ops() {
      wildcard bins rd1   = { 7'b1??0010 };
      wildcard bins rd2   = { 7'b?1?0010 };
      wildcard bins wr    = { 7'b??10010 };
    }

    /* testcase 1 */
    execute_call_ret_reset_cp : coverpoint txn.get_ops() {
      wildcard bins reset       = { 7'b??????1 };
      wildcard bins call        = { 7'b???1??0 };       // reset wins over call
      wildcard bins ret         = { 7'b???01?0 };       // reset and call win over ret
    }

    /* testcase 2.1 */
    disable_while_enabled : coverpoint txn.get_ops() {
      wildcard bins rd1n   = { 7'b0??0010 };
      wildcard bins rd2n   = { 7'b?0?0010 };
      wildcard bins wrn    = { 7'b??00010 };
    }

    /* testcase 2.2 */
    enable_while_disabled : coverpoint txn.get_ops() {
      wildcard bins rd1   = { 7'b1??0000 };
      wildcard bins rd2   = { 7'b?1?0000 };
      wildcard bins wr    = { 7'b??10000 };
    }

    /* testcase 2.3 */
    issue_rw_cp : coverpoint txn.get_ops() {
      type_option.weight = 0; // don't count alone
      wildcard bins rd1   = { 7'b1????1? };
      wildcard bins rd2   = { 7'b?1???1? };
      wildcard bins wr    = { 7'b??1??1? };
    }
    issue_rw_but_masked :
      cross issue_rw_cp, execute_call_ret_reset_cp;

    /* testcase 2.4 */
    rbw_cp : coverpoint anlys_rbw() {
      bins rbw_1_not_2   = { RBW_1 };
      bins rbw_2_not_1   = { RBW_2 };
      bins rbw_both      = { RBW_BOTH };
    }

    /* testcase 3.1, 3.2 */
    issue_call_ret_cp : coverpoint txn.get_ops() {
      wildcard bins call_and_ret   = { 7'b???11?0 }; // while no reset
      wildcard bins call_and_reset = { 7'b???1??1 };
      wildcard bins ret_and_reset  = { 7'b???01?1 }; // while no call
    }

    /* testcase 3.3, 4.1 */
    issue_call_ret_reset_twice : coverpoint txn.get_ops() {
      wildcard bins reset_twice = ( 7'b??????1 [* 2] );
      wildcard bins call_twice  = ( 7'b???1??0 [* 2] );
      wildcard bins ret_twice   = ( 7'b???01?0 [* 2] );
    }

    /* testcase 3.4 */
    spill_cp : coverpoint txn.spill {
      bins spill = { 1 };
    }

    /* testcase 3.4 */
    fill_cp : coverpoint txn.fill {
      bins fill = { 1 };
    }

    /* testcase 4.2 */
    execute_after_reset : coverpoint txn.get_ops() {
      wildcard bins reset_rd1  = ( 7'b??????1 => 7'b1??0010 );
      wildcard bins reset_rd2  = ( 7'b??????1 => 7'b?1?0010 );
      wildcard bins reset_wr   = ( 7'b??????1 => 7'b??10010 );
      wildcard bins reset_call = ( 7'b??????1 => 7'b???1??0 );
    }

    /* testcase 4.3 */
    execute_before_reset : coverpoint txn.get_ops() {
      wildcard bins rd1_reset  = ( 7'b1??0010 => 7'b??????1 );
      wildcard bins rd2_reset  = ( 7'b?1?0010 => 7'b??????1 );
      wildcard bins wr_reset   = ( 7'b??10010 => 7'b??????1 );
      wildcard bins call_reset = ( 7'b???1??0 => 7'b??????1 );
      wildcard bins ret_reset  = ( 7'b???01?0 => 7'b??????1 );
    )

  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);

    /* instantiate the embedded covergroup */
    cnst_rqst_txn_cg = new();

  endfunction : new

  function rbw_port_t anlys_rbw();
    packed_ops_t ops = txn.get_ops();
    bit add1_matches = (txn.add_rd1 == txn.add_wr);
    bit add2_matches = (txn.add_rd2 == txn.add_wr);

    if ((ops == 7'b1110010) && add1_matches && add2_matches)
      return RBW_BOTH;

    if ((ops == 7'b1010010) && add1_matches)
      return RBW_1;

    if ((ops == 7'b0110010) && add2_matches)
      return RBW_2;

    return NO_RBW;
  endfunction : anlys_rbw

  virtual function void sample();
    cnst_rqst_txn_cg.sample();
  endfunction : sample

endclass

`endif // STMCOVERAGE_SVH


