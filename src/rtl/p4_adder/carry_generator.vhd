-- File              : carry_generator.vhd
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
use work.pkg_imath.all;

entity carry_generator is
  generic (
    nbit:           integer := 32;
    nbit_per_block: integer := 4);
  port (
    a:   in	std_logic_vector(nbit-1 downto 0);
    b:   in	std_logic_vector(nbit-1 downto 0);
    cin: in	std_logic;
    co:  out	std_logic_vector((nbit/nbit_per_block)-1 downto 0));
end entity;

architecture structural of carry_generator is 
  constant log2n : integer := ilog2(nbit);
  constant log2s : integer := ilog2(nbit_per_block);

  component sparse_tree is
    generic(
      log2n_g: positive; -- log2n_g = log2(nbit_g): parallelism must be a power of 2
      log2s_g: positive  -- log2s_g = log2(sparseness_g): sparseness must be a power of 2
    );
    port(
    g, p  : in  std_logic_vector(2**log2n_g downto 1);
    c     : out std_logic_vector(2**(log2n_g-log2s_g) downto 1)
  );
  end component;

  component pg_network is
    generic (nbit_g : positive);
    port (
    a, b: in  std_logic_vector(nbit_g downto 1);
    ci:   in  std_logic;
    g, p: out std_logic_vector(nbit_g downto 1)
  ); 
  end component;

  signal glue_g, glue_p : std_logic_vector(nbit downto 1);

begin

  sparse_tree_i : sparse_tree
  generic map (log2n, log2s)
  port map (
    g => glue_g,
    p => glue_p,
    c => co
  );

  pg_network_i : pg_network
  generic map (nbit)
  port map(
    a  => a,
    b  => b,
    ci => cin,
    g  => glue_g,
    p  => glue_p
  );

  assert (log2n /= -1) and (log2s /= -1)
  report "carry_generator: nbit, nbit_per_block must be powers of 2"
  severity FAILURE;

end architecture;
