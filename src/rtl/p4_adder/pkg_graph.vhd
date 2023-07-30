-- File              : pkg_graph.vhd
--
-- Authors           : Fabio Scatozza      <s315216@studenti.polito.it>
--                     Isacco Delpero      <s314713@studenti.polito.it>
--                     Leonardo Cerruti    <s317664@studenti.polito.it>
--
-- Date              : 19.04.2023
-- Last Modified Date: 19.04.2023
--
-- Copyright (c) 2023 
--
-- Licensed under the Solderpad Hardware License v 2.1 (the "License");
-- you may not use this file except in compliance with the License, or,
-- at your option, the Apache License version 2.0.
-- You may obtain a copy of the License at
--
--     https://solderpad.org/licenses/SHL-2.1/
--
-- Unless required by applicable law or agreed to in writing, any work
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

package pkg_graph is

  function extraNode(s: in positive; vl : in natural; l : in positive; i : in positive) return boolean;

end package;

package body pkg_graph is

  function extraNode(s: in positive; vl : in natural; l : in positive; i : in positive) return boolean is
    variable found : boolean := false;  -- to and-reduce in the check of extra nodes

  begin
    
    current_level_extra : for z in 1 to 2**(l-vl)-1 loop
      found := found or (((s*i-(2**(l-1)+s*z)) mod (2**l)) = 0);
    end loop;

    return found;

  end extraNode;

end package body;
