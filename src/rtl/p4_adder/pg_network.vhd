-- File              : pg_network.vhd
--
-- Description       : Starting from the inputs {AN, ..., A1}, {BN, ..., B1}
-- and from the carry-in, the network computes the signals of the recursion base
-- 
--     {GNN, .., G22, G10} and {PNN, ..., P22, P10}
--
-- By generating G10 and P10 instead of G11 and P11 we're embedding the 
-- carry-in value in the set of signals used by the carry generator.
-- The propagate signal is in the simplified OR-form, hence it can't be used
-- for the sum generation.
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

library IEEE;
use IEEE.std_logic_1164.all;

entity pg_network is
  generic (nbit_g : positive);
  port (
    a, b: in  std_logic_vector(nbit_g downto 1);
    ci:   in  std_logic;
    g, p: out std_logic_vector(nbit_g downto 1)
  ); 
end entity;

architecture behavioral of pg_network is
begin

  pg_p : process (a, b, ci) is
    variable gtmp, ptmp : std_logic_vector(nbit_g downto 1); 
  begin
    
    gii_pii : for i in nbit_g downto 1 loop
      gtmp(i) := a(i) and b(i);
      ptmp(i) := a(i) or b(i);
    end loop;

    g(nbit_g downto 2) <= gtmp(nbit_g downto 2);
    g(1) <= gtmp(1) or (ptmp(1) and ci); -- G10 = G11 or (P11 and G00)

    p(nbit_g downto 2) <= ptmp(nbit_g downto 2);
    p(1) <= '0'; -- P10 = P11 and P00, but P00 = '0'

  end process;

end architecture;
