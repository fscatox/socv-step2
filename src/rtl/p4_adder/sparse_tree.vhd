-- File              : sparse_tree.vhd
--
-- Description       : radix 2^1, sklansky sparse tree adder.
-- Starting from the signals of the recursion base 
--
--     g(nbit_g downto 1), p(nbit_g downto 1)
-- 
-- the network computes the prefixes corresponding to the carry-out
-- signals with a given sparseness
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
use work.pkg_graph.all;

entity sparse_tree is
  generic(
    log2n_g: positive; -- log2n_g = log2(nbit_g): parallelism must be a power of 2
    log2s_g: positive  -- log2s_g = log2(sparseness_g): sparseness must be a power of 2
  );
  port(
    g, p  : in  std_logic_vector(2**log2n_g downto 1);
    c     : out std_logic_vector(2**(log2n_g-log2s_g) downto 1)
  );
end entity;

architecture structural of sparse_tree is

  component group_G is
    port(
      pik, gik  : in  std_logic;
      gkm1j     : in  std_logic;
      gij       : out std_logic
    );
  end component;

  component group_PG is
    port(
      pik, gik      : in  std_logic;
      pkm1j, gkm1j  : in  std_logic;
      pij, gij      : out std_logic
    );
  end component;

  -- utility
  constant n : natural := 2**log2n_g;
  constant s : natural := 2**log2s_g;

  -- Interconnect matrix
  -- one level for each one of the binary tree, plus level 0 for the stimuli
  type wiring_mx_t is array (natural range<>) of std_logic_vector(n downto 1);
  signal g_glue, p_glue : wiring_mx_t(0 to log2n_g);


  -- at level l, we're connecting nodes 2**(l-1) positions apart on the
  -- previous level. Hence, when 2**(l-1) > s we need to add
  -- extra nodes to complete the tree
  constant vl : natural := log2s_g + 1; -- level where the violation occurs

begin

  -- place nodes
  traverse_levels : for l in 1 to log2n_g generate
    constant ic : natural := 2**l;      -- increment for current level
    constant ip : natural := 2**(l-1);  -- increment for previous level
    constant fp : natural := ip;        -- first node, previous level

  begin

    binary_tree_nodes : for i in 1 to 2**(log2n_g - l) generate
      -- index i is built to count in 'ic' steps

      pick_node_G : if i = 1 generate
        first_node_G : group_G
        port map(
          pik   => p_glue(l-1)(i*ic),
          gik   => g_glue(l-1)(i*ic),
          gkm1j => g_glue(l-1)(i*ic-ip),
          gij   => g_glue(l)(i*ic)
        );
      end generate;

      pick_node_PG : if i /= 1 generate
        node_PG : group_PG
        port map(
          pik   => p_glue(l-1)(i*ic),
          gik   => g_glue(l-1)(i*ic),
          pkm1j => p_glue(l-1)(i*ic-ip),
          gkm1j => g_glue(l-1)(i*ic-ip),
          pij   => p_glue(l)(i*ic),
          gij   => g_glue(l)(i*ic)
        );
      end generate;

    end generate binary_tree_nodes;

    extra_nodes : if l > vl generate
    constant ce_no : natural := 2**(l-vl)-1; -- # of consecutive extra nodes

    begin

      consecutive_extra : for i in 1 to ce_no generate
      constant fex : natural := fp + s*i; -- chosen extra node
      constant nce_no : natural := n/ic;  -- # of non-consecutive extra nodes

      begin

        -- non_consecutive extra nodes are 2**l positions apart
        non_consecutive_extra : for j in 0 to nce_no - 1 generate
        begin

          pick_extra_node_G : if j = 0 generate
            first_extra_node_G : group_G
            port map(
              pik   => p_glue(l-1)(fex + j*ic),
              gik   => g_glue(l-1)(fex + j*ic),
              gkm1j => g_glue(l-1)(fp + j*ic),
              gij   => g_glue(l)(fex + j*ic)
            );
          end generate;

          pick_extra_node_PG : if j /= 0 generate
            extra_node_PG : group_PG
            port map(
              pik   => p_glue(l-1)(fex + j*ic),
              gik   => g_glue(l-1)(fex + j*ic),
              pkm1j => p_glue(l-1)(fp + j*ic),
              gkm1j => g_glue(l-1)(fp + j*ic),
              pij   => p_glue(l)(fex + j*ic),
              gij   => g_glue(l)(fex + j*ic)
            );
          end generate;

        end generate non_consecutive_extra;

      end generate consecutive_extra;

    end generate extra_nodes;

    wires : for i in 1 to 2**(log2n_g-log2s_g) generate

      noextra_nobinary : if l = vl and ((s*i) mod (2**l)) /= 0 generate
        -- here because: there isn't an extra node, there isn't a binary tree node.
        g_glue(l)(s*i) <= g_glue(l-1)(s*i);
        p_glue(l)(s*i) <= p_glue(l-1)(s*i);

      end generate noextra_nobinary;

      possible_extra : if l > vl generate
        -- here because: there can be extra nodes
        -- therefore check if it's an extra node, knowing that the first one
        -- is at an index such that (index - (2**(l-1)+s)) is a multiple of 2**l

        
        noextra_nobinary_vl : if ((s*i) mod (2**l)) /= 0 and extraNode(s, vl, l, i) = false generate
            -- here because: there isn't an extra nodes, there isn't a binary tree node.
          g_glue(l)(s*i) <= g_glue(l-1)(s*i);
          p_glue(l)(s*i) <= p_glue(l-1)(s*i);

        end generate noextra_nobinary_vl;

      end generate possible_extra;

    end generate wires;

  end generate traverse_levels;


  -- connect stimuli
  g_glue(0) <= g;
  p_glue(0) <= p;

  -- export carry lines
  carry_out_lines_p : process(g_glue(log2n_g)) is
    variable ctmp : std_logic_vector(2**(log2n_g-log2s_g) downto 1); -- to have a single driver
  begin

    select_prefixes : for i in 1 to 2**(log2n_g-log2s_g) loop
      ctmp(i) := g_glue(log2n_g)(s*i);
    end loop;

    c <= ctmp;

  end process;

  assert log2n_g > log2s_g
  report "sparse_tree: detected log2(nbit) <= log2(nbit_per_block)"
  severity FAILURE;

end architecture;
