-- File              : fill_spill_addr_logic.vhd
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

entity fill_spill_addr_logic is
  generic (
    M: positive := 8;  -- number of global registers
    N: positive := 8;  -- number of registers per register subset
    F: positive := 8   -- number of register sets
  );
  port (
    rf_add_rd1: out std_logic_vector(clog2(M+2*N*F)-1 downto 0);   -- internal register file
    rf_add_wr:  out std_logic_vector(clog2(M+2*N*F)-1 downto 0);   -- internal register file
    tcM3N:      out std_logic;
    tcM:        out std_logic;

    add_rd1:    in  std_logic_vector(clog2(M+3*N)-1 downto 0);
    add_wr:     in  std_logic_vector(clog2(M+3*N)-1 downto 0);
    pointer:    in  std_logic_vector(ilog2(F)-1 downto 0);
    bypass:     in  std_logic;

    sc_sel:     in  std_logic;
    up_down_n:  in  std_logic;
    load:       in  std_logic;
    cnt_en:     in  std_logic;
    clk:        in  std_logic
  );
end entity;

architecture mixed of fill_spill_addr_logic is

  component reg_addr_decoder is
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
  end component;

  signal sc_mux_y, addr_cnt : unsigned(clog2(M+3*N)-1 downto 0);
  signal addr_spill_mux_y, addr_fill_mux_y : std_logic_vector(clog2(M+3*N)-1 downto 0);
  
  constant sc_mux_1 : unsigned(clog2(M+3*N)-1 downto 0) := to_unsigned(M+3*N-1, addr_cnt'length);
  constant sc_mux_0 : unsigned(clog2(M+3*N)-1 downto 0) := to_unsigned(M+N, addr_cnt'length);

begin

  -- fill spill element count
  sc_mux : 
  sc_mux_y <= sc_mux_0 when sc_sel = '0' else
              sc_mux_1;

  addr_p : process (clk) is
  begin
    if rising_edge(clk) then
      if load = '1' then
        addr_cnt <= sc_mux_y;

      elsif cnt_en = '1' then
        if up_down_n = '1' then
          addr_cnt <= addr_cnt + 1;
        else
          addr_cnt <= addr_cnt - 1;
        end if;
      end if;
    end if;
  end process;

  tcM3N <= '1' when addr_cnt = to_unsigned(M+3*N, addr_cnt'length) else
           '0';
  tcM   <= '1' when addr_cnt = sc_mux_0 else
           '0';

  -- address generation
  addr_spill_mux : 
  addr_spill_mux_y <= add_rd1 when bypass = '0' else
                      std_logic_vector(addr_cnt);
  addr_fill_mux : 
  addr_fill_mux_y  <= add_wr when bypass = '0' else
                      std_logic_vector(addr_cnt);

  dec_rd_spill : reg_addr_decoder
  generic map (M, N, F)
  port map (
    cwp         => pointer,
    reg_addr    => addr_spill_mux_y,
    rf_reg_addr => rf_add_rd1
  );

  dec_wr_fill : reg_addr_decoder
  generic map (M, N, F)
  port map (
    cwp         => pointer,
    reg_addr    => addr_fill_mux_y,
    rf_reg_addr => rf_add_wr
  );

end architecture;
