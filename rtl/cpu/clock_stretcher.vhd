library IEEE;
use IEEE.std_logic_1164.all;

entity clock_stretcher is
    generic (
        DIVIDER : integer := 4  -- Pas utilisé dans cette version, mais gardé pour compatibilité
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
    signal clk_div : std_logic;
    signal clk_latched : std_logic;
begin

    -- Diviseur par 2
    process(clk_in, reset_n)
    begin
        if reset_n = '0' then
            clk_div <= '0';
        elsif rising_edge(clk_in) then
            clk_div <= not clk_div;
        end if;
    end process;
    
    -- Latch conditionnel
    process(clk_in, reset_n)
    begin
        if reset_n = '0' then
            clk_latched <= '0';
        elsif rising_edge(clk_in) then
            if mrdy = '1' then
                clk_latched <= clk_div;
            end if;
        end if;
    end process;
    
    clk_out <= clk_latched;
    stretch_active <= not mrdy;
    
end rtl;

--library IEEE;
--use IEEE.std_logic_1164.all;
--use IEEE.numeric_std.all;
--
--entity clock_stretcher is
--    generic (
--        DIVIDER : integer := 4
--    );
--    port (
--        clk_in         : in  std_logic;
--        reset_n        : in  std_logic;
--        mrdy           : in  std_logic;
--        stretch_active : out std_logic;
--        clk_out        : out std_logic
--    );
--end entity;
--
--architecture rtl of clock_stretcher is
--    signal cnt : integer range 0 to DIVIDER - 1;
--begin
--
--    -- Combinational outputs
--    -- We are "stretching" if the counter is at the High-phase value 
--    -- and the peripheral is holding mrdy low.
--    stretch_active <= '1' when (cnt = DIVIDER - 1 and mrdy = '0') else '0';
--    
--    -- clk_out follows the counter
--    clk_out <= '1' when (cnt >= DIVIDER / 2) else '0';
--
--    process (clk_in, reset_n)
--    begin
--        if reset_n = '0' then
--            cnt <= 0;
--        elsif rising_edge(clk_in) then
--            if cnt = (DIVIDER / 2) - 1 then
--                -- We are at the end of the LOW phase. 
--                -- Transition to HIGH phase normally.
--                cnt <= cnt + 1;
--                
--            elsif cnt = DIVIDER - 1 then
--                -- We are in the HIGH phase.
--                if mrdy = '1' then
--                    -- Peripheral is ready, wrap to 0 (end the cycle)
--                    cnt <= 0;
--                else
--                    -- Peripheral NOT ready, stay at max count (STRETCH)
--                    cnt <= DIVIDER - 1;
--                end if;
--                
--            else
--                -- Middle of a phase (relevant if DIVIDER > 2)
--                cnt <= cnt + 1;
--            end if;
--        end if;
--    end process;
--end rtl;
--
----architecture rtl of clock_stretcher is
----    signal cnt : integer range 0 to DIVIDER - 1;
----    -- It is highly recommended to synchronize mrdy to clk_in to avoid metastability
----    signal mrdy_sync : std_logic; 
----begin
----
----    -- Combinational output for stretch_active
----    -- Active if we are in the High phase AND the peripheral is saying "not ready"
----    stretch_active <= '1' when (cnt >= DIVIDER/2 and mrdy = '0') else '0';
----
----    -- Combinational output for clk_out
----    clk_out <= '1' when (cnt >= DIVIDER/2) else '0';
----
----    process (clk_in, reset_n)
----    begin
----        if reset_n = '0' then
----            cnt <= 0;
----        elsif rising_edge(clk_in) then
----            -- Check if we are in the "High" phase of clk_out
----            if (cnt >= DIVIDER / 2) and (mrdy = '0') then
----                -- STRETCH: Do not increment. 
----                -- We stay at the current count until mrdy goes high.
----                cnt <= cnt; 
----            else
----                -- NORMAL OPERATION: Increment or wrap
----                if cnt = DIVIDER - 1 then
----                    cnt <= 0;
----                else
----                    cnt <= cnt + 1;
----                end if;
----            end if;
----        end if;
----    end process;
----
----end rtl;
--
--
----
----architecture rtl of clock_stretcher is
----    signal cnt : integer range 0 to DIVIDER - 1;
----begin
----
----    -- Combinational output for stretch_active
----    -- It is only '1' when we are at the end of the cycle AND mrdy is holding us back
----    stretch_active <= '1' when (cnt >= DIVIDER/2 and mrdy = '0') else '0';
----
----    -- Combinational output for clk_out
----    -- (You can also register this if you need a cleaner signal, but this is immediate)
----    clk_out <= '1' when (cnt >= DIVIDER / 2) else '0';
----
----    process (clk_in, reset_n)
----    begin
----        if reset_n = '0' then
----            cnt <= 0;
----        elsif rising_edge(clk_in) then
----            if cnt = DIVIDER - 1 then
----                -- At the end of the High phase: only wrap to 0 if mrdy is ready
----                if mrdy = '1' then
----                    cnt <= 0;
----                else
----                    cnt <= DIVIDER - 1; -- Stay here (Stretch)
----                end if;
----            else
----                -- Normal counting for Low phase and first part of High phase
----                cnt <= cnt + 1;
----            end if;
----        end if;
----    end process;
----
----end rtl;
