--------------------------------------------------------------------------
-- AX4010 Replica1 Top Level
-- Board: Alinx AX4010 - Cyclone IV E EP4CE10F17C8
-- SDRAM: Hynix H57V2562GTR (256Mbit = 32MB, 16Mx16, ROW=12, COL=8)
--------------------------------------------------------------------------
-- To configure the machine search "Board Configuration Parameters"
-- and adapt the configuration to your needs 
--------------------------------------------------------------------------

library IEEE;
    use IEEE.std_logic_1164.all;
    use ieee.numeric_std.all; 
   
entity AX4010_Replica1 is
    port (
        --------- CLOCK ---------
        clk              : in    std_logic;  -- 50MHz

        --------- RESET & KEYS ---------
        rst_n            : in    std_logic;
        key2             : in    std_logic;
        key3             : in    std_logic;
        key4             : in    std_logic;

        --------- LEDs ---------
        led              : out   std_logic_vector(3 downto 0);

        --------- 7-SEGMENT DISPLAY ---------
        seg_data         : out   std_logic_vector(7 downto 0);
        seg_sel          : out   std_logic_vector(5 downto 0);

        --------- SDRAM ---------
        sdram_addr       : out   std_logic_vector(12 downto 0);
        sdram_ba         : out   std_logic_vector(1 downto 0);
        sdram_cas_n      : out   std_logic;
        sdram_cke        : out   std_logic;
        sdram_clk        : out   std_logic;
        sdram_cs_n       : out   std_logic;
        sdram_dq         : inout std_logic_vector(15 downto 0);
        sdram_dqm        : out   std_logic_vector(1 downto 0);
        sdram_ras_n      : out   std_logic;
        sdram_we_n       : out   std_logic;

        --------- UART ---------
        uart_tx          : out   std_logic;
        uart_rx          : in    std_logic;

        --------- VGA ---------
        vga_out_r        : out   std_logic_vector(4 downto 0);
        vga_out_g        : out   std_logic_vector(5 downto 0);
        vga_out_b        : out   std_logic_vector(4 downto 0);
        vga_out_hs       : out   std_logic;
        vga_out_vs       : out   std_logic;

        --------- SD CARD ---------
        SD_DCLK          : out   std_logic;
        SD_MISO          : in    std_logic;
        SD_MOSI          : out   std_logic;
        SD_nCS           : out   std_logic;

        --------- SPI FLASH ---------
        dclk             : out   std_logic;
        miso             : in    std_logic;
        mosi             : out   std_logic;
        ncs              : out   std_logic;

        --------- I2C EEPROM ---------
        i2c_scl          : inout std_logic;
        i2c_sda          : inout std_logic;

        --------- RTC DS1302 ---------
        rtc_sclk         : out   std_logic;
        rtc_data         : inout std_logic;
        rtc_ce           : out   std_logic;

        --------- BUZZER ---------
        buzzer           : out   std_logic
    );
end entity AX4010_Replica1;

architecture top of AX4010_Replica1 is

component mux7seg is
    port (
        clk        : in  std_logic;
        reset_n    : in  std_logic;
        seg_sel    : out std_logic_vector(5 downto 0);  -- Digit select (active low)
        seg_data   : out std_logic_vector(7 downto 0);  -- Segment data (MSB = decimal point)
        display    : in  std_logic_vector(23 downto 0)
    );
end component;

component main_clock is
    port (
        areset        : in  std_logic  := '0';
        inclk0        : in  std_logic  := '0';
        c0            : out std_logic;
        c1            : out std_logic;
        c2            : out std_logic;
        locked        : out std_logic 
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
        RAM_SIZE_KB : integer := 32
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
        CPU_TYPE        : string   :=  "6502";    -- 6502, 65C02, 6800 or 6809
        CPU_CORE        : string   :=  "65XX";    -- 65XX, T65, MX65 
        ROM             : string   := "WOZMON65"; -- default monitor
        RAM_SIZE_KB     : positive := 8;          -- 8kb to 48kb
        BAUD_RATE       : integer  := 9600;       -- uart speed 1200 to 115200
        HAS_ACI         : boolean  := false;      -- add the aci (incomplete)
        HAS_MSPI        : boolean  := false;      -- add master spi  C200
        HAS_TIMER       : boolean  := false       -- add basic timer
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
        TRP_NS             : integer := 20;   -- Precharge time (for PRECHARGE wait)
        TRCD_NS            : integer := 20;   -- RAS to CAS delay (for ACTIVE→READ/WRITE)
        TRFC_NS            : integer := 70;   -- Refresh cycle time (for AUTO REFRESH wait)
        CAS_LATENCY        : integer := 2;    -- CAS Latency: 2 or 3 cycles
        USE_AUTO_PRECHARGE : boolean := true;  -- true = READA/WRITEA false = READ/WRITE
        USE_AUTO_REFRESH   : boolean := true   -- true = autorefresh, false = triggered refresh
    );
    port(
        clk            : in    std_logic;  -- 20MHz
        reset_n        : in    std_logic;  -- Active high
        
        -- Simple CPU interface
        req            : in    std_logic;
        wr_n           : in    std_logic;  -- 1=write, 0=read
        addr           : in    std_logic_vector(ROW_BITS+COL_BITS+1 downto 0); 
        din            : in    std_logic_vector(15 downto 0);
        dout           : out   std_logic_vector(15 downto 0);
        byte_en        : in    std_logic_vector(1 downto 0);  -- Active low (not used yet, always "00")
        ready          : out   std_logic;
        ack            : out   std_logic;
        refresh_req    : in  std_logic;  
        refresh_active : out   std_logic;  -- High during refresh
        
        -- SDRAM pins
        sdram_clk      : out   std_logic;
        sdram_cke      : out   std_logic;
        sdram_cs_n     : out   std_logic;
        sdram_ras_n    : out   std_logic;
        sdram_cas_n    : out   std_logic;
        sdram_we_n     : out   std_logic;
        sdram_ba       : out   std_logic_vector(1 downto 0);
        sdram_addr     : out   std_logic_vector(ROW_BITS-1 downto 0);
        sdram_dq       : inout std_logic_vector(15 downto 0);
        sdram_dqm      : out   std_logic_vector(1 downto 0)
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
        refresh_req   : out std_logic;
        cache_hitp    : out unsigned(6 downto 0)  -- 0 to 100%
    );
end component;

--------------------------------------------------------------------------
-- Board Configuration Parameters 
--------------------------------------------------------------------------
constant CPU_TYPE         : string   := "6502";
constant CPU_CORE         : string   := "MX65";
constant ROM              : string   := "WOZMON65";
constant RAM_SIZE_KB      : positive := 32;                       -- AX4010: max 32KB (limited by 10K LEs)
constant BAUD_RATE        : integer  := 115200;
constant HAS_ACI          : boolean  := false;
constant HAS_MSPI         : boolean  := false;
constant HAS_TIMER        : boolean  := false;
constant USE_EBR_RAM      : boolean  := true;
constant SDRAM_MHZ        : integer  := 120;                      -- 100MHz SDRAM clock
constant ROW_BITS         : integer  := 13;                       -- H57V2562GTR: 13 row bits
constant COL_BITS         : integer  := 9;                        -- H57V2562GTR: 9 col bits
constant TRP_NS           : integer  := 20;                       -- Precharge time (for PRECHARGE wait)
constant TRCD_NS          : integer  := 20;                       -- RAS to CAS delay (for ACTIVE→READ/WRITE)
constant TRFC_NS          : integer  := 70;                       -- Refresh cycle time (for AUTO REFRESH wait)
constant CAS_LATENCY      : integer  := 2;                        -- CAS Latency: 2 or 3 cycles
constant ADDR_BITS        : integer  := 12;                       -- 4KB test window
constant AUTO_PRECHARGE   : boolean  := false;
constant AUTO_REFRESH     : boolean  := true;
constant CACHE_DATA       : boolean  := false;                    -- WARNING: Cache uses LUTs on this small FPGA!
constant CACHE_SIZE_BYTES : integer  := 512;                      -- Small cache (512B) to save resources
constant LINE_SIZE_BYTES  : integer  := 16;
constant SDRAM_ADDR_WIDTH : integer  := ROW_BITS + COL_BITS + 2;
constant RAM_BLOCK_TYPE   : string   := "M9K";


signal  address_bus    : std_logic_vector(15 downto 0);
signal  data_bus       : std_logic_vector(7 downto 0);
signal  ram_data       : std_logic_vector(7 downto 0);
signal  tram_data      : std_logic_vector(7 downto 0);
signal  ram_cs_n       : std_logic;
signal  tram_cs_n      : std_logic;
signal  reset_n        : std_logic;
signal  cpu_reset_n    : std_logic;
signal  main_ck        : std_logic;
signal  sdram_ck       : std_logic;
signal  disp_ck        : std_logic;
signal  serial_ck      : std_logic;
signal  pll_locked     : std_logic;
signal  phi2           : std_logic;
signal  rw             : std_logic;
signal  mrdy           : std_logic;
signal  serial_rx      : std_logic;
signal  serial_tx      : std_logic;

-- SDRAM Controller Interface
signal sdram_req       : std_logic;
signal sdram_wr_n      : std_logic;
signal sdram_addr_int  : std_logic_vector(10 downto 0);
signal sdram_din       : std_logic_vector(15 downto 0);
signal sdram_dout      : std_logic_vector(15 downto 0);
signal sdram_byte_en   : std_logic_vector(1 downto 0);
signal sdram_ready     : std_logic;
signal sdram_ack       : std_logic;
signal refresh_busy    : std_logic;
signal refresh_req     : std_logic;

signal cache_hit       : unsigned(6 downto 0);
signal cache_hit_tens  : unsigned(3 downto 0);
signal cache_hit_ones  : unsigned(3 downto 0);

signal display         : std_logic_vector(23 downto 0);

begin

    -- 7-segment display: show cache hit rate
    cache_hit_tens <= resize(cache_hit / 10, 4);
    cache_hit_ones <= resize(cache_hit mod 10, 4);
    

    display <= address_bus & data_bus                                                          when key2 = '1' else
               x"0000" & std_logic_vector(cache_hit_tens) & std_logic_vector(cache_hit_ones);         
    
    sevenseg: mux7seg                  port map(clk       => disp_ck,
                                                reset_n   => reset_n,
                                                seg_sel   => seg_sel,
                                                seg_data  => seg_data,
                                                display   => display);

                                                
    sclk: clock_divider             generic map(divider   => 50_000_000 / 10_000)
                                       port map(clk_in    => clk, 
                                                reset     => reset_n, 
                                                clk_out   => disp_ck);
                                                
    -- Reset management
    reset_n <= rst_n;
    cpu_reset_n <= '1' when reset_n = '1' and pll_locked = '1' else '0';

    -- Main PLL: generate clocks
    mclk: main_clock                   port map(areset    => not reset_n,
                                                inclk0    => clk,
                                                c0        => main_ck,
                                                c1        => open,
                                                c2        => sdram_ck,
                                                locked    => pll_locked);

    -- UART baud rate clock
    uclk: fractional_clock_divider  generic map(CLK_FREQ_HZ => 50_000_000, 
                                                FREQUENCY_HZ => 1_843_200)
                                       port map(clk_in => clk, 
                                                reset_n => reset_n, 
                                                clk_out => serial_ck);

        

    ap1: Replica1_CORE              generic map(CPU_TYPE       =>  CPU_TYPE,    -- 6502, 65C02, 6800 or 6809
                                                CPU_CORE       =>  CPU_CORE,    -- "65XX", "T65", MX65"
                                                ROM            =>  ROM,         -- default wozmon65
                                                RAM_SIZE_KB    =>  RAM_SIZE_KB, -- 8 to 48Kb 
                                                BAUD_RATE      =>  BAUD_RATE,   -- uart speed 1200 to 115200
                                                HAS_ACI        =>  HAS_ACI,     -- add the aci (incomplete)
                                                HAS_MSPI       =>  HAS_MSPI,    -- add master spi  C200
                                                HAS_TIMER      =>  HAS_TIMER)   -- add basic timer C210
                                       port map(main_clk       =>  main_ck,
                                                serial_clk     =>  serial_ck,
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
                                                uart_rx        =>  uart_rx,
                                                uart_tx        =>  uart_tx,
                                                spi_cs         =>  SD_nCS, 
                                                spi_sck        =>  SD_DCLK, 
                                                spi_mosi       =>  SD_MOSI, 
                                                spi_miso       =>  SD_MISO, 
                                                tape_out       =>  open,
                                                tape_in        =>  '1');
        

gen_ebr_ram: if USE_EBR_RAM = true generate
    ram: EBR_RAM                    generic map(RAM_SIZE_KB     => RAM_SIZE_KB)
                                       port map(clock           => phi2,
                                                cs_n            => ram_cs_n,
                                                we_n            => rw,
                                                address         => address_bus,
                                                data_in         => data_bus,
                                                data_out        => ram_data);
end generate gen_ebr_ram;

    bridge : sram_sdram_bridge      generic map(ADDR_BITS        => ADDR_BITS,
                                                SDRAM_MHZ        => SDRAM_MHZ,
                                                GENERATE_REFRESH => not AUTO_REFRESH,
                                                USE_CACHE        => CACHE_DATA,
                                                -- Cache parameters
                                                CACHE_SIZE_BYTES => CACHE_SIZE_BYTES,
                                                LINE_SIZE_BYTES  => LINE_SIZE_BYTES,
                                                RAM_BLOCK_TYPE   => RAM_BLOCK_TYPE)
                                       port map(sdram_clk        => sdram_ck,
                                                E                => phi2,
                                                reset_n          => reset_n,
                                                -- SRAM interface (test side)
                                                sram_ce_n        => tram_cs_n,
                                                sram_we_n        => rw,
                                                sram_oe_n        => not rw,
                                                sram_addr        => address_bus(ADDR_BITS -1  downto 0),
                                                sram_din         => data_bus,
                                                sram_dout        => tram_data,
                                                mrdy             => mrdy,

                                                -- SDRAM controller interface
                                                sdram_req        => sdram_req,
                                                sdram_wr_n       => sdram_wr_n,
                                                sdram_addr       => sdram_addr_int,
                                                sdram_din        => sdram_din,
                                                sdram_dout       => sdram_dout,
                                                sdram_byte_en    => sdram_byte_en,
                                                sdram_ready      => sdram_ready,
                                                sdram_ack        => sdram_ack,
                                                refresh_req      => refresh_req,
                                                cache_hitp       => cache_hit);

                                             
    -- SDRAM Controller Instance
    sdram : sdram_controller        generic map(FREQ_MHZ           => SDRAM_MHZ,
                                                ROW_BITS           => ROW_BITS, 
                                                COL_BITS           => COL_BITS,
                                                TRP_NS             => TRP_NS,
                                                TRCD_NS            => TRCD_NS,
                                                TRFC_NS            => TRFC_NS,
                                                CAS_LATENCY        => CAS_LATENCY,
                                                USE_AUTO_PRECHARGE => AUTO_PRECHARGE,
                                                USE_AUTO_REFRESH   => AUTO_REFRESH)
                                      port map (clk                => sdram_ck,
                                                reset_n            => reset_n,
                                                req                => sdram_req,
                                                wr_n               => sdram_wr_n,
                                                addr               => std_logic_vector(resize(unsigned(sdram_addr_int), SDRAM_ADDR_WIDTH)), 
                                                din                => sdram_din,
                                                dout               => sdram_dout,
                                                byte_en            => sdram_byte_en,
                                                ready              => sdram_ready,
                                                ack                => sdram_ack,
                                                refresh_req        => refresh_req,
                                                refresh_active     => refresh_busy,
                                                sdram_clk          => sdram_clk,
                                                sdram_cke          => sdram_cke,
                                                sdram_cs_n         => sdram_cs_n,
                                                sdram_ras_n        => sdram_ras_n,
                                                sdram_cas_n        => sdram_cas_n,
                                                sdram_we_n         => sdram_we_n,
                                                sdram_ba           => sdram_ba,
                                                sdram_addr         => sdram_addr,
                                                sdram_dq           => sdram_dq,
                                                sdram_dqm          => sdram_dqm);

    -- LEDs
    led(0) <= refresh_busy;
    led(1) <= '0';
    led(2) <= '0';
    led(3) <= pll_locked;

    -- VGA: not used yet (for future TVI925 terminal)
    vga_out_r  <= (others => '0');
    vga_out_g  <= (others => '0');
    vga_out_b  <= (others => '0');
    vga_out_hs <= '0';
    vga_out_vs <= '0';

    -- Unused peripherals
    dclk       <= '0';
    mosi       <= '0';
    ncs        <= '1';
    buzzer     <= '1';
    rtc_sclk   <= '0';
    rtc_ce     <= '0';
    

end top;
