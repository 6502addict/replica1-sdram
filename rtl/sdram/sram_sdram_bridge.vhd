library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sram_sdram_bridge is
    generic (
        ADDR_BITS : integer := 24;
        SDRAM_MHZ : integer := 100
    );
    port (
        sdram_clk    : in   std_logic;
        E            : in   std_logic;
        reset_n      : in   std_logic;
        
        -- SRAM-like interface (CPU side)
        sram_ce_n     : in  std_logic;
        sram_we_n     : in  std_logic;
        sram_oe_n     : in  std_logic;
        sram_addr     : in  std_logic_vector(ADDR_BITS-1 downto 0);
        sram_din      : in  std_logic_vector(7 downto 0);
        sram_dout     : out std_logic_vector(7 downto 0);
        
        -- Memory ready output (for clock stretching)
        mrdy          : out std_logic;
        
        -- SDRAM controller interface
        sdram_req     : out std_logic;
        sdram_wr_n    : out std_logic;
        sdram_addr    : out std_logic_vector(ADDR_BITS-2 downto 0);
        sdram_din     : out std_logic_vector(15 downto 0);
        sdram_dout    : in  std_logic_vector(15 downto 0);
        sdram_byte_en : out std_logic_vector(1 downto 0);
        sdram_ready   : in  std_logic;
        sdram_ack     : in  std_logic;
        debug         : out std_logic_vector(2 downto 0)
    );
end sram_sdram_bridge;

architecture rtl of sram_sdram_bridge is
    type state_type is (IDLE, WAIT_SDRAM_ACK);
    signal state             : state_type := IDLE;
    signal E_prev            : std_logic;
    signal sdram_ack_prev    : std_logic;
	signal session_active    : std_logic := '0';
	signal E_meta, E_sync    : std_logic;
	signal E_sync_prev       : std_logic;
	
begin

	debug <= "000" when state = IDLE           and session_active = '0' else -- IDLE NO SESSION ACTIVE 
	         "001" when state = IDLE           and session_active = '0' else -- SDRAM NOT YET READY 
             "010" when state = WAIT_SDRAM_ACK and sram_we_n = '1'      else -- READING 
             "011" when state = WAIT_SDRAM_ACK and sram_we_n = '0'      else -- WRITING 
             "111";

    process(sdram_clk)
        begin
        if rising_edge(sdram_clk) then
            -- Two-stage synchronizer
            E_meta <= E;           -- First FF (captures metastability)
            E_sync <= E_meta;      -- Second FF (clean output)
            E_sync_prev <= E_sync; -- Edge detection on synchronized signal
		
			sdram_ack_prev <= sdram_ack;
			
            if reset_n = '0' then
                state          <= IDLE;
                mrdy           <= '1';
                sdram_req      <= '0';
                sdram_wr_n     <= '0';
				session_active <= '0';
            else
                case state is
                    when IDLE =>
                        mrdy <= '1';
                        sdram_req <= '0';
                        -- trigger on E rising while cs is low
						if (session_active = '1') or (sram_ce_n = '0' and E_sync = '1' and E_sync_prev = '0') then
                            -- we have detect the rising edge of E combined with CS low
							session_active <= '1';
							-- we immediately block the cpu cycle
							mrdy <= '0';
						    -- no we wait until the sdram is ready with the cpu cycle blocked by mrdy
							if sdram_ready = '1' then 
                                sdram_addr  <= sram_addr(ADDR_BITS - 1 downto 1);
								--sdram_addr  <= std_logic_vector(unsigned(sram_addr(ADDR_BITS - 1 downto 1)) - 1);
								if sram_addr(0) = '0' then
									sdram_byte_en <= "01";
								else
									sdram_byte_en <= "10";
								end if;
								if sram_we_n = '1' then
									sdram_wr_n  <= '1';
								else
									sdram_wr_n  <= '0';
									-- loopback  <= sram_din; for debug
									sdram_din <= sram_din & sram_din;
								end if;
								sdram_req   <= '1';
								state <= WAIT_SDRAM_ACK;
							end if;
						end if;	
						
					when WAIT_SDRAM_ACK =>
						if sdram_ack = '1' and sdram_ack_prev = '0' then
							sdram_req <= '0';
							sdram_wr_n  <= '1';
							if sram_we_n = '1' then
								-- sram_dout <= loopback; for debug
								-- neet to get the data from sdram								
								if sram_addr(0) = '0' then
									sram_dout <= sdram_dout(7 downto 0);
								else
									sram_dout <= sdram_dout(15 downto 8);
								end if;
							end if;
							session_active <= '0';
							mrdy <= '1';
							state <= IDLE;
						end if;

            end case;
			end if;
		end if;
	end process;

end rtl;

