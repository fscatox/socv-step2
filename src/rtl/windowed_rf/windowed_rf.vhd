-- File              : windowed_rf.vhd
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

entity windowed_rf is
  generic (
    M:          positive := 8;  -- number of global registers
    N:          positive := 8;  -- number of registers per register subset 
    F:          positive := 8;  -- number of register sets (N "in" + N "local")

    width_data: positive := 64  -- parallelism of data
  );
  port (
    clk:      in  std_logic;
    reset:    in  std_logic;  -- synchronous, write-through
    enable:   in  std_logic;  -- gates rd1, rd2, wr

    -- 2R / 1W ports 
    rd1:      in  std_logic;  -- enables synchronous reading on port R1
    rd2:      in  std_logic;  -- enables synchronous reading on port R2
    wr:       in  std_logic;  -- enables synchronous writing

    -- Addressing convention:
    -- Windowed Register Address  Register Address
    --   in[0] - in[N-1]            r[M+2*N] - r[M+3*N-1]
    --   local[0] - local[N-1]      r[M+N] - r[M+2*N-1]
    --   out[0] - out[N-1]          r[M] - r[M+N-1]
    --   global[0] - global[M-1]    r[0] - r[M-1]

    add_rd1:  in  std_logic_vector(clog2(M+3*N)-1 downto 0);
    add_rd2:  in  std_logic_vector(clog2(M+3*N)-1 downto 0);
    add_wr:   in  std_logic_vector(clog2(M+3*N)-1 downto 0);

    datain:   in  std_logic_vector(width_data-1 downto 0);
    out1:     out std_logic_vector(width_data-1 downto 0);
    out2:     out std_logic_vector(width_data-1 downto 0);

    -- execution flow control
    call:     in  std_logic;  -- subroutine call
    ret:      in  std_logic;  -- subroutine return
    bypass:   out std_logic;  -- '0' when available for external operations

    -- interface to memory management unit
    fill:     out std_logic;
    spill:    out std_logic;

    mmu_done: in  std_logic;  -- fill/spill synchronization
    mmu_data: in  std_logic_vector(width_data-1 downto 0)
  );
end entity;

architecture structural of windowed_rf is

  component register_file is 
    generic (
      width_addr : positive := 5; -- parallelism of addresses
      width_data : positive := 64 -- parallelism of data
    );
    port ( 
      clk:     in std_logic;
      reset:   in std_logic;  -- synchronous, write-through
      enable:  in std_logic;  -- gates rd1, rd2, wr

    -- 2R / 1W ports 
      rd1:     in std_logic;  -- enables synchronous reading on port R1
      rd2:     in std_logic;  -- enables synchronous reading on port R2
      wr:      in std_logic;  -- enables synchronous writing

      add_rd1: in std_logic_vector(width_addr-1 downto 0);
      add_rd2: in std_logic_vector(width_addr-1 downto 0);
      add_wr:  in std_logic_vector(width_addr-1 downto 0);

      datain:  in  std_logic_vector(width_data-1 downto 0);
      out1:    out std_logic_vector(width_data-1 downto 0);
      out2:    out std_logic_vector(width_data-1 downto 0)
    );
  end component;

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

  component bin_encoder is
    generic (N : positive);
    port (
      x : in  std_logic_vector(2**N-1 downto 0);  -- one hot encoding
      y : out std_logic_vector(N-1 downto 0);     -- binary
      f : out std_logic                           -- valid input
    );
  end component;

  component rot_register is
    generic (
      nbit : positive;
      count : positive; -- rotation bit count
      rv : std_logic_vector -- reset vector
    );
    port (
      q:            out std_logic_vector(nbit -1 downto 0);
      right_left_n: in  std_logic;
      rot_en:       in  std_logic;
      reset:        in  std_logic; -- synchronous
      clk:          in  std_logic
    );
  end component;

  component up_down_counter is
    generic (nbit : positive);
    port (
      cnt:       out std_logic_vector(nbit-1 downto 0);
      up_down_n: in  std_logic;
      cnt_en:    in  std_logic;
      reset:     in  std_logic; -- synchronous
      clk:       in  std_logic
    );
  end component;

  component fill_spill_addr_logic is
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
  end component;

  component subroutine_control is
    port (
      call:             in  std_logic;
      ret:              in  std_logic;
      mmu_done:         in  std_logic;
      wim_cwp:          in  std_logic;
      addr_tcM3N:       in  std_logic;
      addr_tcM:         in  std_logic;

      spill:            out std_logic;
      fill:             out std_logic;
      bypass:           out std_logic;
      su_enable:        out std_logic;
      su_rd:            out std_logic;
      su_wr:            out std_logic;
      addr_up_down_n:   out std_logic;
      addr_cnt_en:      out std_logic;
      addr_load:        out std_logic;
      sc_sel:           out std_logic;
      wim_right_left_n: out std_logic;
      wim_rot_en:       out std_logic;
      cwp_up_down_n:    out std_logic;
      cwp_cnt_en:       out std_logic;

      reset:            in  std_logic;
      clk:              in  std_logic
    );
  end component;

  signal wim_cwp, addr_tcM3N, addr_tcM, 
         bypass_buf, 
         su_enable, su_rd, su_wr, 
         addr_up_down_n, addr_cnt_en, addr_load, sc_sel, 
         wim_right_left_n, wim_rot_en, cwp_up_down_n, cwp_cnt_en : std_logic;
  
  signal wim_q : std_logic_vector(F-1 downto 0);
  signal cwp_cnt, wim_enc_y, pointer_mux_y : std_logic_vector(ilog2(F)-1 downto 0);

  signal rf_add_rd1, rf_add_rd2, rf_add_wr : std_logic_vector(clog2(M+2*N*F)-1 downto 0);

  signal datain_mux_y : std_logic_vector(width_data-1 downto 0);
  signal rf_rd1, rf_wr, rf_enable : std_logic;

begin
  
  -- control unit
  cu : subroutine_control
  port map (
    call, ret, mmu_done,
    wim_cwp,
    addr_tcM3N, addr_tcM,
    spill, fill,
    bypass_buf, su_enable, su_rd, su_wr,
    addr_up_down_n, addr_cnt_en, addr_load,
    sc_sel,
    wim_right_left_n, wim_rot_en,
    cwp_up_down_n, cwp_cnt_en,
    reset, clk
  );

  bypass <= bypass_buf;

  -- pointer generation
  wim : rot_register
  generic map (
    nbit  => F,
    count => 1,
    rv    => std_logic_vector(to_unsigned(2, F)) 
  )
  port map (
    wim_q,
    wim_right_left_n,
    wim_rot_en,
    reset,
    clk
  );
  
  cwp : up_down_counter
  generic map (ilog2(F))
  port map (
    cwp_cnt,
    cwp_up_down_n,
    cwp_cnt_en,
    reset,
    clk
  );

  wim_mux : 
  wim_cwp <= wim_q(to_integer(unsigned(cwp_cnt)));

  wim_enc : bin_encoder
  generic map (N => ilog2(F))
  port map(wim_q, wim_enc_y, open);

  pointer_mux :
  pointer_mux_y <= cwp_cnt when bypass_buf = '0' else
                   wim_enc_y;

  -- full address logic
  fill_spill_addr_logic_i : fill_spill_addr_logic
  generic map (M, N, F)
  port map (
    rf_add_rd1,
    rf_add_wr,
    addr_tcM3N,
    addr_tcM,

    add_rd1,
    add_wr,
    pointer_mux_y,
    bypass_buf,

    sc_sel,
    addr_up_down_n,
    addr_load,
    addr_cnt_en,
    clk
  );

  dec_rd2 : reg_addr_decoder
  generic map (M, N, F)
  port map (cwp_cnt, add_rd2, rf_add_rd2); 

  -- internal register file
  datain_mux :
  datain_mux_y <= datain when bypass_buf = '0' else
                  mmu_data;
  overwrite_rd :
  rf_rd1 <= su_rd or rd1;
 
  overwrite_wr : 
  rf_wr <= su_wr or wr;

  enable_mux :
  rf_enable <= enable when bypass_buf = '0' else
               su_enable;

  rf : register_file
  generic map (
    width_addr => clog2(M+2*N*F),
    width_data => width_data
  )
  port map (
    clk,
    reset,
    rf_enable,

    rf_rd1,
    rd2,
    rf_wr,

    rf_add_rd1,
    rf_add_rd2,
    rf_add_wr,

    datain_mux_y,
    out1,
    out2
  );

end architecture;
