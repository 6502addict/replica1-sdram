library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity clock_stretcher is
    generic (
        DIVIDER : integer := 4
    );
    port (
        clk_in         : in  std_logic;
        reset_n        : in  std_logic;
        mrdy           : in  std_logic;
        stretch_active : out std_logic;
        clk_out        : out std_logic
    );
end entity;

architecture rtl of clock_stretcher is
    signal cnt : integer range 0 to DIVIDER - 1;
begin

    -- Combinational output for stretch_active
    -- It is only '1' when we are at the end of the cycle AND mrdy is holding us back
    stretch_active <= '1' when (cnt = DIVIDER - 1 and mrdy = '0') else '0';

    -- Combinational output for clk_out
    -- (You can also register this if you need a cleaner signal, but this is immediate)
    clk_out <= '1' when (cnt >= DIVIDER / 2) else '0';

    process (clk_in, reset_n)
    begin
        if reset_n = '0' then
            cnt <= 0;
        elsif rising_edge(clk_in) then
            if cnt = DIVIDER - 1 then
                -- At the end of the High phase: only wrap to 0 if mrdy is ready
                if mrdy = '1' then
                    cnt <= 0;
                else
                    cnt <= DIVIDER - 1; -- Stay here (Stretch)
                end if;
            else
                -- Normal counting for Low phase and first part of High phase
                cnt <= cnt + 1;
            end if;
        end if;
    end process;

end rtl;
