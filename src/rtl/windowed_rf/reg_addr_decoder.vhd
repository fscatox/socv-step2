-- File              : reg_addr_decoder.vhd
--
-- Description       : Windowed Register Address Decoder
--
-- Addressing convention:
--   Windowed Register Address  Register Address
--     in[0] - in[N-1]            r[M+2*N] - r[M+3*N-1]
--     local[0] - local[N-1]      r[M+N] - r[M+2*N-1]
--     out[0] - out[N-1]          r[M] - r[M+N-1]
--     global[0] - global[M-1]    r[0] - r[M-1]
-- 
-- Mapping into the register file:
--
--   |---------|
--   | LOCAL 1 | M+2*N*F-1
--   |         |
--   |---------|
--   |  IN  2  |
--   | (OUT 1) |
--   |---------|
--   | LOCAL 2 |
--   |         |
--   |---------|
--   |  IN  3  |
--   | (OUT 2) |
--   |---------|
--   | LOCAL 3 |
--   |         |
--   |---------|
--        .
--        .
--        .
--   |---------|
--   |  IN  0  | M+3*N-1
--   |(OUT F-1)|
--   |---------| M+2*N
--   | LOCAL 0 | M+2*N-1
--   |         |
--   |---------| M+N
--   |  IN  1  | M+N-1 
--   | (OUT 0) |  
--   |---------| M
--   |         | M-1
--   | GLOBALS |
--   |         |
--   |---------| 0
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
use IEEE.numeric_std.all;
use work.pkg_imath.all;

entity reg_addr_decoder is
  generic (
    M: positive := 8;  -- number of global registers
    N: positive := 8;  -- number of registers per register subset
    F: positive := 8   -- number of register sets
  );
  port (
    cwp:         in  std_logic_vector(ilog2(F)-1 downto 0);
    reg_addr:    in  std_logic_vector(clog2(M+3*N)-1 downto 0);    -- accessible to the instruction
    rf_reg_addr: out std_logic_vector(clog2(M+2*N*F)-1 downto 0)   -- internal register file
);
end entity;

architecture behavioral of reg_addr_decoder is

  component bin_encoder is
    generic (N : positive);
    port (
      x : in  std_logic_vector(2**N-1 downto 0);  -- one hot encoding
      y : out std_logic_vector(N-1 downto 0);     -- binary
      f : out std_logic                           -- valid input
    );
  end component;

  signal reg_addr_onehot:    unsigned(M+3*N-1 downto 0);
  signal rf_reg_addr_onehot: unsigned((2**clog2(M+2*N*F))-1 downto 0);

begin

  -- convert the windowed register address to one hot encoding
  to_onehot_p: 
    reg_addr_onehot <= shift_left(to_unsigned(1, M+3*N), to_integer(unsigned(reg_addr)));

  -- Assemble the one hot encoding of the address into the internal register file:
  --   1) globals are shared by all windows
  rf_reg_addr_onehot(M-1 downto 0) <= reg_addr_onehot(M-1 downto 0);

  --   2) the remaining addressable registers belong to the window pointed by cwp
  rf_reg_addr_onehot(M+2*N*F-1 downto M) <= rotate_left(
                                              resize(reg_addr_onehot(M+3*N-1 downto M), 2*N*F), 
                                              2*N*to_integer(unsigned(cwp))
                                            );
  --   3) there may be additional floating bit if M+2*N*F is not a power of 2
  rf_reg_addr_onehot((2**clog2(M+2*N*F))-1 downto M+2*N*F) <= (others => '0');

  -- convert the resulting one hot code into binary
  -- that is, from M+2*N*F to clog2(M+2*N*F)
  rf_reg_addr_conv : bin_encoder
  generic map (clog2(M+2*N*F))
  port map (
    x => std_logic_vector(rf_reg_addr_onehot),
    y => rf_reg_addr,
    f => open
  );

  -- address space analysis
  assert ilog2(F) /= -1
  report "The number of windows (F) must be a power of 2."
  severity FAILURE;

  assert ilog2(M+3*N) /= -1
  report "There are unused windowed register addresses."
  severity WARNING;

  assert ilog2(M+2*N*F) /= -1
  report "There are unused register file addresses."
  severity WARNING;

  assert to_integer(unsigned(reg_addr)) < M+3*N
  report "Windowed register address violation."
  severity ERROR;

end architecture;
