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

Parameterization test:

    for i in {3, ..., 7}
      for j in {2, ..., i-1}
        define NBIT = 2^i
        define NBIT_PER_BLOCK = 2^j

Test cases:

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

Typical parameterization:

    NBIT = 32
    NBIT_MEM = 8
    NGLOBALS = 8
    NLOCALS = 8
    NWINDOWS = 4 // to increase spill/fill events

Test cases:

1. execute all operations. In case of read and write operations, execution means
   that the operation must be issued and must not be masked by a reset, a call or 
   a return.

2. read and write operations
     1. disabled by *rd1*, *rd2* or *wr* while enabled by *enable*
     2. enabled by *rd1*, *rd2* or *wr* but disabled by *enable*
     3. issued but masked by a reset, a call or a return
     4. read-before-write, distinguishing between read port 1 and 2

3. call and return operations
     1. issued together
     2. issued with a reset
     3. execute twice in a row
     4. generate a spill
     5. generate a fill

4. reset operation
     1. execute twice in a row
     2. execute all operations, except for reset and return, after a reset
     3. execute all operations, except for reset, before a reset


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

    * [`src/tb/Sequencer.svh`](src/tb/Sequencer.svh) - arbitrates the flow of sequence items to the
      driver.

    * [`src/tb/Coverage.svh`](src/tb/Coverage.svh) - base coverage collector abstract class.
      Tests must use the factory to override with a child class that includes stimulus-specific
      covergroups and implements the `sample()` callback.

    * [`src/tb/Printer.svh`](src/tb/Printer.svh) - listens on the monitor analysis port and
      prints the broadcasted transactions to the screen and to a file. Quiet tests, which don't
      display transaction on the screen, can be developed by overriding the Printer class with the
      BitBucket child class.

    * [`src/tb/BaseScoreboard.svh`](src/tb/BaseScoreboard.svh) - listens on the monitor
      analysis ports to validate DUT responses. The RspTxn encapsulate the request data, which
      is used to compute the expected response. The comparison results are written to a file. Child
      classes must implement the comparison logic.

    * [`src/tb/Environment.svh`](src/tb/Environment.svh) - default verification environment.
      Test classes can customize it with both the factory overrides and the environment
      configuration object.

    * [`src/tb/BaseTest.svh`](src/tb/BaseTest.svh) - handles the default configuration of the
      environment, and the execution of the top-hierarchy sequence TopSequence. Child classes
      can call `configure_env()` to perform last minute tweaking. Additional customization parameters
      can be passed as plusargs:

        - the number of request transactions per test sequence can be set by command line with
          `+n_txn=<txn number>`; otherwise, it defaults to 100

        - the printer file can be set by command line with `+printer_file=<file path>`;
          otherwise it defaults to printer.log

        - the scoreboard file can be set by command line with `+scoreboard_file=<file path>`;
          otherwise it defaults to scoreboard.log

        - to make the test quiet, pass the flag `+quiet`

    * [`src/tb/p4_adder`](src/tb/p4_adder) - **Pentium IV Adder additional sources**

        * [`src/tb/p4_adder/p4_adder_if.sv`](src/tb/p4_adder/p4_adder_if.sv) - bundles the DUT wires
          encapsulating synchronization information for the verification environment.

        * [`src/tb/p4_adder/RqstTxn.svh`](src/tb/p4_adder/RqstTxn.svh) - base request transaction
          translated by the driver to pin wiggles. Tests can use the factory to override with a
          child class that includes stimulus-specific constraints.

        * [`src/tb/p4_adder/RspTxn.svh`](src/tb/p4_adder/RspTxn.svh) - response transaction
          extracted from the DUT by the monitor.

        * [`src/tb/p4_adder/Driver.svh`](src/tb/p4_adder/Driver.svh) - translates incoming sequence
          items to pin wiggles, communicating with the DUT through the virtual interface.

        * [`src/tb/p4_adder/Monitor.svh`](src/tb/p4_adder/Monitor.svh) - recognizes the pin-level
          activity on the virtual interface and turns it into a transaction that gets broadcasted to
          environment components (every request generates a response).

        * [`src/tb/p4_adder/Agent.svh`](src/tb/p4_adder/Agent.svh) - p4 adder agent. To add
          flexibility, it's extended from uvm_agent and configurable in either active or passive
          mode.

        * [`src/tb/p4_adder/Scoreboard.svh`](src/tb/p4_adder/Scoreboard.svh) - extends
          BaseScoreboard specifying an analysis communication target and a predictor. A prediction
          function is called inside the `write()` method of the analysis implementation.

        * [`src/tb/p4_adder/TopSequence.svh`](src/tb/p4_adder/TopSequence.svh) - generates the stream
          of sequence items to feed the driver. Tests can override the type of request transaction
          through the factory.

        * [`src/tb/p4_adder/NoCnstNoCovTest.svh`](src/tb/p4_adder/NoCnstNoCovTest.svh) - extends
          BaseTest to clarify its purpose. The TopSequence type is not overridden, thus the generated
          transactions are fully unconstrained. Moreover, it's kept the environment default of having
          no coverage collector.

        * [`src/tb/p4_adder/CnstRqstTxn.svh`](src/tb/p4_adder/CnstRqstTxn.svh) - extends RqstTxn
          adding constraints to skew the stimulus in such a way to increase coverage for the
          testcases. Tests can use it via factory override.

        * [`src/tb/p4_adder/StmCoverage.svh`](src/tb/p4_adder/StmCoverage.svh) - extends Coverage
          adding coverage for the testcases of the p4 adder verification plan.
        
        * [`src/tb/p4_adder/FullTest.svh`](src/tb/p4_adder/FullTest.svh) - extends BaseTest adding
          coverage and randomization constraints to the request transactions.

        * [`src/tb/p4_adder/p4_adder_pkg.sv`](src/tb/p4_adder/p4_adder_pkg.sv) - namespace for the
          p4 adder UVM-based testbench. The DUT generics are set at compile time defining the
          following macros by command line:
            
            - *NBIT*, the data parallelism 
           
            - *NBIT_PER_BLOCK*, the sparseness of the carry generator tree

        * [`src/tb/p4_adder/p4_adder_top.sv`](src/tb/p4_adder/p4_adder_top.sv) - instantiates the
          DUT and the free running clock, then it sets up and invokes the test specified by command
          line with `+UVM_TESTNAME=<test name>`


    * [`src/tb/windowed_rf`](src/tb/windowed_rf) - **Windowed Register File additional sources**

        * [`src/tb/windowed_rf/windowed_rf_if.sv`](src/tb/windowed_rf/windowed_rf_if.sv) - bundles
          the dut wires encapsulating synchronization information for the verification environment.

        * [`src/tb/windowed_rf/RqstTxn.svh`](src/tb/windowed_rf/RqstTxn.svh) - base request
          transaction translated by the driver to pin wiggles. Tests can use the factory to override
          with a child class that includes stimulus-specific constraints. Calling `get_ops()` the
          fields specifying the requested operations are returned in a packed struct.

        * [`src/tb/windowed_rf/RqstAnlysTxn.svh`](src/tb/windowed_rf/RqstAnlysTxn.svh) - extends 
          RqstTxn adding monitor-to-scoreboard analysis fields required for late-correction of
          scoreboard predictions. This is because the behavioral DUT that generates the predictions is
          instantiated in the scoreboard and runs at each incoming response. Instead, a reset request can
          cut short pending call/return operations. 

          In addition, mmu outputs are sampled as part of the request to the DUT, but having made the
          choice to have a single analysis communication channel from the monitor to scoreboard,
          printer and coverage collector, there's no way to separate requests from response samples,
          which would be necessary to properly examine the mmu/dut interaction. That being said,
          once having made sure that the behavioral mmu implemented in the testbench complies with
          the specifications, errors in the DUT due to the interaction with the mmu would still be
          caught, even though without additional info to help designers. That is, the scoreboard
          doesn't verify the dut-mmu interaction cycles directly, but only through read/write
          operations and fill/spill signals.

        * [`src/tb/windowed_rf/RspTxn.svh`](src/tb/windowed_rf/RspTxn.svh) - response transaction
          extracted from the DUT by the monitor. The bypass field is used by the monitor to
          determine when the sequence resumes execution. In case of call and ret operations,
          out1 and out2 are not taken into account for the comparison, unless reset is high.

        * [`src/tb/windowed_rf/Mmu.svh`](src/tb/windowed_rf/Mmu.svh) - handles filling/spilling
          requests from the DUT, implementing the FSM described in the documentation in the run phase
          task. The synchronous reset is handled by restarting the fsm thread.

        * [`src/tb/windowed_rf/Driver.svh`](src/tb/windowed_rf/Driver.svh) - translates incoming
          sequence items to pin wiggles, communicating with the DUT through the virtual interface.
          It instantiates the Mmu component to reply to DUT spill and fill requests. Instead of
          using a configuration object to pass the virtual interface down the hierarchy, the driver
          configures the child mmu component in the end of elaboration phase. The request
          transactions are applied at each falling edge: if the bypass signal is high, and the
          operation is not a reset, the driver skips the cycle.

        * [`src/tb/windowed_rf/Monitor.svh`](src/tb/windowed_rf/Monitor.svh) - recognizes the
          pin-level activity on the virtual interface and turns it into a transaction that gets
          broadcasted to environment components. The monitor activates on rising edges:

            - it samples the new request, applied to the dut by the driver in the
              previous falling edge;

            - it samples the response for the request that was sampled the cycle before.
              Once the response is available, it's broadcasted.

          Request sampling is suspended while the bypass signal is active, because the driver
          waits for the register file to become available before applying new requests, with
          the exception of reset operations. In the case of a call operation, the response must
          be sampled not one cycle but two cycles after the request, which is the one during
          which the rf may raise spill.

        * [`src/tb/windowed_rf/Agent.svh`](src/tb/windowed_rf/Agent.svh) - windowed rf agent. To
          add flexibility, it's extended from uvm_agent and configurable in either active or passive
          mode

        * [`src/tb/windowed_rf/BehWindowedRf.svh`](src/tb/windowed_rf/BehWindowedRf.svh) - the
          windowed rf is modelled as a stack (SystemVerilog queue) of register sets, as explained
          in the SPARC Architecture Manual, whereas spill and fill are generated treating the
          stack as a circular buffer, with two pointers to detect the corresponding full and 
          empty conditions.

        * [`src/tb/windowed_rf/Scoreboard.svh`](src/tb/windowed_rf/Scoreboard.svh) - extends
          BaseScoreboard specifying an analysis communication target and a predictor. Notice that
          the driver suspends applying items while the bypass signal is high.

        * [`src/tb/windowed_rf/ResetSequence.svh`](src/tb/windowed_rf/ResetSequence.svh) - generates
          some sequence items to feed the driver and bring the dut registers in a known state. It's not
          counted in the `+n_txn` requests.

        * [`src/tb/windowed_rf/CnstRqstTxn.svh`](src/tb/windowed_rf/CnstRqstTxn.svh) - extends
          RqstTxn adding constraints to ensure the validity of the stimulus. Before randomizing
          an object, a "profile" must have been set by calling `set_profile()` with the
          following arguments:
            - *call_ret_weight*, weight for call/ret operations
            - *call_ret_enhanced*, weight for the call/ret operation after having already issued it
            - *reset_weight*
            - *reset_enhanced*
          Tests can use it via factory override.

        * [`src/tb/windowed_rf/TestSequence.svh`](src/tb/windowed_rf/TestSequence.svh) - 
          FullTest-specific sequence. It generates a stream of CnstRqstTxn items, specifying as 
          randomization parameters the one set at compile time as class templates.

        * [`src/tb/windowed_rf/TopSequence.svh`](src/tb/windowed_rf/TopSequence.svh) - assembles
          the desired stream of sequence items by configuring and calling sub-sequences for FullTest.
          This class is test-specific, and additional tests can override it with the factory.

        * [`src/tb/windowed_rf/StmCoverage.svh`](src/tb/windowed_rf/StmCoverage.svh) - extends
          Coverage adding coverage for the testcases of the windowed rf verification plan. 

        * [`src/tb/windowed_rf/FullTest.svh`](src/tb/windowed_rf/FullTest.svh) - extends BaseTest
          adding coverage and randomization constraints to the request transactions. Notice that
          with this test, "+n_txn" is the number of transactions per test sequence.

        * [`src/tb/windowed_rf/windowed_rf_pkg.sv`](src/tb/windowed_rf/windowed_rf_pkg.sv) -
          namespace for the windowed register file UVM-based testbench. The dut and mmu generics are
          set at compile time defining the following macros by command line

            - *NBIT*, the parallelism of the rf

            - *NBIT_MEM*, the minimum addressable width of the main memory

            - *NGLOBALS*, global registers per window

            - *NLOCALS*, local registers per window

            - *NWINDOWS*, number of windows

        * [`src/tb/windowed_rf/windowed_rf_top.sv`](src/tb/windowed_rf/windowed_rf_top.sv) -
          instantiates the dut and the free running clock, then it sets up and invokes the test
          specified by command line with "+UVM_TESTNAME=<test name>"


## Usage

1. Change into the directory containing this file:

    ```bash
    cd /path/to/scatozza-step2
    ```
2. Invoke the launcher. Examples:

    * **Pentium IV Adder**. After the execution of the following command, the outputs are saved
      in `out/p4_adder/NBIT32-NBIT_PER_BLOCK4`.

      ```bash
      ./run.sh -k 1
      ```
 
    * **Windowed Register File**. After the execution of the following command, the outputs are
      saved in `out/windowed_rf/NBIT32-NBIT_MEM8-NGLOBALS8-NLOCALS8-NWINDOWS4`.

      ```bash
      ./run.sh -k 3
      ```
   For additional info, hit `./run.sh -h`.

3. Examine the outputs:

    * the logs: `printer.log`, `scoreboard.log` and `vsim.log`

    * the output of logs post-processing: `extract.csv`

    * the coverage report: `func_cover.rpt`

## References

[1] C. Spear and G. Tumbush, SystemVerilog for Verification: A Guide to Learning the Testbench
Language Features, 3rd. Springer US, 2012, isbn: 9781461407140.

[2] R. Salemi, The UVM Primer: A Step-By-Step Introduction to the Universal Verification
Methodology, Boston Light Press, 2013, isbn: 9780974164939.

[3] “IEEE Standard for Verilog Hardware Description Language”, IEEE Std 1364-2005 (Revision of IEEE
Std 1364-2001), pp. 1–590, 2006. doi: 10.1109/IEEESTD.2006.99495.

[4] “IEEE Standard for SystemVerilog: Unified Hardware Design, Specification and Verification
Language”, IEEE Std 1800-2005, pp. 1–648, 2005. doi: 10.1109/IEEESTD.2005.97972.

