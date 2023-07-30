-- File              : subroutine_control.vhd
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

entity subroutine_control is
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
end entity;

architecture fsm of subroutine_control is
  type state_t is (RUN, CWP_DOWN, SPILL_ONE, WAIT_SPILL, CWP_UP, WAIT_FILL, FILL_ONE);
  signal state, next_state : state_t;

begin

  transition_logic_p : process (
    state,
    call, ret,
    mmu_done,
    wim_cwp,
    addr_tcM3N, addr_tcM 
  ) is
  begin

    case state is
      when RUN        =>
        if call = '1' then
          next_state <= CWP_DOWN;
        elsif ret = '1' then
          next_state <= CWP_UP;
        else
          next_state <= RUN;
        end if;

      when CWP_DOWN   =>
        if wim_cwp = '1' then
          next_state <= SPILL_ONE;
        else
          next_state <= RUN;
        end if;

      when SPILL_ONE  =>
        next_state <= WAIT_SPILL;

      when WAIT_SPILL =>
        if mmu_done = '0' then
          next_state <= WAIT_SPILL;
        elsif addr_tcM3N = '0' then
          next_state <= WAIT_SPILL;
        else
          next_state <= RUN;
        end if;

      when CWP_UP     =>
        if wim_cwp = '1' then
          next_state <= WAIT_FILL;
        else 
          next_state <= RUN;
        end if;

      when WAIT_FILL  =>
        if mmu_done = '0' then
          next_state <= WAIT_FILL;
        else
          next_state <= FILL_ONE;
        end if;

      when FILL_ONE   =>
        if addr_tcM = '0' then
          next_state <= WAIT_FILL;
        else
          next_state <= RUN;
        end if;

      when others     =>
        next_state <= RUN;

    end case;

  end process;

  output_logic_p : process (
    state, 
    call, ret,  -- mealy (under controlled registered conditions) for better reactivity
    mmu_done,
    wim_cwp,
    addr_tcM3N, addr_tcM  
  ) is 
  begin

    -- default values
    spill            <= '0';
    fill             <= '0';
    bypass           <= '1';
    su_enable        <= '0';
    su_rd            <= '0';
    su_wr            <= '0';
    addr_up_down_n   <= '1';
    addr_cnt_en      <= '0';
    addr_load        <= '0';
    sc_sel           <= '0';
    wim_right_left_n <= '1';
    wim_rot_en       <= '0';
    cwp_up_down_n    <= '1';
    cwp_cnt_en       <= '0';

    -- actual values
    case state is
      when RUN        =>
        bypass <= '0';

        if call = '1' then
          cwp_up_down_n <= '0';
          cwp_cnt_en    <= '1';
        elsif ret = '1' then
          cwp_cnt_en <= '1';
        end if;

      when CWP_DOWN   =>
        addr_load <= '1';

        if wim_cwp = '1' then
          wim_rot_en <= '1';
        end if;

      when SPILL_ONE  =>
        spill       <= '1';
        su_enable   <= '1';
        su_rd       <= '1';
        addr_cnt_en <= '1';

      when WAIT_SPILL =>
        if mmu_done = '1' and addr_tcM3N = '0' then
          spill       <= '1';
          su_enable   <= '1';
          su_rd       <= '1';
          addr_cnt_en <= '1';
        end if;

      when CWP_UP     =>
        addr_load <= '1';
        sc_sel    <= '1';

        if wim_cwp = '1' then
          fill <= '1';
        end if;

      when FILL_ONE   =>
        su_enable      <= '1';
        su_wr          <= '1';
        addr_up_down_n <= '0';
        addr_cnt_en    <= '1';

        if addr_tcM = '0' then
          fill <= '1';
        else 
          wim_right_left_n <= '0';
          wim_rot_en <= '1';
        end if;

      when others     =>
    end case;

  end process;

  state_reg_p : process (clk) is
  begin
    if rising_edge(clk) then
      if reset = '1' then
        state <= RUN;
      else
        state <= next_state;
      end if;
    end if;
  end process;

end architecture;
