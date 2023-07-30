-- File              : bin_encoder.vhd
--
-- Description       : tree structure, recursive description
--
-- Authors           : Fabio Scatozza      <s315216@studenti.polito.it>
--                     Isacco Delpero      <s314713@studenti.polito.it>
--                     Leonardo Cerruti    <s317664@studenti.polito.it>
--
-- Date              : 04.05.2023
-- Last Modified Date: 04.05.2023
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

entity bin_encoder is
  generic (N : positive);
  port (
    x : in  std_logic_vector(2**N-1 downto 0);  -- one hot encoding
    y : out std_logic_vector(N-1 downto 0);     -- binary
    f : out std_logic                           -- valid input
  );
end entity;

architecture structural of bin_encoder is
  
  procedure priority(x : in std_logic_vector; 
                     y : out std_logic_vector; 
                     f : out std_logic) is  -- found a one?

    constant xN:            positive := x'length;  -- certainly a power of 2
    constant log2xN:        integer := ilog2(xN);

    -- auxiliary signal for changing indexing
    variable xt:            std_logic_vector(xN-1 downto 0);

    variable f_high, f_low: std_logic;
    variable y_ret:         std_logic_vector(log2xN-1 downto 0);
    variable y_high, y_low: std_logic_vector(max(log2xN-2, 0) downto 0);

  begin
    -- normalize indexes
    xt := x;

    if xN = 2 then
      -- recursion base: 2to1 encoder
      y_ret(0) := xt(1);
      f := xt(1) or xt(0);
    
    else
      -- recurse on the two halves
      priority(xt(xN-1 downto xN/2), y_high, f_high);
      priority(xt(xN/2-1 downto 0), y_low, f_low);

      -- compute the combined result
      f := f_low or f_high;

      if f_high = '1' then
        y_ret := '1' & y_high; -- MSB goes to the left
      else
        y_ret := '0' & y_low;
      end if;
    end if;

    y := y_ret;
  end procedure priority;

begin

  enc_p : process (x) is
    variable yv : std_logic_vector(N-1 downto 0);
    variable fv : std_logic;

  begin
    
    priority(x, yv, fv);
    y <= yv;
    f <= fv;
  end process;

end architecture;
