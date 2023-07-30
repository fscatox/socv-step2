-- File              : pkg_imath.vhd
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

package pkg_imath is

 -- If x is a power of 2, it returns the exponent; 
 -- otherwise it returns -1.
 function ilog2 (x : in positive) return integer;
 
 -- Computes ceil(log2(n))
 function clog2(n : positive) return natural;

end package;

package body pkg_imath is
  
  function ilog2 (x : in positive) return integer is
  variable y : natural := 0;
  variable ret : integer := -1;

  begin

    while 2**y < x loop
      y := y+1;
    end loop;

    if 2**y = x then
      ret := y;
    end if;

    return ret;
  end ilog2;

  function clog2(n : positive) return natural is
  variable r  : natural := 0;
  variable m  : natural := n-1;

  begin

    while (m /= 0) loop
      r := r+1;
      m := m/2;
    end loop;
  
    return r;
  end clog2;

end package body;
