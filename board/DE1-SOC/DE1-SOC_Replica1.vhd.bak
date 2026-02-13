--------------------------------------------------------------------------
-- To configure the machine search "Board Configuration Parameters"
-- and adapt the configuration to your needs 
--------------------------------------------------------------------------


library IEEE;
	use IEEE.std_logic_1164.all;
   use ieee.numeric_std.all; 
	
entity DE10_Replica1 is
  port (
		ADC_CLK_10      :	in	   std_logic;
	
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
		DRAM_RAS_N      :	out	   std_logic;
		DRAM_UDQM       :	out    std_logic;
		DRAM_WE_N       :	out	   std_logic;

		HEX0			:	out    std_logic_vector(7 downto 0);
		HEX1			:	out    std_logic_vector(7 downto 0);
		HEX2			:	out    std_logic_vector(7 downto 0);
		HEX3			:	out    std_logic_vector(7 downto 0);
		HEX4			:	out    std_logic_vector(7 downto 0);
		HEX5			:	out    std_logic_vector(7 downto 0);

		KEY				:	in	   std_logic_vector(1 downto 0);

		LEDR			:	out	   std_logic_vector(9 downto 0);

		SW				:	in	   std_logic_vector(9 downto 0);
		
		VGA_B			:	out	   std_logic_vector(3 downto 0);
		VGA_G			:	out    std_logic_vector(3 downto 0);
		VGA_HS			:	out	   std_logic;
		VGA_R			:   out	   std_logic_vector(3 downto 0);
		VGA_VS			:	out	   std_logic;
		
		GSENSOR_CS_N	:	out	   std_logic;
		GSENSOR_INT		:	in	   std_logic_vector(2 downto 1);
		GSENSOR_SCLK	:   out    std_logic;
		GSENSOR_SDI		:	inout  std_logic;
		GSENSOR_SDO	 	:	inout  std_logic;

		ARDUINO_IO		 : inout  std_logic_vector(15 downto 0);
		ARDUINO_RESET_N : inout  std_logic;

		GPIO            :	inout  std_logic_vector(35 downto 0)
  );
end entity;	

architecture top of DE10_Replica1 is

component hexto7seg is
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

component clock_divider is
    generic (divider : integer := 4);
    port (
        reset    : in  std_logic := '1';
        clk_in   : in  std_logic;
        clk_out  : out std_logic
    );
end component;

component clock_stretcher is
    generic (
        DIVIDER : integer := 4  -- Clock divider (4 = input/4)
    );
    port (
        clk_in         : in  std_logic;  -- Fast input clock (e.g., 8MHz)
        reset_n        : in  std_logic;  -- Active high reset
        mrdy           : in  std_logic;  -- Memory ready (1=ready, 0=stretch)
		  stretch_active : out std_logic;
        clk_out        : out std_logic   -- Stretched output clock (e.g., 2MHz)
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
	
component RAM_DE10 is
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
        sdram_addr  : out   std_logic_vector(12 downto 0);
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
        LINE_SIZE_BYTES  : integer := 16     -- 16-byte cache lines
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
constant BOARD          : string   := "DE10_Lite";
constant CPU_TYPE       : string   := "6502";   -- 6502, 65C02, 6800, 6809
constant CPU_CORE       : string   := "MX65";   -- 65XX or T65 or MX65
constant ROM            : string   := "WOZMON65";
constant RAM_SIZE_KB    : positive := 48;       -- DE10-Lite supports up to 48KB
constant BAUD_RATE      : integer  := 115200;
constant HAS_ACI        : boolean  := false;
constant HAS_MSPI       : boolean  := false;
constant HAS_TIMER      : boolean  := false;

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
signal strch           : std_logic;
signal bshit           : std_logic;

signal refresh_reg     : std_logic;
signal ready_reg       : std_logic;
signal ack_reg         : std_logic;
signal req_reg         : std_logic;
signal wr_reg          : std_logic;
signal la_state        : std_logic_vector(1 downto 0);
	
	
-- remove after use
signal strch_flag      : std_logic;
signal phi2_old        : std_logic;
signal phi2_new        : std_logic;
signal pulse_trigger : std_logic;
signal pulse_count : integer range 0 to 10 := 0;
signal mrdy_test : std_logic;
signal e    : std_logic;
signal q    : std_logic;
signal xx   : std_logic;
signal debug : std_logic_vector(2 downto 0);

signal clk_ticks     : std_logic := '0';
signal debug_state   : std_logic_vector(3 downto 0);
signal debug_cmd     : std_logic_vector(3 downto 0);
signal debug_addr_10 : std_logic;
signal debug_addr_9  : std_logic;
signal debug_addr_0  : std_logic;
signal debug_dqm     : std_logic_vector(1 downto 0);
signal debug_dq_0    : std_logic;

signal cache_hit      : unsigned(6 downto 0);  -- 0 to 100%
signal cache_hit_tens : unsigned(3 downto 0);  -- 0 à 10
signal cache_hit_ones : unsigned(3 downto 0);  -- 0 à 9	

begin
	-- on the DE10 Lite the 7 seg display show the current address and data 
    
    -- Conversion binaire → BCD
    cache_hit_tens <= resize(cache_hit / 10, 4);
    cache_hit_ones <= resize(cache_hit mod 10, 4);    
    
    h0 : hexto7seg port map (hex => std_logic_vector(cache_hit_ones), seg => HEX0); 
    h1 : hexto7seg port map (hex => std_logic_vector(cache_hit_tens), seg => HEX1);    
    
--	h0 : hexto7seg port map  (hex => data_bus(3  downto 0),     seg => HEX0); 
--	h1 : hexto7seg port map  (hex => data_bus(7  downto 4),     seg => HEX1); 

	h2 : hexto7seg port map  (hex => address_bus(3 downto 0),   seg => HEX2); 
	h3 : hexto7seg port map  (hex => address_bus(7 downto 4),   seg => HEX3); 
	h4 : hexto7seg port map  (hex => address_bus(11 downto 8),  seg => HEX4); 
	h5 : hexto7seg port map  (hex => address_bus(15 downto 12), seg => HEX5); 

	-- reset_n is mapped to KEY 0 of the DE10 Lite
	-- reset_n is used to reset low level layers of the fpga modules
	reset_n <= KEY(0);
	
	
	-- cpu_reset_n can only go high if reset_n is high and the PLL locked
	-- cpu_reset_n only reset the cpu and the peripherals
	cpu_reset_n <= '1' when reset_n = '1' and main_locked = '1' else '0';
	
	-- MAIN clock  note on 6502 core main clock is at least twice phi2
	mclk: main_clock                port map(areset		     => not reset_n,
		                                      inclk0		     => MAX10_CLK1_50,
		                                      c0	  	        => clock_30mhz,
		                                      c1	  	        => open,
														  c2             => clock_sdram,
		                                      locked	  	     => main_locked);
														  

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
			
   --main_clk <= clock_30mhz;															
	
	-- UART baud rate clock  1.8432Mhz base serial clock
	uclk: fractional_clock_divider   generic map(CLK_FREQ_HZ    => 50_000_000,
										 	     FREQUENCY_HZ   => 1_843_200)
	 									port map(clk_in         => MAX10_CLK1_50,
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
												 bus_phi1       =>  phi1,    
												 bus_address    =>  address_bus,
												 bus_data       =>  data_bus,
												 bus_rw         =>  rw,
												 bus_mrdy       =>  mrdy,
												 bus_strch      =>  strch,
												 bus_bshit      =>  bshit,
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
												 tape_in        =>  ARDUINO_IO(2),
												 la_state       =>  la_state);


de10_gen_ram: if BOARD = "DE10_Lite" generate
	ram: RAM_DE10                    generic map(RAM_SIZE_KB     => RAM_SIZE_KB)
								        port map(clock           => phi2,
					   	                         cs_n            => ram_cs_n,
										         we_n            => rw,
										         address         => address_bus,
										         data_in         => data_bus,
							                     data_out        => ram_data);
end generate de10_gen_ram;																



    bridge_inst : sram_sdram_bridge  generic map(ADDR_BITS        => 12,
	                                             SDRAM_MHZ        => 75,
                                                 GENERATE_REFRESH => true,
                                                 USE_CACHE        => true,
                                                 -- Cache parameters
                                                 CACHE_SIZE_BYTES => 1024,  -- 1KB cache
                                                 LINE_SIZE_BYTES  => 16)    -- 16-byte cache lines
									    port map(sdram_clk        => clock_sdram,
										      	 E                => phi2,
												 reset_n          => reset_n,
												 -- SRAM interface (test side)
												 sram_ce_n        => tram_cs_n,
												 sram_we_n        => rw,
												 sram_oe_n        => not rw,
												 sram_addr        => address_bus(11 downto 0),
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
												 debug            => debug);

    -- SDRAM Controller Instance
    sdram_inst : sdram_controller   generic map (FREQ_MHZ           => 75,
									 			 ROW_BITS           => 13, 
												 COL_BITS           => 10,
                                                 USE_AUTO_PRECHARGE => false,
                                                 USE_AUTO_REFRESH   => false)
									   port map (clk                => clock_sdram,
												 reset_n            => reset_n,
												 req                => sdram_req,
												 wr_n               => sdram_wr_n,
												 addr               => (24 downto 11 => '0') & sdram_addr,
												 din                => sdram_din,
												 dout               => sdram_dout,
												 byte_en            => sdram_byte_en,
												 ready              => sdram_ready,
												 ack                => sdram_ack,
												 debug_state        => debug_state,
												 debug_cmd          => debug_cmd,
				 				 --		  		 debug_seq          => display(15 downto 0),
                                                 debug_addr_10      => debug_addr_10,
                                                 debug_addr_9       => debug_addr_9,
                                                 debug_addr_0       => debug_addr_0,
                                                 debug_dqm          => debug_dqm,
                                                 debug_dq_0         => debug_dq_0,
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
																

																
process(clock_sdram, reset_n) 
begin
    if reset_n = '0' then
        clk_ticks <= '0';
	elsif rising_edge(clock_sdram) then
		req_reg     <= sdram_req;
		ack_reg     <= sdram_ack;
		ready_reg   <= sdram_ready;
		wr_reg      <= sdram_wr_n;
		refresh_reg <= refresh_busy;
        clk_ticks     <= not clk_ticks;
	end if;
end process;


-- trigger 																
GPIO(0)            <= sdram_wr_n;
GPIO(1)            <= clk_ticks;   -- 1 edge by clock tick
-- CMD 
GPIO(5 downto 2)   <= debug_state;
GPIO(9 downto 6)   <= debug_cmd;
-- A9 for MODE LOAD
GPIO(10)           <= debug_addr_9;
-- A10
GPIO(11)           <= debug_addr_10;
GPIO(13 downto 12) <= debug_dqm;
-- specific
GPIO(14)           <= debug_addr_0;  
GPIO(15)           <= debug_dq_0;  
-- external clock
GPIO(16)           <= clock_sdram;


--=== SRAM TO SDRAM BRIDGE DEBUG ====
---- test state												 
--GPIO(0)          <= sdram_addr(0); ---   main_clk; 
--GPIO(1)          <= ram_addr(0); --strch; 
---- 6502 signals
--GPIO(2)          <= mrdy;     
--GPIO(3)          <= phi2; 
---- sram signals
--GPIO(4)          <= tram_cs_n;   
--GPIO(5)          <= rw when tram_cs_n = '0' else '1';
--GPIO(6)          <= address_bus(1);-- when tram_cs_n = '0' else '0';
---- bridge state
----GPIO(9 downto 7) <= debug;
---- sdram signals
--GPIO(10)         <= req_reg;
--GPIO(11)         <= ack_reg;
--GPIO(12)         <= wr_reg;     
--GPIO(13)         <= ready_reg;  
--GPIO(14)         <= refresh_reg;
--GPIO(15)         <= '0' when (address_bus(0) = '0' and sdram_byte_en = "01" and tram_cs_n = '0') or (address_bus(0) = '1' and sdram_byte_en = "10" and tram_cs_n = '0') else '1';


	 
--	DRAM_ADDR      <= (others => 'Z');
--	DRAM_BA        <= (others => 'Z');
--	DRAM_CAS_N     <= 'Z';  
--	DRAM_CKE       <= 'Z';  
--	DRAM_CLK       <= 'Z';  
--	DRAM_CS_N      <= 'Z';  
--	DRAM_DQ        <= (others => 'Z');  
--	DRAM_LDQM      <= 'Z';  
--	DRAM_RAS_N     <= 'Z';  
--	DRAM_UDQM      <= 'Z';  
--	DRAM_WE_N      <= 'Z';  
	
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

