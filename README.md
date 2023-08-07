# Step 2 - Introduction to the UVM

UVM (Universal Verification Methodology) based verification of some intermediate designs from the
*Microelectronic Systems* course laboratories. This material is developed as part of the workshop
*SoC Verification Strategies* at Politecnico di Torino and builds upon the *Introduction to
SystemVerilog* step.

## Contents

<!-- @import "[TOC]" {cmd="toc" depthFrom=2 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Contents](#contents)
- [Introduction](#introduction)
- [Included Files](#included-files)
- [Usage](#usage)
- [References](#references)

<!-- /code_chunk_output -->

## Introduction

## Included Files

* [`src/rtl`](src/rtl) - **DUTs source files**

    * [`src/rtl/p4_adder`](src/rtl/p4_adder) - Pentium IV Adder sources

    * [`src/rtl/windowed_rf`](src/rtl/windowed_rf) - Windowed Register File sources

* [`src/tb`](src/tb) - **UVM testbenches**

    * [`src/tb/p4_adder`](src/tb/p4_adder) - Pentium IV Adder sources

        * [`src/tb/p4_adder/p4_adder_if.sv`](src/tb/p4_adder/p4_adder_if.sv) - bundles the dut wires
          encapsulating synchronization information for the verification environment.

        * [`src/tb/p4_adder/RqstTxn.svh`](src/tb/p4_adder/RqstTxn.svh) - base request transaction
          translated by the driver to pin wiggles. Tests can use the factory to override with a
          child class that includes stimulus-specific constraints.

        * [`src/tb/p4_adder/RspTxn.svh`](src/tb/p4_adder/RspTxn.svh) - response transaction
          extracted from the DUT by the monitor.

        * [`src/tb/p4_adder/Sequencer.svh`](src/tb/p4_adder/Sequencer.svh) - arbitrates the flow of
          sequence items to the driver.

        * [`src/tb/p4_adder/Driver.svh`](src/tb/p4_adder/Driver.svh) - translates incoming sequence
          items to pin wiggles, communicating with the DUT through the virtual interface.

        * [`src/tb/p4_adder/Monitor.svh`](src/tb/p4_adder/Monitor.svh) - recognizes the pin-level
          activity on the virtual interface and turns it into a transaction that gets broadcasted to
          environment components (every request generates a response).

        * [`src/tb/p4_adder/Agent.svh`](src/tb/p4_adder/Agent.svh) - p4 adder agent. To add
          flexibility, it's extended from uvm_agent and configurable in either active or passive
          mode.

        * [`src/tb/p4_adder/Coverage.svh`](src/tb/p4_adder/Coverage.svh) - base coverage collector
          class. Tests can use the factory to override with a child class that includes
          stimulus-specific covergroups.

        * [`src/tb/p4_adder/Printer.svh`](src/tb/p4_adder/Printer.svh) - listens on the monitor
          analysis ports and prints the broadcasted transactions. Quiet tests can be developed by
          overriding with the BitBucket child class.

        * [`src/tb/p4_adder/Scoreboard.svh`](src/tb/p4_adder/Scoreboard.svh) - listens on the
          monitor analysis ports and validates DUT responses. The RspTxn encapsulate the request
          data, which is used to compute the expected response.

        * [`src/tb/p4_adder/Environment.svh`](src/tb/p4_adder/Environment.svh) - default
          verification environment for the p4 adder. Test classes can customize it with both the
          factory overrides and the environment configuration object.

        * [`src/tb/p4_adder/RqstSequence.svh`](src/tb/p4_adder/RqstSequence.svh) - generates the
          stream of sequence items to feed the driver. Tests can override the type of request
          transaction through the factory.

        * [`src/tb/p4_adder/BaseTest.svh`](src/tb/p4_adder/BaseTest.svh) - handles the default
          configuration of the environment and the common duties of child tests.

            - the number of request transactions can be set by command line with
                `+n_txn=<txn number>`; otherwise, it defaults to 100

            - to make the test quiet, pass the flag `+quiet`

        * [`src/tb/p4_adder/p4_adder_pkg.sv`](src/tb/p4_adder/p4_adder_pkg.sv) - namespace for the
          p4 adder UVM-based testbench.

        * [`src/tb/p4_adder/p4_adder_top.sv`](src/tb/p4_adder/p4_adder_top.sv) - instantiates the
          dut and the free running clock, then it sets up and invokes the test specified by command
          line with `+UVM_TESTNAME=<test name>`
## Usage

## References

[1] C. Spear and G. Tumbush, SystemVerilog for Verification: A Guide to Learning the Testbench
Language Features, 3rd. Springer US, 2012, isbn: 9781461407140.

[2] R. Salemi, The UVM Primer: A Step-By-Step Introduction to the Universal Verification
Methodology, Boston Light Press, 2013, isbn: 9780974164939.

[3] “IEEE Standard for Verilog Hardware Description Language”, IEEE Std 1364-2005 (Revision of IEEE
Std 1364-2001), pp. 1–590, 2006. doi: 10.1109/IEEESTD.2006.99495.

[4] “IEEE Standard for SystemVerilog: Unified Hardware Design, Specification and Verification
Language”, IEEE Std 1800-2005, pp. 1–648, 2005. doi: 10.1109/IEEESTD.2005.97972.

