-- File              : p4_adder.vhd
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

entity p4_adder is
  generic (
    nbit:           integer := 32;
    nbit_per_block: integer := 4);
  port (
    a:    in    std_logic_vector(nbit-1 downto 0);
    b:    in    std_logic_vector(nbit-1 downto 0);
    cin:  in    std_logic;
    s:    out   std_logic_vector(nbit-1 downto 0);
    cout: out   std_logic
  );
end entity;

architecture structural of p4_adder is

  component carry_generator is
    generic (
      nbit:           integer := 32;
      nbit_per_block: integer := 4);
    port (
      a:   in   std_logic_vector(nbit-1 downto 0);
      b:   in   std_logic_vector(nbit-1 downto 0);
      cin: in   std_logic;
      co:  out  std_logic_vector((nbit/nbit_per_block)-1 downto 0)
    );
  end component;

  component sum_generator is
    generic (
      nbit_per_block_g: integer;
      nblocks_g:        integer);
    port (
      a:  in      std_logic_vector(nbit_per_block_g*nblocks_g-1 downto 0);
      b:  in      std_logic_vector(nbit_per_block_g*nblocks_g-1 downto 0);
      ci: in      std_logic_vector(nblocks_g-1 downto 0);
      s:  out     std_logic_vector(nbit_per_block_g*nblocks_g-1 downto 0)
    );
  end component;

  constant nblocks : natural := nbit/nbit_per_block;

  signal glue_c : std_logic_vector(nblocks downto 0);

begin

  glue_c(0) <= cin;
  cout <= glue_c(nblocks);

  carry_generator_i : carry_generator
  generic map (nbit, nbit_per_block)
  port map(
    a   => a,
    b   => b,
    cin => cin,
    co  => glue_c(nblocks downto 1)
  );

  sum_generator_i : sum_generator
  generic map (
    nbit_per_block_g => nbit_per_block,
    nblocks_g => nblocks
  )
  port map(
    a => a,
    b => b,
    ci => glue_c(nblocks-1 downto 0),
    s => s
  );

end architecture;
