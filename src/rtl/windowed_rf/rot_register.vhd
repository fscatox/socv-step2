-- File              : rot_register.vhd
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

entity rot_register is
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
end entity;

architecture behavioral of rot_register is
begin

  rot_reg_p : process (clk) is
    variable qbuf : unsigned(nbit-1 downto 0);

  begin
    if rising_edge(clk) then
      if reset = '1' then
        qbuf := unsigned(rv);
      elsif rot_en = '1' then
        if right_left_n = '1' then
          qbuf := rotate_right(qbuf, count);
        else
          qbuf := rotate_left(qbuf, count);
        end if;
      end if;

      q <= std_logic_vector(qbuf);
    end if;
  end process;

end architecture;
