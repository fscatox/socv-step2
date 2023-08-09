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
- [Verification Plan](#verification-plan)
  - [Pentium IV Adder](#pentium-iv-adder)
  - [Windowed Register File](#windowed-register-file)
- [Included Files](#included-files)
- [Usage](#usage)
- [References](#references)

<!-- /code_chunk_output -->

## Introduction

In the *Introduction to SystemVerilog* step, I had the opportunity to begin tackling the
shortcomings of the directed testing approach, getting familiar with some common principles of
more advanced verification methodologies and their elected language, SystemVerilog. Most notably:
 
- *constrained-random stimuli*. Contrary to directed tests, which find bugs where they are expected
  to be, randomness allows to find bugs that were never anticipated; at the same time, constraints
  are essential to ensure that the stimulus is valid and relevant to the DUT. 

- *functional coverage*. Once having switched to random tests, functional coverage becomes the metric
  for tracking progress in the verification plan, ensuring that all the intended features of the DUT
  were exercised.

- *layered structure*. Random stimuli imply the need for an environment capable of predicting the
  expected response; building this infrastructure requires additional work, thus the importance of
  effectively managing complexity:

    - the abstraction level is raised up to the transaction level. The environment is structured in a
      layered manner, composing simpler modules. 

    - language expressiveness limits analyzability, synthesizability and optimizability. Nonetheless,
      being verification the primary goal, HDLs make way for SystemVerilog and its convenient set of
      features.

Primarily guided by [1], I leveraged object-oriented and generic programming principles to develop a
reusable, templated testbench framework that I was than able to specialize for specific DUTs. By
designing and developing the entire testbench architecture, I gained a better understanding of the
techniques that go into the classes and utilities of standardized verification libraries such as the
UVM.

The goal of this step is to apply the UVM to develop a fully-fledged SystemVerilog verification
environment for some intermediate designs from the *Microelectronic Systems* course laboratories:

- the Pentium IV Adder, described with generic data parallelism and tree sparseness;

- a windowed register file

As a glimpse of the used UVM features:

- customization both via the factory and the configuration database

- TLM and analysis communication 

- id and severity specific logging to file

- bottom-up veto power via objections and `phase_ready_to_end()`

## Verification Plan

The verification plan is directly derived from the design specifications and encompasses the
description of what features shall be exercised and the techniques to do so. 

Given that the DUTs are parameterized, a simple approach for verifying their correctness is to let
the parameters be defined as compile-time options and repeat the simulations while changing them in
the set of interest.

### Pentium IV Adder

    for i in {3, ..., 7}
      for j in {2, ..., i-1}
        define NBIT = 2^i
        define NBIT_PER_BLOCK = 2^j

Testcases:

1. zero input
     1. all 0s on an input
     2. all 0s on both inputs

2. one input
     1. all 1s on an input
     2. all 1s on both inputs

3. non-corner values on both inputs

4. 0s on both inputs and carry-in '0'

5. 1s on both inputs and carry-in '1'

6. (unsigned) overflow


### Windowed Register File


## Included Files

* [`run.sh`](run.sh) - *Step 2 - Introduction to the UVM* launcher

* [`scripts`](scripts) - **Simulation automation**

    * [`scripts/main.do`](scripts/main.do) - QuestaSim shell script, launched by run.sh. It
      orchestrates: source files collection, dependency resolution, simulation run, coverage report
      generation and the post-processing of the applied stimulus.

    * [`scripts/findFiles.tcl`](scripts/findFiles.tcl) - recursive glob procedure.

    * [`scripts/autocompile.tcl`](scripts/autocompile.tcl) - determines the compile order for a list
      of hdl sources by executing the compilation command for each one of them in order, then
      repeating for any compiles that fail until there are no more compile errors.

    * [`scripts/log2csv.tcl`](scripts/log2csv.tcl) - parses the printer and the scoreboard logs.
      The response transactions broadcasted to the printer are exported in comma-separated value format,
      with the outcome of the comparison by the scoreboard. To ensure repeatability, the seed of the
      simulation is listed at the top of the file.

* [`src/rtl`](src/rtl) - **DUTs source files**

    * [`src/rtl/p4_adder`](src/rtl/p4_adder) - Pentium IV Adder sources

    * [`src/rtl/windowed_rf`](src/rtl/windowed_rf) - Windowed Register File sources

* [`src/tb`](src/tb) - **UVM testbenches**

    * [`src/tb/p4_adder`](src/tb/p4_adder) - Pentium IV Adder sources

        * [`src/tb/p4_adder/p4_adder_if.sv`](src/tb/p4_adder/p4_adder_if.sv) - bundles the DUT wires
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
          abstract class. Tests must use the factory to override with a child class that includes
          stimulus-specific covergroups and implements the `sample()` callback.

        * [`src/tb/p4_adder/Printer.svh`](src/tb/p4_adder/Printer.svh) - listens on the monitor
          analysis port and prints the broadcasted transactions to the screen and to a file. Quiet
          tests, which don't display transaction on the screen, can be developed by overriding the Printer
          class with the BitBucket child class. 

        * [`src/tb/p4_adder/Scoreboard.svh`](src/tb/p4_adder/Scoreboard.svh) - listens on the
          monitor analysis ports and validates DUT responses. The RspTxn encapsulate the request
          data, which is used to compute the expected response. The comparison results are written
          to a file.

        * [`src/tb/p4_adder/Environment.svh`](src/tb/p4_adder/Environment.svh) - default
          verification environment for the p4 adder. Test classes can customize it with both the
          factory overrides and the environment configuration object.

        * [`src/tb/p4_adder/RqstSequence.svh`](src/tb/p4_adder/RqstSequence.svh) - generates the
          stream of sequence items to feed the driver. Tests can override the type of request
          transaction through the factory.

        * [`src/tb/p4_adder/BaseTest.svh`](src/tb/p4_adder/BaseTest.svh) - handles the default
          configuration of the environment and the common DUTies of child tests.

            - the number of request transactions can be set by command line with
              `+n_txn=<txn number>`; otherwise, it defaults to 100
 
            - the printer file can be set by command line with `+printer_file=<file path>`;
              otherwise it defaults to *printer.log*
              
            - the scoreboard file can be set by command line with `+scoreboard_file=<file path>`;
              otherwise it defaults to *scoreboard.log*

            - to make the test quiet, pass the flag `+quiet`

        * [`src/tb/p4_adder/p4_adder_pkg.sv`](src/tb/p4_adder/p4_adder_pkg.sv) - namespace for the
          p4 adder UVM-based testbench. The DUT generics are set at compile time defining the macros
          *NBIT* and *NBIT_PER_BLOCK* by command line.

        * [`src/tb/p4_adder/p4_adder_top.sv`](src/tb/p4_adder/p4_adder_top.sv) - instantiates the
          DUT and the free running clock, then it sets up and invokes the test specified by command
          line with `+UVM_TESTNAME=<test name>`

        * [`src/tb/p4_adder/CnstRqstTxn.svh`](src/tb/p4_adder/CnstRqstTxn.svh) - extends RqstTxn
          adding constraints to skew the stimulus in such a way to increase coverage for the
          testcases. Tests can use it via factory override.

        * [`src/tb/p4_adder/StmCoverage.svh`](src/tb/p4_adder/StmCoverage.svh) - extends Coverage
          adding coverage for the testcases of the p4 adder verification plan.

        * [`src/tb/p4_adder/Test.svh`](src/tb/p4_adder/Test.svh) - extends BaseTest adding coverage
          and randomization constraints to the request transactions.

## Usage

1. Change into the directory containing this file:

    ```bash
    cd /path/to/scatozza-step2
    ```
2. Invoke the launcher. Examples:

    * **Pentium IV Adder**. After the execution of the following command, the outputs are saved
      in `out/p4_adder-NBIT32-NBIT_PER_BLOCK4`.
      
      ```bash
      ./run.sh -k 1
      ```
3. Examine the outputs:

    * the logs: `printer.log`, `scoreboard.log` and `vsim.log`

    * the output of logs post-processing: `extract.csv`

    * the coverage report: `func_cover.rpt`

For additional info, hit `./run.sh -h`.

## References

[1] C. Spear and G. Tumbush, SystemVerilog for Verification: A Guide to Learning the Testbench
Language Features, 3rd. Springer US, 2012, isbn: 9781461407140.

[2] R. Salemi, The UVM Primer: A Step-By-Step Introduction to the Universal Verification
Methodology, Boston Light Press, 2013, isbn: 9780974164939.

[3] “IEEE Standard for Verilog Hardware Description Language”, IEEE Std 1364-2005 (Revision of IEEE
Std 1364-2001), pp. 1–590, 2006. doi: 10.1109/IEEESTD.2006.99495.

[4] “IEEE Standard for SystemVerilog: Unified Hardware Design, Specification and Verification
Language”, IEEE Std 1800-2005, pp. 1–648, 2005. doi: 10.1109/IEEESTD.2005.97972.

