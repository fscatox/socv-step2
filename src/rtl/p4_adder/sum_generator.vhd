-- File              : sum_generator.vhd
--
-- Authors           : Fabio Scatozza      <s315216@studenti.polito.it>
--                     Isacco Delpero      <s314713@studenti.polito.it>
--                     Leonardo Cerruti    <s317664@studenti.polito.it>
--
-- Date              : 19.04.2023
-- Last Modified Date: 30.07.2023
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

entity sum_generator is
  generic (
    nbit_per_block_g: integer;
    nblocks_g:        integer);
  port (
    a:  in      std_logic_vector(nbit_per_block_g*nblocks_g-1 downto 0);
    b:  in      std_logic_vector(nbit_per_block_g*nblocks_g-1 downto 0);
    ci: in      std_logic_vector(nblocks_g-1 downto 0);
    s:  out     std_logic_vector(nbit_per_block_g*nblocks_g-1 downto 0)
  );
end entity;

architecture structural of sum_generator is

  component carry_select_block is 
    generic (nbit_g: positive);
    port (
      a:  in  std_logic_vector(nbit_g-1 downto 0);
      b:  in  std_logic_vector(nbit_g-1 downto 0);
      ci: in  std_logic;
      s:  out std_logic_vector(nbit_g-1 downto 0)
    );
  end component; 

begin

  csb_gen : for i in nblocks_g downto 1 generate
    subtype block_range_t is
      natural range i*nbit_per_block_g-1 downto (i-1)*nbit_per_block_g;
  begin
    csb_i : carry_select_block
    generic map (nbit_per_block_g)
    port map (
      a  => a(block_range_t),
      b  => b(block_range_t),
      ci => ci(i-1),
      s  => s(block_range_t)
    );
  end generate;

end architecture;
