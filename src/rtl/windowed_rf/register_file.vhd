-- File              : register_file.vhd
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

entity register_file is 
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
end entity;

architecture behavioral of register_file is

  -- explicitly declare the range for addresses: the depth of the register file is 2**width_addr
  subtype addr_range is natural range 0 to 2**width_addr-1;

  -- declare a generic array of width_data-wide locations
  type reg_array is array(natural range <>) of std_logic_vector(width_data-1 downto 0);

  -- the actual register file
  signal registers : reg_array(addr_range);

begin 

  rf_p : process (clk) is
  begin
    if rising_edge(clk) then

      if reset = '1' then

        -- clear all registers
        clear_all : for i in addr_range loop
          registers(i) <= (others => '0');
        end loop;

        -- write through
        out1 <= (others => '0');
        out2 <= (others => '0');

      elsif enable = '1' then
        
        -- read before write
        if rd1 = '1' then
          out1 <= registers(to_integer(unsigned(add_rd1)));
        end if;

        if rd2 = '1' then
          out2 <= registers(to_integer(unsigned(add_rd2)));
        end if;

        if wr = '1' then
          registers(to_integer(unsigned(add_wr))) <= datain;
        end if;

      end if;

    end if;
  end process;

end architecture;
