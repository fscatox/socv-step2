/**
 * File              : NoCnstNoCovTest.svh
 *
 * Description       : extends BaseTest to clarify its purpose. The
 *                     TopSequence type is not overridden, thus the generated
 *                     transactions are fully unconstrained. Moreover, it's
 *                     kept the environment default of having no coverage
 *                     collector.
 *
 * Author            : Fabio Scatozza <s315216@studenti.polito.it>
 *
 * Date              : 08.08.2023
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

`ifndef NOCNSTNOCOVTEST_SVH
`define NOCNSTNOCOVTEST_SVH

class NoCnstNoCovTest extends BaseTest;
  `uvm_component_utils(NoCnstNoCovTest)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

endclass

`endif // NOCNSTNOCOVTEST_SVH
