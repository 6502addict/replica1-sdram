--------------------------------------------------------------------------
-- To configure the machine search "Board Configuration Parameters"
-- and adapt the configuration to your needs 
--------------------------------------------------------------------------

-- Notes: ---------------------------------------------------------------------
-- Till now the integrated usb serial of the DE1-SOC is failing
-- the serial port must be connected via a FTDI cable to GPIO
-------------------------------------------------------------------------------


library IEEE;
    use IEEE.std_logic_1164.all;
    use ieee.numeric_std.all; 
   
   
entity DE1_SoC_Replica1 is
    port (
        --------- ADC ---------
        ADC_CONVST       : out   std_logic;
        ADC_DIN          : out   std_logic;
        ADC_DOUT         : in    std_logic;
        ADC_SCLK         : out   std_logic;

        --------- AUD ---------
        AUD_ADCDAT       : in    std_logic;
        AUD_ADCLRCK      : inout std_logic;
        AUD_BCLK         : inout std_logic;
        AUD_DACDAT       : out   std_logic;
        AUD_DACLRCK      : inout std_logic;
        AUD_XCK          : out   std_logic;

        --------- CLOCKS ---------
        CLOCK2_50        : in    std_logic;
        CLOCK3_50        : in    std_logic;
        CLOCK4_50        : in    std_logic;
        CLOCK_50         : in    std_logic;

        --------- DRAM ---------
        DRAM_ADDR        : out   std_logic_vector(12 downto 0);
        DRAM_BA          : out   std_logic_vector(1 downto 0);
        DRAM_CAS_N       : out   std_logic;
        DRAM_CKE         : out   std_logic;
        DRAM_CLK         : out   std_logic;
        DRAM_CS_N        : out   std_logic;
        DRAM_DQ          : inout std_logic_vector(15 downto 0);
        DRAM_LDQM        : out   std_logic;
        DRAM_RAS_N       : out   std_logic;
        DRAM_UDQM        : out   std_logic;
        DRAM_WE_N        : out   std_logic;

        --------- FAN ---------
        FAN_CTRL         : out   std_logic;

        --------- FPGA I2C ---------
        FPGA_I2C_SCLK    : out   std_logic;
        FPGA_I2C_SDAT    : inout std_logic;

        --------- GPIO ---------
        GPIO_0           : inout std_logic_vector(35 downto 0);
        GPIO_1           : inout std_logic_vector(35 downto 0);

        --------- HEX Displays ---------
        HEX0             : out   std_logic_vector(6 downto 0);
        HEX1             : out   std_logic_vector(6 downto 0);
        HEX2             : out   std_logic_vector(6 downto 0);
        HEX3             : out   std_logic_vector(6 downto 0);
        HEX4             : out   std_logic_vector(6 downto 0);
        HEX5             : out   std_logic_vector(6 downto 0);

        -- Note: VHDL does not have a direct equivalent to Verilog `ifdef.
        -- These HPS ports are included here; comment them out if HPS is disabled.
        --------- HPS ---------
--        HPS_CONV_USB_N   : inout std_logic;
--        HPS_DDR3_ADDR    : out   std_logic_vector(14 downto 0);
--        HPS_DDR3_BA      : out   std_logic_vector(2 downto 0);
--        HPS_DDR3_CAS_N   : out   std_logic;
--        HPS_DDR3_CKE     : out   std_logic;
--        HPS_DDR3_CK_N    : out   std_logic;
--        HPS_DDR3_CK_P    : out   std_logic;
--        HPS_DDR3_CS_N    : out   std_logic;
--        HPS_DDR3_DM      : out   std_logic_vector(3 downto 0);
--        HPS_DDR3_DQ      : inout std_logic_vector(31 downto 0);
--        HPS_DDR3_DQS_N   : inout std_logic_vector(3 downto 0);
--        HPS_DDR3_DQS_P   : inout std_logic_vector(3 downto 0);
--        HPS_DDR3_ODT     : out   std_logic;
--        HPS_DDR3_RAS_N   : out   std_logic;
--        HPS_DDR3_RESET_N : out   std_logic;
--        HPS_DDR3_RZQ     : in    std_logic;
--        HPS_DDR3_WE_N    : out   std_logic;
--        HPS_ENET_GTX_CLK : out   std_logic;
--        HPS_ENET_INT_N   : inout std_logic;
--        HPS_ENET_MDC     : out   std_logic;
--        HPS_ENET_MDIO    : inout std_logic;
--        HPS_ENET_RX_CLK  : in    std_logic;
--        HPS_ENET_RX_DATA : in    std_logic_vector(3 downto 0);
--        HPS_ENET_RX_DV   : in    std_logic;
--        HPS_ENET_TX_DATA : out   std_logic_vector(3 downto 0);
--        HPS_ENET_TX_EN   : out   std_logic;
--        HPS_FLASH_DATA   : inout std_logic_vector(3 downto 0);
--        HPS_FLASH_DCLK   : out   std_logic;
--        HPS_FLASH_NCSO   : out   std_logic;
--        HPS_GSENSOR_INT  : inout std_logic;
--        HPS_I2C1_SCLK    : inout std_logic;
--        HPS_I2C1_SDAT    : inout std_logic;
--        HPS_I2C2_SCLK    : inout std_logic;
--        HPS_I2C2_SDAT    : inout std_logic;
--        HPS_I2C_CONTROL  : inout std_logic;
--        HPS_KEY          : inout std_logic;
--        HPS_LED          : inout std_logic;
--        HPS_LTC_GPIO     : inout std_logic;
--        HPS_SD_CLK       : out   std_logic;
--        HPS_SD_CMD       : inout std_logic;
--        HPS_SD_DATA      : inout std_logic_vector(3 downto 0);
--        HPS_SPIM_CLK     : out   std_logic;
--        HPS_SPIM_MISO    : in    std_logic;
--        HPS_SPIM_MOSI    : out   std_logic;
--        HPS_SPIM_SS      : inout std_logic;
--        HPS_UART_RX      : in    std_logic;
--        HPS_UART_TX      : out   std_logic;
--        HPS_USB_CLKOUT   : in    std_logic;
--        HPS_USB_DATA     : inout std_logic_vector(7 downto 0);
--        HPS_USB_DIR      : in    std_logic;
--        HPS_USB_NXT      : in    std_logic;
--        HPS_USB_STP      : out   std_logic;

        --------- IRDA ---------
        IRDA_RXD         : in    std_logic;
        IRDA_TXD         : out   std_logic;

        --------- KEY ---------
        KEY              : in    std_logic_vector(3 downto 0);

        --------- LEDR ---------
        LEDR             : out   std_logic_vector(9 downto 0);

        --------- PS2 ---------
        PS2_CLK          : inout std_logic;
        PS2_CLK2         : inout std_logic;
        PS2_DAT          : inout std_logic;
        PS2_DAT2         : inout std_logic;

        --------- SW ---------
        SW               : in    std_logic_vector(9 downto 0);

        --------- TD ---------
        TD_CLK27         : in    std_logic;
        TD_DATA          : in    std_logic_vector(7 downto 0);
        TD_HS            : in    std_logic;
        TD_RESET_N       : out   std_logic;
        TD_VS            : in    std_logic;

        --------- VGA ---------
        VGA_B            : out   std_logic_vector(7 downto 0);
        VGA_BLANK_N      : out   std_logic;
        VGA_CLK          : out   std_logic;
        VGA_G            : out   std_logic_vector(7 downto 0);
        VGA_HS           : out   std_logic;
        VGA_R            : out   std_logic_vector(7 downto 0);
        VGA_SYNC_N       : out   std_logic;
        VGA_VS           : out   std_logic;

        --------- UART ---------
        UART_TX          : out   std_logic;
        UART_RX          : in    std_logic;
        UART_RTS         : out   std_logic;
        UART_CTS         : in    std_logic;

        --------- QSPI ---------
        QSPI_FLASH_SCLK  : out   std_logic;
        QSPI_FLASH_DATA  : inout std_logic_vector(3 downto 0);
        QSPI_FLASH_CE_n  : out   std_logic

        --------- RISC-V JTAG ---------
--        RISCV_JTAG_TCK   : in    std_logic;
--        RISCV_JTAG_TDI   : in    std_logic;
--        RISCV_JTAG_TDO   : out   std_logic;
--        RISCV_JTAG_TMS   : in    std_logic
    );
end entity DE1_SoC_Replica1;


architecture top of DE1_SOC_Replica1 is

component hexto7seg is
  generic (SEGMENTS : integer := 8);
  port (
	   hex           : in   std_logic_vector(3 downto 0);
	   seg           : out  std_logic_vector(SEGMENTS-1 downto 0)
	);
end component;

component main_clock is
	port (
		areset		: in  std_logic  := '0';
		inclk0		: in  std_logic  := '0';
		c0	  	      : out std_logic;
		c1	  	      : out std_logic;
		c2	  	      : out std_logic;
		locked		: out std_logic 
	);
end component;

component clock_divider is
    generic (divider : integer := 4);
    port (
        reset    : in  std_logic := '1';
        clk_in   : in  std_logic;
        clk_out  : out std_logic
    );
end component;

component fractional_clock_divider is
    generic (
        CLK_FREQ_HZ     : positive := 50_000_000;  
        FREQUENCY_HZ    : positive := 1_843_200      
    );
    port (
        clk_in   : in  std_logic;  
        reset_n  : in  std_logic;  
        clk_out  : out std_logic   
    );
end component;
	
component EBR_RAM is
    generic (
        RAM_SIZE_KB : integer := 32  -- 8, 16, 24, 32, 40, or 48
    );
    port (
        clock:      in std_logic;
        cs_n:       in std_logic;
        we_n:       in std_logic;
        address:    in std_logic_vector(15 downto 0);
        data_in:    in std_logic_vector(7 downto 0);
        data_out:   out std_logic_vector(7 downto 0)
    );
end component;	

component Replica1_CORE is
  generic (
		BOARD           : string   := "DE1_Lite";
		CPU_TYPE        : string  :=  "6502";        -- 6502, 65C02, 6800 or 6809
 	    CPU_CORE        : string  :=  "65XX";        -- 65XX, T65, MX65 
  	    ROM             : string   := "WOZMON65"; -- default monitor
		RAM_SIZE_KB     : positive := 8;          -- 8kb to 48kb
  	    BAUD_RATE       : integer  := 9600;       -- uart speed 1200 to 115200
		HAS_ACI         : boolean  := false;      -- add the aci (incomplete)
		HAS_MSPI        : boolean  := false;      -- add master spi  C200
		HAS_TIMER       : boolean  := false       -- add basic timer
	);
  port (
        sdram_clk      : in     std_logic;
  		main_clk       : in     std_logic;
  		serial_clk     : in     std_logic;
		reset_n        : in     std_logic;
		cpu_reset_n    : in     std_logic;
		bus_phi2       : out    std_logic;
		bus_phi1       : out    std_logic;
		bus_address    : out    std_logic_vector(15 downto 0);
		bus_data       : out    std_logic_vector(7  downto 0);
		bus_rw         : out    std_logic;
		bus_mrdy       : in     std_logic;
		bus_strch      : out    std_logic;
		bus_bshit      : out    std_logic;
		ext_ram_cs_n   : out    std_logic;		
		ext_ram_data   : in     std_logic_vector(7  downto 0);
		ext_tram_cs_n  : out    std_logic;		 
		ext_tram_data  : in     std_logic_vector(7  downto 0);
		uart_rx        : in     std_logic;
		uart_tx        : out    std_logic;
		spi_cs         : out    std_logic;
		spi_sck        : out    std_logic;
		spi_mosi       : out    std_logic;
		spi_miso       : in     std_logic;
		tape_out       : out    std_logic;
		tape_in        : in     std_logic;
		la_state       : out    std_logic_vector(1 downto 0)
  );
end component;	

component debug_clock_button is
    port (
        clk_1hz_in   : in  STD_LOGIC;         
        debug_btn    : in  STD_LOGIC;         
        debug_clk    : out STD_LOGIC         
    );
end component;

component simple_clock_switch is
    port (
        -- Available clocks
        clock_debug : in  STD_LOGIC;
        clock_1hz   : in  STD_LOGIC;
        clock_1mhz  : in  STD_LOGIC;
        clock_2mhz  : in  STD_LOGIC;
        clock_5mhz  : in  STD_LOGIC;
        clock_10mhz : in  STD_LOGIC;
        clock_15mhz : in  STD_LOGIC;
        clock_30mhz : in  STD_LOGIC;
        
        -- Switch selection (only 3 switches needed)
        SW          : in  STD_LOGIC_VECTOR(2 downto 0);  -- SW(2 downto 0)
        
        -- Output
        main_clock  : out STD_LOGIC
    );
end component;


component sdram_controller is
    generic (
        FREQ_MHZ           : integer := 100;   -- Clock frequency in MHz
        ROW_BITS           : integer := 13;    -- 13 for DE10-Lite, 12 for DE1
        COL_BITS           : integer := 10;    -- 10 for DE10-Lite, 8 for DE1
        USE_AUTO_PRECHARGE : boolean := true;  -- true = READA/WRITEA false = READ/WRITE
        USE_AUTO_REFRESH   : boolean := true   -- true = autorefresh, false = triggered refresh
    );
    port(
        clk         : in    std_logic;  -- 20MHz
        reset_n     : in    std_logic;  -- Active high
        
        -- Simple CPU interface
        req         : in    std_logic;
        wr_n        : in    std_logic;  -- 1=write, 0=read
        addr        : in    std_logic_vector(ROW_BITS+COL_BITS+1 downto 0); 
        din         : in    std_logic_vector(15 downto 0);
        dout        : out   std_logic_vector(15 downto 0);
        byte_en     : in    std_logic_vector(1 downto 0);  -- Active low (not used yet, always "00")
        ready       : out   std_logic;
        ack         : out   std_logic;
        
        -- Debug outputs for logic analyzer
        debug_state    : out   std_logic_vector(3 downto 0);  -- Current FSM state
        debug_cmd      : out   std_logic_vector(3 downto 0);  -- Current SDRAM command
--      debug_seq      : out   std_logic_vector(15 downto 0);  -- Sequence counter (lower 8 bits)
        debug_addr_10  : out   std_logic;
        debug_addr_9   : out   std_logic;
        debug_addr_0   : out   std_logic;
        debug_dqm      : out   std_logic_vector(1 downto 0);
        debug_dq_0     : out   std_logic;

        refresh_active : out   std_logic;  -- High during refresh
        
        -- SDRAM pins
        sdram_clk   : out   std_logic;
        sdram_cke   : out   std_logic;
        sdram_cs_n  : out   std_logic;
        sdram_ras_n : out   std_logic;
        sdram_cas_n : out   std_logic;
        sdram_we_n  : out   std_logic;
        sdram_ba    : out   std_logic_vector(1 downto 0);
        sdram_addr  : out   std_logic_vector(ROW_BITS-1 downto 0);
        sdram_dq    : inout std_logic_vector(15 downto 0);
        sdram_dqm   : out   std_logic_vector(1 downto 0)
    );
end component;

component sram_sdram_bridge is
    generic (
        ADDR_BITS        : integer := 24;
		SDRAM_MHZ        : integer := 75;
        GENERATE_REFRESH : boolean := true;  -- generate refresh_req  false = don't refresh
        USE_CACHE        : boolean := true;  -- enable/disable cache
        -- Cache parameters
        CACHE_SIZE_BYTES : integer := 4096;  -- 4KB cache
        LINE_SIZE_BYTES  : integer := 16;    -- 16-byte cache lines
  		RAM_BLOCK_TYPE   : string  := "M9K"   -- "M9K", "M4K", "M10K", "AUTO"
    );
    port (
        sdram_clk     : in  std_logic;
        E             : in  std_logic;
        reset_n       : in  std_logic;
        
        -- SRAM-like interface (CPU side)
        sram_ce_n     : in  std_logic;  -- Chip enable (active low)
        sram_we_n     : in  std_logic;  -- Write enable (active low)
        sram_oe_n     : in  std_logic;  -- Output enable (active low)
        sram_addr     : in  std_logic_vector(ADDR_BITS-1 downto 0);
        sram_din      : in  std_logic_vector(7 downto 0);
        sram_dout     : out std_logic_vector(7 downto 0);
        
        -- Memory ready output (for clock stretching)
        mrdy          : out std_logic;  -- HIGH=ready, LOW=stretch clock
        
        -- SDRAM controller interface
        sdram_req     : out std_logic;
        sdram_wr_n    : out std_logic;
        sdram_addr    : out std_logic_vector(ADDR_BITS-2 downto 0);  
        sdram_din     : out std_logic_vector(15 downto 0);
        sdram_dout    : in  std_logic_vector(15 downto 0);
        sdram_byte_en : out std_logic_vector(1 downto 0);
        sdram_ready   : in  std_logic;
        sdram_ack     : in  std_logic;
        cache_hitp    : out unsigned(6 downto 0);  -- 0 to 100%
     	debug         : out std_logic_vector(2 downto 0)
    );
end component;


--------------------------------------------------------------------------
-- Board Configuration Parameters 
--------------------------------------------------------------------------
constant BOARD            : string   := "DE1-SOC";
constant CPU_TYPE         : string   := "6502";                   -- 6502, 65C02, 6800, 6809
constant CPU_CORE         : string   := "MX65";                   -- 65XX or T65 or MX65
constant ROM              : string   := "WOZMON65";
constant RAM_SIZE_KB      : positive := 48;                       -- DE10-Lite supports up to 48KB
constant BAUD_RATE        : integer  := 115200;
constant HAS_ACI          : boolean  := false;
constant HAS_MSPI         : boolean  := false;
constant HAS_TIMER        : boolean  := false;
constant USE_EBR_RAM      : boolean  := true;
constant SDRAM_MHZ        : integer  := 120;
constant ROW_BITS         : integer  := 13;
constant COL_BITS         : integer  := 10;
constant ADDR_BITS        : integer  := 12; 
constant AUTO_PRECHARGE   : boolean  := false;
constant AUTO_REFRESH     : boolean  := false;
constant CACHE_DATA       : boolean  := false;
constant CACHE_SIZE_BYTES : integer  := 1024;                     -- 1KB cache
constant LINE_SIZE_BYTES  : integer  := 16;                       -- 16-byte cache lines
constant SDRAM_ADDR_WIDTH : integer  := ROW_BITS + COL_BITS + 2;  -- +2 pour BA(1:0)
constant RAM_BLOCK_TYPE   : string   := "AUTO";                   -- "M9K", "M4K", "M10K", "AUTO"

-- Notes: ---------------------------------------------------------------------
-- Beware Enabling the CACHE_DATA paramter works fine on DE10-Lite
--        but not on DE1 and DE1-SOC where the cache ram is implemented in LUT
-------------------------------------------------------------------------------


signal  address_bus    : std_logic_vector(15 downto 0);
signal  data_bus       : std_logic_vector(7 downto 0);
signal  sw_prev        : std_logic_vector(2 downto 0);
signal  ram_data       : std_logic_vector(7 downto 0);
signal  tram_data      : std_logic_vector(7 downto 0);
signal  ram_cs_n       : std_logic;
signal  tram_cs_n      : std_logic;
signal  reset_n        : std_logic;
signal  cpu_reset_n    : std_logic;
signal  main_clk       : std_logic;
signal  raw_clk        : std_logic;
signal  clock_debug    : std_logic;
signal  clock_1hz      : std_logic;
signal  clock_1mhz     : std_logic;
signal  clock_2mhz     : std_logic;
signal  clock_4mhz     : std_logic;
signal  clock_5mhz     : std_logic;
signal  clock_10mhz    : std_logic;
signal  clock_15mhz    : std_logic;
signal  clock_30mhz    : std_logic;
signal  clock_sdram    : std_logic;
signal  serial_clk     : std_logic;
signal  main_locked    : std_logic;
signal  phi2           : std_logic;
signal  phi1           : std_logic;
signal  rw             : std_logic;
signal  ram_cs         : std_logic;
signal  rom_cs         : std_logic;
signal  spi_cs         : std_logic;
signal  spi_sck        : std_logic;
signal  spi_mosi       : std_logic;
signal  spi_miso       : std_logic;

-- SDRAM Controller Interface (bridge side)
signal sdram_req       : std_logic;
signal sdram_wr_n      : std_logic;
signal sdram_addr      : std_logic_vector(10 downto 0);
signal sdram_din       : std_logic_vector(15 downto 0);
signal sdram_dout      : std_logic_vector(15 downto 0);
signal sdram_byte_en   : std_logic_vector(1 downto 0);
signal sdram_ready     : std_logic;
signal sdram_ack       : std_logic;
signal refresh_busy    : std_logic;
signal mrdy            : std_logic;

signal cache_hit      : unsigned(6 downto 0);  -- 0 to 100%
signal cache_hit_tens : unsigned(3 downto 0);  -- 0 à 10
signal cache_hit_ones : unsigned(3 downto 0);  -- 0 à 9	

signal sync_reg : std_logic_vector(2 downto 0) := "111";
signal clean_rx : std_logic := '1';

begin
	-- on the DE10 Lite the 7 seg display show the current address and data 
    
    -- Conversion binaire → BCD
    cache_hit_tens <= resize(cache_hit / 10, 4);
    cache_hit_ones <= resize(cache_hit mod 10, 4);    
    
    h0 : hexto7seg generic map (SEGMENTS => 7) port map (hex => std_logic_vector(cache_hit_ones), seg => HEX0); 
    h1 : hexto7seg generic map (SEGMENTS => 7) port map (hex => std_logic_vector(cache_hit_tens), seg => HEX1);    
    
--	h0 : hexto7seg port map  (hex => data_bus(3  downto 0),     seg => HEX0); 
--	h1 : hexto7seg port map  (hex => data_bus(7  downto 4),     seg => HEX1); 

	h2 : hexto7seg generic map (SEGMENTS => 7) port map  (hex => address_bus(3 downto 0),   seg => HEX2); 
	h3 : hexto7seg generic map (SEGMENTS => 7) port map  (hex => address_bus(7 downto 4),   seg => HEX3); 
	h4 : hexto7seg generic map (SEGMENTS => 7) port map  (hex => address_bus(11 downto 8),  seg => HEX4); 
	h5 : hexto7seg generic map (SEGMENTS => 7) port map  (hex => address_bus(15 downto 12), seg => HEX5); 

	-- reset_n is mapped to KEY 0 of the DE10 Lite
	-- reset_n is used to reset low level layers of the fpga modules
	reset_n <= KEY(0);
	
	
	-- cpu_reset_n can only go high if reset_n is high and the PLL locked
	-- cpu_reset_n only reset the cpu and the peripherals
	cpu_reset_n <= '1' when reset_n = '1' and main_locked = '1' else '0';
	
	-- MAIN clock  note on 6502 core main clock is at least twice phi2
	mclk: main_clock                port map(areset		     => not reset_n,
		                                      inclk0		 => CLOCK_50,
		                                      c0	  	     => clock_30mhz,
		                                      c1	  	     => open,
											  c2             => clock_sdram,
		                                      locked	  	 => main_locked);
														  

	-- not these clock are the main clock used by the core
	-- this clock is internaly divided by 2 so the main clock is twice the cpu clock

--	dbg: debug_clock_button              port map(clk_1hz_in      => clock_1hz,
--														       debug_btn       => KEY(1),
--														       debug_clk       => clock_debug);
																 
--	clk1hz: clock_divider             generic map(divider        => 120_000_000/1*4)
--	 									  	       port map(reset          => '1',
--																 clk_in         => MAX10_CLK1_50,
--														       clk_out        => clock_1hz);

	clk1mhz: clock_divider            generic map(divider        => 30)
	 								     port map(reset          => '1',
												  clk_in         => clock_30mhz,
												  clk_out        => clock_1mhz);

	clk2mhz: clock_divider             generic map(divider       => 15)
	 								      port map(reset         => '1',
												   clk_in        => clock_30mhz,
												   clk_out       => clock_2mhz);

   clk5mhz: clock_divider              generic map(divider       => 6)
									      port map(reset         => '1',
										           clk_in        => clock_30mhz,
										           clk_out       => clock_5mhz);

	clk10mhz: clock_divider            generic map(divider       => 3)
	 								      port map(reset         => '1',
												   clk_in        => clock_30mhz,
												   clk_out       => clock_10mhz);

	clk15mhz: clock_divider            generic map(divider       => 2)
	 								      port map(reset         => '1',
												   clk_in        => clock_30mhz,
												   clk_out       => clock_15mhz);

	csw: simple_clock_switch              port map(clock_debug   => '1', -- 000
												   clock_1hz     => '1',   -- 001
												   clock_1mhz    => clock_1mhz,  -- 010
												   clock_2mhz    => clock_2mhz,  -- 011
												   clock_5mhz    => clock_5mhz,  -- 100
												   clock_10mhz   => clock_10mhz, -- 101 
												   clock_15mhz   => clock_15mhz, -- 110 
												   clock_30mhz   => clock_30mhz, -- 111 
												   SW            => SW(2 downto 0),
												   main_clock    => raw_clk);
	process(clock_30mhz) 
	begin
		if rising_edge(clock_30mhz)  then
			sw_prev <= SW(2 downto 0);
		end if;
	end process;

	main_clk <= raw_clk when SW(2 downto 0) = sw_prev else '0';
			
	-- UART baud rate clock  1.8432Mhz base serial clock
	uclk: fractional_clock_divider   generic map(CLK_FREQ_HZ    => 50_000_000,
										 	     FREQUENCY_HZ   => 1_843_200)
	 									port map(clk_in         => CLOCK_50,
										 		 reset_n        => reset_n,
												 clk_out        => serial_clk);
															 
	ap1: Replica1_CORE               generic map(BOARD          =>  BOARD,
										  		 CPU_TYPE       =>  CPU_TYPE,    -- 6502, 65C02, 6800 or 6809
												 CPU_CORE       =>  CPU_CORE,    -- "65XX", "T65", MX65"
												 ROM            =>  ROM,         -- default wozmon65
												 RAM_SIZE_KB    =>  RAM_SIZE_KB, -- 8 to 48Kb 
												 BAUD_RATE      =>  BAUD_RATE,   -- uart speed 1200 to 115200
												 HAS_ACI        =>  HAS_ACI,     -- add the aci (incomplete)
                                                 HAS_MSPI       =>  HAS_MSPI,    -- add master spi  C200
		                                         HAS_TIMER      =>  HAS_TIMER)   -- add basic timer C210
								        port map(sdram_clk      =>  clock_sdram,
									             main_clk       =>  main_clk,
											     serial_clk     =>  serial_clk,
												 reset_n        =>  reset_n,
												 cpu_reset_n    =>  cpu_reset_n,
												 bus_phi2       =>  phi2,    
												 bus_phi1       =>  open,    
												 bus_address    =>  address_bus,
												 bus_data       =>  data_bus,
												 bus_rw         =>  rw,
												 bus_mrdy       =>  mrdy,
												 bus_strch      =>  open,
												 bus_bshit      =>  open,
												 ext_ram_cs_n   =>  ram_cs_n,
												 ext_ram_data   =>  ram_data,
												 ext_tram_cs_n  =>  tram_cs_n,
												 ext_tram_data  =>  tram_data,
												 uart_rx        =>  GPIO_1(0), --UART_RX,   --ARDUINO_IO(0),
												 uart_tx        =>  GPIO_1(1),   --ARDUINO_IO(1),
												 spi_cs         =>  GPIO_1(2), --ARDUINO_IO(4),   -- SD Card Data 3          CS
												 spi_sck        =>  GPIO_1(3), --ARDUINO_IO(13),  -- SD Card Clock           SCLK
												 spi_mosi       =>  GPIO_1(4), --ARDUINO_IO(11),  -- SD Card Command Signal  MOSI
												 spi_miso       =>  GPIO_1(5), --ARDUINO_IO(12),  -- SD Card Data            MISO
												 tape_out       =>  GPIO_1(6), --ARDUINO_IO(3),
												 tape_in        =>  GPIO_1(7), --ARDUINO_IO(2),
												 la_state       =>  open);


gen_ebr_ram: if USE_EBR_RAM = true generate
	ram: EBR_RAM                     generic map(RAM_SIZE_KB     => RAM_SIZE_KB)
								        port map(clock           => phi2,
					   	                         cs_n            => ram_cs_n,
										         we_n            => rw,
										         address         => address_bus,
										         data_in         => data_bus,
							                     data_out        => ram_data);
end generate gen_ebr_ram;																



    bridge_inst : sram_sdram_bridge  generic map(ADDR_BITS        => ADDR_BITS,
	                                             SDRAM_MHZ        => SDRAM_MHZ,
                                                 GENERATE_REFRESH => not AUTO_REFRESH,
                                                 USE_CACHE        => CACHE_DATA,
                                                 -- Cache parameters
                                                 CACHE_SIZE_BYTES => CACHE_SIZE_BYTES,  -- 1KB cache
                                                 LINE_SIZE_BYTES  => LINE_SIZE_BYTES,   -- 16-byte cache lines
                                                 RAM_BLOCK_TYPE   => RAM_BLOCK_TYPE)
									    port map(sdram_clk        => clock_sdram,
										      	 E                => phi2,
												 reset_n          => reset_n,
												 -- SRAM interface (test side)
												 sram_ce_n        => tram_cs_n,
												 sram_we_n        => rw,
												 sram_oe_n        => not rw,
												 sram_addr        => address_bus(ADDR_BITS -1  downto 0),
												 sram_din         => data_bus,
												 sram_dout        => tram_data,
            
												 -- Memory ready
												 mrdy             => mrdy,
             
                                                 -- SDRAM controller interface
												 sdram_req        => sdram_req,
												 sdram_wr_n       => sdram_wr_n,
												 sdram_addr       => sdram_addr,
												 sdram_din        => sdram_din,
												 sdram_dout       => sdram_dout,
												 sdram_byte_en    => sdram_byte_en,
												 sdram_ready      => sdram_ready,
												 sdram_ack        => sdram_ack,
                                                 cache_hitp       => cache_hit,
												 debug            => open);

                                             
    -- SDRAM Controller Instance
    sdram_inst : sdram_controller   generic map (FREQ_MHZ           => SDRAM_MHZ,
									 			 ROW_BITS           => ROW_BITS, 
												 COL_BITS           => COL_BITS,
                                                 USE_AUTO_PRECHARGE => AUTO_PRECHARGE,
                                                 USE_AUTO_REFRESH   => AUTO_REFRESH)
									   port map (clk                => clock_sdram,
												 reset_n            => reset_n,
												 req                => sdram_req,
												 wr_n               => sdram_wr_n,
												 addr               => std_logic_vector(resize(unsigned(sdram_addr), SDRAM_ADDR_WIDTH)), --(24 downto 11 => '0') & sdram_addr,
												 din                => sdram_din,
												 dout               => sdram_dout,
												 byte_en            => sdram_byte_en,
												 ready              => sdram_ready,
												 ack                => sdram_ack,
												 debug_state        => open, --debug_state,
												 debug_cmd          => open, --debug_cmd,
				 				 --		  		 debug_seq          => display(15 downto 0),
                                                 debug_addr_10      => open, --debug_addr_10,
                                                 debug_addr_9       => open, --debug_addr_9,
                                                 debug_addr_0       => open, --debug_addr_0,
                                                 debug_dqm          => open, --debug_dqm,
                                                 debug_dq_0         => open, --debug_dq_0,
												 refresh_active     => refresh_busy,
												 sdram_clk          => DRAM_CLK,
												 sdram_cke          => DRAM_CKE,
												 sdram_cs_n         => DRAM_CS_N,
												 sdram_ras_n        => DRAM_RAS_N,
												 sdram_cas_n        => DRAM_CAS_N,
												 sdram_we_n         => DRAM_WE_N,
												 sdram_ba           => DRAM_BA,
												 sdram_addr         => DRAM_ADDR,
												 sdram_dq           => DRAM_DQ,
												 sdram_dqm(1)       => DRAM_UDQM,
												 sdram_dqm(0)       => DRAM_LDQM);
																

	
	VGA_B		<= (others => 'Z');
	VGA_G   	<= (others => 'Z'); 
	VGA_HS	   	<= 'Z';
	VGA_R	 	<= (others => 'Z');  
	VGA_VS	   	<= 'Z';
		
    LEDR(0)     <= refresh_busy;    

	
end top;

