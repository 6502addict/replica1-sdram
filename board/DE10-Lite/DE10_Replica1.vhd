--------------------------------------------------------------------------
-- To configure the machine search "Board Configuration Parameters"
-- and adapt the configuration to your needs 
--------------------------------------------------------------------------


library IEEE;
	use IEEE.std_logic_1164.all;
   use ieee.numeric_std.all; 
	
entity DE10_Replica1 is
  port (
		ADC_CLK_10      :	in	    std_logic;
	
		MAX10_CLK1_50   :	in     std_logic;
		MAX10_CLK2_50   :	in     std_logic;

		DRAM_ADDR       :	out    std_logic_vector(12 downto 0);
		DRAM_BA         :	out    std_logic_vector(1 downto 0);
		DRAM_CAS_N      :	out    std_logic;
		DRAM_CKE        :	out    std_logic;
		DRAM_CLK        :	out    std_logic;
		DRAM_CS_N       :	out    std_logic;
		DRAM_DQ         :	inout  std_logic_vector(15 downto 0);
		DRAM_LDQM       :	out    std_logic;
		DRAM_RAS_N      :	out	 std_logic;
		DRAM_UDQM       :	out    std_logic;
		DRAM_WE_N       :	out	 std_logic;

		HEX0		  	    :	out    std_logic_vector(7 downto 0);
		HEX1			    :	out    std_logic_vector(7 downto 0);
		HEX2			    :	out    std_logic_vector(7 downto 0);
		HEX3			    :	out    std_logic_vector(7 downto 0);
		HEX4			    :	out    std_logic_vector(7 downto 0);
		HEX5			    :	out    std_logic_vector(7 downto 0);

		KEY				 :	in	    std_logic_vector(1 downto 0);

		LEDR			    :	out	 std_logic_vector(9 downto 0);

		SW				    :	in	    std_logic_vector(9 downto 0);
		
		VGA_B			    :	out	 std_logic_vector(3 downto 0);
		VGA_G			    :	out    std_logic_vector(3 downto 0);
		VGA_HS			 :	out	 std_logic;
		VGA_R			    : out	 std_logic_vector(3 downto 0);
		VGA_VS			 :	out	 std_logic;
		
		GSENSOR_CS_N	 :	out	 std_logic;
		GSENSOR_INT		 :	in	    std_logic_vector(2 downto 1);
		GSENSOR_SCLK	 : out    std_logic;
		GSENSOR_SDI		 :	inout  std_logic;
		GSENSOR_SDO	 	 :	inout  std_logic;

		ARDUINO_IO		 : inout  std_logic_vector(15 downto 0);
		ARDUINO_RESET_N : inout  std_logic;

		GPIO            :	inout  std_logic_vector(35 downto 0)
  );
end entity;	

architecture top of DE10_Replica1 is

component hexto7seg is
  generic (SEGMENTS  : integer := 7);
  port (
	   hex           : in   std_logic_vector(3 downto 0);
	   seg           : out  std_logic_vector(7 downto 0)
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

component frac_clk_div is
    port (
        reset_n  : in  std_logic := '1';
        clk_in   : in  std_logic;
        divider  : in  std_logic_vector(15 downto 0);  -- [15:8] integer part, [7:0] fractional part (*256)
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
  	   ROM             : string   := "WOZMON65";    -- default monitor
		RAM_SIZE_KB     : positive := 8;             -- 8kb to 48kb
  	   BAUD_RATE       : integer  := 9600;          -- uart speed 1200 to 115200
		HAS_ACI         : boolean  := false;         -- add the aci (incomplete)
		HAS_MSPI        : boolean  := false;         -- add master spi  C200
		HAS_TIMER       : boolean  := false          -- add basic timer
	);
  port (
   	main_clk       : in     std_logic;
  		serial_clk     : in     std_logic;
		reset_n        : in     std_logic;
		cpu_reset_n    : in     std_logic;
		bus_phi2       : out    std_logic;
		bus_address    : out    std_logic_vector(15 downto 0);
		bus_data       : out    std_logic_vector(7  downto 0);
		bus_rw         : out    std_logic;
		bus_mrdy       : in     std_logic;
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
		tape_in        : in     std_logic
  );
end component;	

component sdram_controller is
    generic (
        FREQ_MHZ           : integer := 100;   -- Clock frequency in MHz
        ROW_BITS           : integer := 13;    -- 13 for DE10-Lite, 12 for DE1
        COL_BITS           : integer := 10;    -- 10 for DE10-Lite, 8 for DE1
        TRP_NS             : integer := 20;    -- Precharge time (for PRECHARGE wait)
        TRCD_NS            : integer := 20;    -- RAS to CAS delay (for ACTIVE→READ/WRITE)
        TRFC_NS            : integer := 70;    -- Refresh cycle time (for AUTO REFRESH wait)
        CAS_LATENCY        : integer := 2;     -- CAS Latency: 2 or 3 cycles
        USE_AUTO_PRECHARGE : boolean := true;  -- true = READA/WRITEA false = READ/WRITE
        USE_AUTO_REFRESH   : boolean := true   -- true = autorefresh, false = triggered refresh
    );
    port(
        clk                : in    std_logic;  
        reset_n            : in    std_logic;  
        
        -- Simple CPU interface
        req                : in    std_logic;
        wr_n               : in    std_logic;  
        addr               : in    std_logic_vector(ROW_BITS+COL_BITS+1 downto 0); 
        din                : in    std_logic_vector(15 downto 0);
        dout               : out   std_logic_vector(15 downto 0);
        byte_en            : in    std_logic_vector(1 downto 0);  
        ready              : out   std_logic;
        ack                : out   std_logic;
        
        refresh_req        : in   std_logic;
        refresh_active     : out   std_logic;  
        
        -- SDRAM pins
        sdram_clk          : out   std_logic;
        sdram_cke          : out   std_logic;
        sdram_cs_n         : out   std_logic;
        sdram_ras_n        : out   std_logic;
        sdram_cas_n        : out   std_logic;
        sdram_we_n         : out   std_logic;
        sdram_ba           : out   std_logic_vector(1 downto 0);
        sdram_addr         : out   std_logic_vector(ROW_BITS - 1 downto 0);
        sdram_dq           : inout std_logic_vector(15 downto 0);
        sdram_dqm          : out   std_logic_vector(1 downto 0)
    );
end component;

component sram_sdram_bridge is
    generic (
        ADDR_BITS        : integer := 24;
		  SDRAM_MHZ        : integer := 75;
        GENERATE_REFRESH : boolean := true;               -- generate refresh_req  false = don't refresh
        USE_CACHE        : boolean := true;               -- enable/disable cache
        -- Cache parameters
        CACHE_SIZE_BYTES : integer := 4096;               -- 4KB cache
        LINE_SIZE_BYTES  : integer := 16;                 -- 16-byte cache lines
        RAM_BLOCK_TYPE   : string  := "M9K, no_rw_check"  -- "M9K", "M4K", "M10K", "AUTO"
    );
    port (
        sdram_clk        : in  std_logic;
        E                : in  std_logic;
        reset_n          : in  std_logic;
        
        -- SRAM-like interface (CPU side)
        sram_ce_n        : in  std_logic;  -- Chip enable (active low)
        sram_we_n        : in  std_logic;  -- Write enable (active low)
        sram_oe_n        : in  std_logic;  -- Output enable (active low)
        sram_addr        : in  std_logic_vector(ADDR_BITS-1 downto 0);
        sram_din         : in  std_logic_vector(7 downto 0);
        sram_dout        : out std_logic_vector(7 downto 0);
        
        -- Memory ready output (for clock stretching)
        mrdy             : out std_logic;  -- HIGH=ready, LOW=stretch clock
        
        -- SDRAM controller interface
        sdram_req        : out std_logic;
        sdram_wr_n       : out std_logic;
        sdram_addr       : out std_logic_vector(ADDR_BITS-2 downto 0);  
        sdram_din        : out std_logic_vector(15 downto 0);
        sdram_dout       : in  std_logic_vector(15 downto 0);
        sdram_byte_en    : out std_logic_vector(1 downto 0);
        sdram_ready      : in  std_logic;
        sdram_ack        : in  std_logic;
        refresh_req      : out std_logic;
        cache_hitp       : out unsigned(6 downto 0)  -- 0 to 100%
    );
end component;


--------------------------------------------------------------------------
-- Board Configuration Parameters 
--------------------------------------------------------------------------
constant BOARD            : string   := "DE10_Lite";
constant CPU_TYPE         : string   := "6502";                   -- 6502, 65C02, 6800, 6809
constant CPU_CORE         : string   := "MX65";                   -- 65XX or T65 or MX65
constant ROM              : string   := "WOZMON65";
constant RAM_SIZE_KB      : positive := 48;                       -- DE10-Lite supports up to 48KB
constant BAUD_RATE        : integer  := 115200;
constant HAS_ACI          : boolean  := false;
constant HAS_MSPI         : boolean  := false;
constant HAS_TIMER        : boolean  := false;
constant USE_EBR_RAM      : boolean  := true;                     -- true for DE10-Lite/DE1-SOC, false for DE1
constant SDRAM_MHZ        : integer  := 120;
constant ROW_BITS         : integer  := 13;
constant COL_BITS         : integer  := 10;
constant TRP_NS           : integer := 20;                        -- Precharge time (for PRECHARGE wait)
constant TRCD_NS          : integer := 20;                        -- RAS to CAS delay (for ACTIVE→READ/WRITE)
constant TRFC_NS          : integer := 70;                        -- Refresh cycle time (for AUTO REFRESH wait)
constant CAS_LATENCY      : integer := 2;                         -- CAS Latency: 2 or 3 cycles
constant ADDR_BITS        : integer  := 12; 
constant AUTO_PRECHARGE   : boolean  := false;
constant AUTO_REFRESH     : boolean  := false;
constant CACHE_DATA       : boolean  := true;                     -- actually only works fine on DE10-Lite
constant CACHE_SIZE_BYTES : integer  := 1024;                     -- 1KB cache
constant LINE_SIZE_BYTES  : integer  := 16;                       -- 16-byte cache lines
constant SDRAM_ADDR_WIDTH : integer  := ROW_BITS + COL_BITS + 2;  -- +2 pour BA(1:0)
constant RAM_BLOCK_TYPE   : string   := "M9K, no_rw_check";       -- "M9K", "M4K", "M10K", "AUTO"

signal  address_bus    : std_logic_vector(15 downto 0);
signal  data_bus       : std_logic_vector(7 downto 0);
signal  ram_data       : std_logic_vector(7 downto 0);
signal  tram_data      : std_logic_vector(7 downto 0);
signal  ram_cs_n       : std_logic;
signal  tram_cs_n      : std_logic;
signal  reset_n        : std_logic;
signal  cpu_reset_n    : std_logic;
signal  fast_clk       : std_logic;
signal  main_clk       : std_logic;
signal  sdram_clk      : std_logic;
signal  serial_clk     : std_logic;
signal  pll_locked     : std_logic;
signal  phi2           : std_logic;
signal  rw             : std_logic;
signal  ram_cs         : std_logic;
signal  rom_cs         : std_logic;

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
signal refresh_req     : std_logic;
signal cache_hit      : unsigned(6 downto 0);  -- 0 to 100%
signal cache_hit_tens : unsigned(3 downto 0);  -- 0 à 10
signal cache_hit_ones : unsigned(3 downto 0);  -- 0 à 9	
signal cpu_divider    : std_logic_vector(15 downto 0);
signal display        : std_logic_vector(23 downto 0);

begin
	-- on the DE10 Lite the 7 seg display show the current address and data 
    
    -- Conversion binaire → BCD
    cache_hit_tens <= resize(cache_hit / 10, 4);
    cache_hit_ones <= resize(cache_hit mod 10, 4);    
	 
	 display <= address_bus & data_bus                                                          when SW(9) = '0' else
	            x"0000" & std_logic_vector(cache_hit_tens) & std_logic_vector(cache_hit_ones); 
    
	h0 : hexto7seg generic map (SEGMENTS => 8) port map  (hex => display(3  downto  0),   seg => HEX0); 
	h1 : hexto7seg generic map (SEGMENTS => 8) port map  (hex => display(7  downto  4),   seg => HEX1); 
	h2 : hexto7seg generic map (SEGMENTS => 8) port map  (hex => display(11 downto  8),   seg => HEX2); 
	h3 : hexto7seg generic map (SEGMENTS => 8) port map  (hex => display(15 downto 12),   seg => HEX3); 
	h4 : hexto7seg generic map (SEGMENTS => 8) port map  (hex => display(19 downto 16),   seg => HEX4); 
	h5 : hexto7seg generic map (SEGMENTS => 8) port map  (hex => display(23 downto 20),   seg => HEX5); 


	-- reset_n is mapped to KEY 0 of the DE10 Lite
	-- reset_n is used to reset low level layers of the fpga modules
	reset_n <= KEY(0);
	
	
	-- cpu_reset_n can only go high if reset_n is high and the PLL locked
	-- cpu_reset_n only reset the cpu and the peripherals
	cpu_reset_n <= '1' when reset_n = '1' and pll_locked = '1' else '0';
	
	-- MAIN clock  note on 6502 core main clock is at least twice phi2
	mclk: main_clock                port map(areset		     => not reset_n,
		                                      inclk0		     => MAX10_CLK1_50,
		                                      c0	  	        => fast_clk,
		                                      c1	  	        => open,
														  c2             => sdram_clk,
		                                      locked	  	     => pll_locked);
														  
   cclk: frac_clk_div              port map(reset_n       => reset_n,
												 		  clk_in        => fast_clk,
														  divider       => cpu_divider,
														  clk_out       => main_clk);
														  
   sclk: frac_clk_div              port map(reset_n       => reset_n,
												 		  clk_in        => fast_clk,
														  divider       => x"411B",
														  clk_out       => serial_clk);
														  
               
	-- phi0 = phi2 * 4, divider = 120 / phi0
	-- SW(4 downto 0) selects phi2 frequency in MHz
	cpu_divider <= x"1E00" when SW(3 downto 0) = "0001" else  --  1 MHz phi2 / phi0  4 MHz  120/ 4 = 30.000 exact
						x"0F00" when SW(3 downto 0) = "0010" else  --  2 MHz phi2 / phi0  8 MHz  120/ 8 = 15.000 exact
						x"0A00" when SW(3 downto 0) = "0011" else  --  3 MHz phi2 / phi0 12 MHz  120/12 = 10.000 exact
						x"0780" when SW(3 downto 0) = "0100" else  --  4 MHz phi2 / phi0 16 MHz  120/16 =  7.500 int=7  frac=128
						x"0600" when SW(3 downto 0) = "0101" else  --  5 MHz phi2 / phi0 20 MHz  120/20 =  6.000 exact
						x"0500" when SW(3 downto 0) = "0110" else  --  6 MHz phi2 / phi0 24 MHz  120/24 =  5.000 exact
						x"0449" when SW(3 downto 0) = "0111" else  --  7 MHz phi2 / phi0 28 MHz  120/28 =  4.286 int=4  frac=73
						x"03C0" when SW(3 downto 0) = "1000" else  --  8 MHz phi2 / phi0 32 MHz  120/32 =  3.750 int=3  frac=192
						x"0355" when SW(3 downto 0) = "1001" else  --  9 MHz phi2 / phi0 36 MHz  120/36 =  3.333 int=3  frac=85
						x"0300" when SW(3 downto 0) = "1010" else  -- 10 MHz phi2 / phi0 40 MHz  120/40 =  3.000 exact
						x"02BA" when SW(3 downto 0) = "1011" else  -- 11 MHz phi2 / phi0 44 MHz  120/44 =  2.727 int=2  frac=186
						x"0280" when SW(3 downto 0) = "1100" else  -- 12 MHz phi2 / phi0 48 MHz  120/48 =  2.500 int=2  frac=128
						x"024F" when SW(3 downto 0) = "1101" else  -- 13 MHz phi2 / phi0 52 MHz  120/52 =  2.308 int=2  frac=79
						x"0225" when SW(3 downto 0) = "1110" else  -- 14 MHz phi2 / phi0 56 MHz  120/56 =  2.143 int=2  frac=37
						x"0200" when SW(3 downto 0) = "1111" else  -- 15 MHz phi2 / phi0 60 MHz  120/60 =  2.000 exact
						x"1E00";                                     -- default: 1 MHz
					
															 
	ap1: Replica1_CORE                generic map(BOARD          =>  BOARD,
																 CPU_TYPE       =>  CPU_TYPE,    -- 6502, 65C02, 6800 or 6809
																 CPU_CORE       =>  CPU_CORE,    -- "65XX", "T65", MX65"
																 ROM            =>  ROM,         -- default wozmon65
																 RAM_SIZE_KB    =>  RAM_SIZE_KB, -- 8 to 48Kb 
																 BAUD_RATE      =>  BAUD_RATE,   -- uart speed 1200 to 115200
																 HAS_ACI        =>  HAS_ACI,     -- add the aci (incomplete)
                                                 HAS_MSPI       =>  HAS_MSPI,    -- add master spi  C200
	                                              HAS_TIMER      =>  HAS_TIMER)   -- add basic timer C210
													 port map(main_clk       =>  main_clk,
																 serial_clk     =>  serial_clk,
																 reset_n        =>  reset_n,
																 cpu_reset_n    =>  cpu_reset_n,
																 bus_phi2       =>  phi2,    
																 bus_address    =>  address_bus,
																 bus_data       =>  data_bus,
																 bus_rw         =>  rw,
																 bus_mrdy       =>  mrdy,
																 ext_ram_cs_n   =>  ram_cs_n,
																 ext_ram_data   =>  ram_data,
																 ext_tram_cs_n  =>  tram_cs_n,
																 ext_tram_data  =>  tram_data,
																 uart_rx        =>  ARDUINO_IO(0),
																 uart_tx        =>  ARDUINO_IO(1),
																 spi_cs         =>  ARDUINO_IO(4),   -- SD Card Data 3          CS
																 spi_sck        =>  ARDUINO_IO(13),  -- SD Card Clock           SCLK
																 spi_mosi       =>  ARDUINO_IO(11),  -- SD Card Command Signal  MOSI
																 spi_miso       =>  ARDUINO_IO(12),  -- SD Card Data            MISO
																 tape_out       =>  ARDUINO_IO(3),
																 tape_in        =>  ARDUINO_IO(2));


gen_ebr_ram: if USE_EBR_RAM = true generate
	ram: EBR_RAM                      generic map(RAM_SIZE_KB     => RAM_SIZE_KB)
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
                                                 CACHE_SIZE_BYTES => CACHE_SIZE_BYTES, 
                                                 LINE_SIZE_BYTES  => LINE_SIZE_BYTES,  
																 RAM_BLOCK_TYPE   => RAM_BLOCK_TYPE)  
													 port map(sdram_clk        => sdram_clk,
													          E                => phi2,
																 reset_n          => reset_n,
																 -- SRAM interface 
																 sram_ce_n        => tram_cs_n,
																 sram_we_n        => rw,
																 sram_oe_n        => not rw,
																 sram_addr        => address_bus(ADDR_BITS - 1 downto 0),
																 sram_din         => data_bus,
																 sram_dout        => tram_data,
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
																 refresh_req      => refresh_req,
                                                 cache_hitp       => cache_hit);

    -- SDRAM Controller Instance
    sdram_inst : sdram_controller   generic map (FREQ_MHZ           => SDRAM_MHZ,
																 ROW_BITS           => ROW_BITS, 
												             COL_BITS           => COL_BITS,
                                                 TRP_NS             => TRP_NS,
                                                 TRCD_NS            => TRCD_NS,
                                                 TRFC_NS            => TRFC_NS,
                                                 CAS_LATENCY        => CAS_LATENCY,
                                                 USE_AUTO_PRECHARGE => AUTO_PRECHARGE,
                                                 USE_AUTO_REFRESH   => AUTO_REFRESH)
													port map (clk                => sdram_clk,
																 reset_n            => reset_n,
																 req                => sdram_req,
																 wr_n               => sdram_wr_n,
																 addr               => std_logic_vector(resize(unsigned(sdram_addr), SDRAM_ADDR_WIDTH)),
																 din                => sdram_din,
																 dout               => sdram_dout,
																 byte_en            => sdram_byte_en,
																 ready              => sdram_ready,
																 ack                => sdram_ack,
																 refresh_req        => refresh_req,
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
																

	
	VGA_B		   	<= (others => 'Z');
	VGA_G	   		<= (others => 'Z'); 
	VGA_HS	   	<= 'Z';
	VGA_R		   	<= (others => 'Z');  
	VGA_VS	   	<= 'Z';
		
	GSENSOR_CS_N	<= 'Z';
	GSENSOR_SCLK	<= 'Z';
	GSENSOR_SDI		<= 'Z';
	GSENSOR_SDO	 	<= 'Z';


	
end top;

