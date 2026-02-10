-- Simple SDRAM Controller Template for Logic Analyzer Debug
-- 100MHz operation for IS42S16320F
-- Write your own logic from here!

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity sdram_controller is
    generic (
        FREQ_MHZ           : integer := 100; -- Clock frequency in MHz
        ROW_BITS           : integer := 13;  -- 13 for DE10-Lite, 12 for DE1
        COL_BITS           : integer := 10;  -- 10 for DE10-Lite, 8 for DE1
        USE_AUTO_PRECHARGE : boolean := true  -- true = READA/WRITEA false = READ/WRITE
    );
    port(
        clk         : in    std_logic;  -- 20MHz
        reset_n     : in    std_logic;  -- Active low
        
        -- Simple CPU interface
        req         : in    std_logic;
        wr_n        : in    std_logic;  -- 0=write, 1=read
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
end sdram_controller;

architecture rtl of sdram_controller is

    -- SDRAM Commands
    -- CS_N  RAS_N  CAS_N  WE_N  | Command               | Notes
    -- -------------------------------------------------------------------------
    --  1     x      x      x    | DESELECT (DESL)       | Chip deselected
    --  0     1      1      1    | NOP                   | No operation
    --  0     1      1      0    | BURST STOP (BST)      | Terminate burst read/write
	--  0     1      0      1    | READ                  | A10=0: normal, A10=1: auto-precharge
  	--  0     1      0      0    | WRITE                 | A10=0: normal, A10=1: auto-precharge
	--  0     0      1      1    | BANK ACTIVATE (ACT)   | Open row, BA1:0 selects bank
	--  0     0      1      0    | PRECHARGE (PRE/PALL)  | A10=0: selected bank, A10=1: all banks
	--  0     0      0      1    | AUTO REFRESH (REF)    | CKE stays high
	--  0     0      0      1    | SELF REFRESH (SELF)   | CKE: H→L (entry), L→H (exit)
	--  0     0      0      0    | MODE REGISTER SET     | BA="00" for standard mode register
	 
	constant CMD_DESL          : std_logic_vector(3 downto 0) := "1111";  -- Device Deselect (CS=H)
	constant CMD_NOP           : std_logic_vector(3 downto 0) := "0111";  -- No Operation
    constant CMD_BST           : std_logic_vector(3 downto 0) := "0110";  -- Burst Stop
    constant CMD_READ          : std_logic_vector(3 downto 0) := "0101";  -- Read (A10=L for normal, A10=H for auto-precharge)
    constant CMD_WRITE         : std_logic_vector(3 downto 0) := "0100";  -- Write (A10=L for normal, A10=H for auto-precharge)
    constant CMD_ACT           : std_logic_vector(3 downto 0) := "0011";  -- Bank Activate
    constant CMD_PRE           : std_logic_vector(3 downto 0) := "0010";  -- Precharge (A10=L for selected bank, A10=H for all banks)
    constant CMD_REF           : std_logic_vector(3 downto 0) := "0001";  -- CBR Auto-Refresh
    constant CMD_SELF          : std_logic_vector(3 downto 0) := "0001";  -- Self-Refresh (same as REF, differentiated by CKE transition)
    constant CMD_MRS           : std_logic_vector(3 downto 0) := "0000";  -- Mode Register Set
	 
    -- States (visible on logic analyzer via debug_state)
    constant ST_INIT           : std_logic_vector(3 downto 0) := "0000";
    constant ST_INIT_PRECHARGE : std_logic_vector(3 downto 0) := "0001";
    constant ST_INIT_REFRESH   : std_logic_vector(3 downto 0) := "0010";
    constant ST_INIT_MODE      : std_logic_vector(3 downto 0) := "0011";
    constant ST_IDLE           : std_logic_vector(3 downto 0) := "0100";
    constant ST_REFRESH        : std_logic_vector(3 downto 0) := "0101";
    constant ST_ACTIVATE       : std_logic_vector(3 downto 0) := "0110";
    constant ST_READ           : std_logic_vector(3 downto 0) := "0111";
    constant ST_READA          : std_logic_vector(3 downto 0) := "1000";
    constant ST_WRITE          : std_logic_vector(3 downto 0) := "1001";
    constant ST_WRITEA         : std_logic_vector(3 downto 0) := "1010";
    constant ST_PRECHARGE      : std_logic_vector(3 downto 0) := "1011";
	 
	 -- SDRAM timing parameters (in nanoseconds)
	constant TRP_NS            : integer := 20;   -- Precharge time (for PRECHARGE wait)
	constant TRCD_NS           : integer := 20;   -- RAS to CAS delay (for ACTIVE→READ/WRITE)
	constant TRFC_NS           : integer := 70;   -- Refresh cycle time (for AUTO REFRESH wait)
    
	 -- Calculated cycles:
	constant TRP_CYCLES        : integer := ((TRP_NS * FREQ_MHZ) + 999) / 1000;
	constant TRCD_CYCLES       : integer := ((TRCD_NS * FREQ_MHZ) + 999) / 1000;
	constant TRFC_CYCLES       : integer := ((TRFC_NS * FREQ_MHZ) + 999) / 1000;  -- Use THIS for AUTO REFRESH!
	constant TMRD_CYCLES       : integer := 2;  -- Mode register delay (2 cycles fixed)
	constant TWR_CYCLES        : integer := 2;  -- Write recovery time
    
    constant CAS_LATENCY       : integer := 2;  -- Or 2, depending on your SDRAM
	 
	constant MODE_REG          : std_logic_vector(12 downto 0) := "000" & "1" & "00" & "010" & "0" & "000";

	 -- ISSI datatasheet at least 100µs delay 
	 -- before issing a command other than NOP or INHIBIT
    constant INIT_WAIT         : integer := FREQ_MHZ * 200;      -- 200µs
	constant REFRESH_INTERVAL  : integer := (FREQ_MHZ * 78) / 10; -- 7.8µs

    signal state               : std_logic_vector(3 downto 0) := ST_INIT;
    signal state_next          : std_logic_vector(3 downto 0) := ST_INIT;
	signal seq_count           : integer range 0 to INIT_WAIT + 50 := 0;
	signal seq_count_next      : integer range 0 to INIT_WAIT + 50 := 0;
	signal row_active          : std_logic := '0';  -- '1' when a row is open
  	signal row_active_next     : std_logic := '0';  -- '1' when a row is open
    signal need_refresh        : std_logic := '0';  -- '1' when a refresh is needed
    signal need_refresh_next   : std_logic := '0';  -- '1' when a refresh is needed
    signal ack_next            : std_logic := '0';
    signal ready_next          : std_logic := '0';
    signal dout_next           : std_logic_vector(15 downto 0);
    
    signal refresh_counter     : integer range 0 to REFRESH_INTERVAL := 0;
    signal init_done           : std_logic := '0';  -- Flag: initialization complete
    signal init_done_next      : std_logic := '0';  -- Flag: initialization complete
    
    -- Address latches
    signal addr_bank_latched   : std_logic_vector(1 downto 0);
    signal addr_row_latched    : std_logic_vector(ROW_BITS-1 downto 0);
    signal addr_col_latched    : std_logic_vector(COL_BITS-1 downto 0);
    signal byte_en_latched     : std_logic_vector(1 downto 0);
    signal din_latched         : std_logic_vector(15 downto 0);
    signal wr_n_latched        : std_logic;
	 
	signal active_row          : std_logic_vector(ROW_BITS-1 downto 0) := (others => '0');
	signal active_row_next     : std_logic_vector(ROW_BITS-1 downto 0) := (others => '0');
	signal active_bank         : std_logic_vector(1 downto 0) := "00";
	signal active_bank_next    : std_logic_vector(1 downto 0) := "00";
  
    -- Command outputs

    signal cmd_next            : std_logic_vector(3 downto 0) := CMD_NOP;

    -- next values
	signal sdram_cke_next      : std_logic;
    signal sdram_ba_next       : std_logic_vector(1 downto 0);
    signal sdram_addr_next     : std_logic_vector(12 downto 0);
    signal sdram_dqm_next      : std_logic_vector(1 downto 0);
    signal sdram_dq_next       : std_logic_vector(15 downto 0) := (others => 'Z');  -- ADD THIS! Default tri-state;1
	 
	 -- init refresh counter
	 signal refresh_count      : integer range 0 to 15; 
	 signal refresh_count_next : integer range 0 to 15; 
	 

begin

    
    -- Output assignments
    sdram_clk  <= not clk;
    sdram_dq   <= sdram_dq_next when (state = ST_WRITE or state = ST_WRITEA) else (others => 'Z');
    
    process(clk)
    begin
        if rising_edge(clk) then
            if reset_n = '0' then
				sdram_cke  <= '0';
                state      <= ST_INIT;
                seq_count  <= INIT_WAIT;
--                cmd        <= CMD_NOP;
                sdram_cs_n    <= CMD_NOP(3);
                sdram_ras_n   <= CMD_NOP(2);
                sdram_cas_n   <= CMD_NOP(1);
                sdram_we_n    <= CMD_NOP(0);		  
                sdram_ba   <= "00";
                sdram_addr <= (others => '0');
                sdram_dqm  <= "11";
                ready      <= '0';
                ack        <= '0';
                refresh_counter <= 0;
                need_refresh    <= '0';
                init_done       <= '0';
                
            else
                state         <= state_next;
                seq_count     <= seq_count_next;
                row_active    <= row_active_next;
                active_row    <= active_row_next;
                active_bank   <= active_bank_next;
                need_refresh  <= need_refresh_next;
                init_done     <= init_done_next;
                refresh_count <= refresh_count_next;
            
                -- transfer next values to controller
                ack           <= ack_next;
                ready         <= ready_next;
                dout          <= dout_next;
                
                -- transfer next values to sdram pins
                sdram_cke     <= sdram_cke_next;
                sdram_cs_n    <= cmd_next(3);
                sdram_ras_n   <= cmd_next(2);
                sdram_cas_n   <= cmd_next(1);
                sdram_we_n    <= cmd_next(0);		  
                sdram_addr    <= sdram_addr_next;
                sdram_ba      <= sdram_ba_next;
                sdram_dqm     <= sdram_dqm_next;
              --  sdram_dq      <= sdram_dq_next;

                -- transfer next values to debug pins
                debug_state   <= state_next;
                debug_cmd     <= cmd_next;
                debug_addr_0  <= sdram_addr_next(0);  
                debug_addr_9  <= sdram_addr_next(9);  
                debug_addr_10 <= sdram_addr_next(10);  
                debug_dqm     <= sdram_dqm_next;
                debug_dq_0    <= sdram_dq_next(0);
            
                -- Default: clear ack
--                ack_next <= '0';
                
                -- Refresh counter (ONLY after initialization complete)
                if init_done = '1' then
                    if refresh_counter >= REFRESH_INTERVAL then
                        refresh_counter <= 0;
                        need_refresh <= '1';
                    else
                        refresh_counter <= refresh_counter + 1;
                    end if;
                end if;
            end if;
        end if;    
    end process;    

    process(
        -- Current state registers
        state,
        seq_count,
        row_active,
        active_row,
        active_bank,
        need_refresh,
        refresh_count,
        init_done,
        refresh_counter,
        
        -- Latched address/data/control
        addr_bank_latched,
        addr_row_latched,
        addr_col_latched,
        byte_en_latched,
        din_latched,
        wr_n_latched,
        
        -- Current output states (for defaults)
        ack,
        ready,
        dout,
        
        -- External inputs from CPU/system
        req,
        wr_n,
        addr,
        byte_en,
        din,
        
        -- Input from SDRAM
        sdram_dq
    )

    begin    
        state_next <= state;
        seq_count_next <= seq_count;
        cmd_next <= CMD_NOP;
        sdram_addr_next <= (others => '0');
        sdram_ba_next <= "00";
        sdram_dqm_next <= "11";
        sdram_cke_next <= '1';
        sdram_dq_next <= (others => 'Z');
        row_active_next <= row_active;
        active_row_next <= active_row;
        active_bank_next <= active_bank;
        need_refresh_next <= need_refresh;
        refresh_count_next <= refresh_count;
        init_done_next <= init_done;
        ready_next <= '0';
        ack_next <= '0';
        dout_next <= (others => '0');
    
    
        case state is
                   
        --========================================
        -- INITIALIZATION
        --========================================
					  
		-- INIT State
		-- Purpose: Allow SDRAM power and clock to stabilize
		--
		-- Signal Requirements:
		--   CKE    = '1'  --> Clock ENABLED (transitions from '0' to '1' when entering this state)
		--   CMD    = INHIBIT or NOP (CS_N='1' for INHIBIT, or CS_N='0'/RAS_N='1'/CAS_N='1'/WE_N='1' for NOP)
		--   DQM    = '1'  --> Data mask active (datasheet requirement)
		--   ADDR   = (don't care)
		--   BA     = (don't care)
		--
		-- Timing: Wait 100µs minimum WITH CKE='1'
		-- Datasheet: CKE must be LOW initially,  then HIGH for initialization						  
						  
        when ST_INIT =>
            cmd_next            <= CMD_NOP;
            sdram_cke_next <= '1';
            sdram_dqm_next <= "11";
            if seq_count = 0 then
                state_next      <= ST_INIT_PRECHARGE;
                cmd_next        <= CMD_PRE;  -- Issue command on transition
                sdram_addr_next <= (10 => '1', others => '0');  -- Set ALL bits!
                seq_count_next  <= TRP_CYCLES;  -- Now wait
            else
                seq_count_next  <= seq_count - 1;
            end if;					  
                    
        -- INIT_PRECHARGE State
        -- Purpose: Precharge ALL banks to prepare for initialization
        --
        -- Signal Requirements:
        --   CKE    = '1'  --> Clock enabled
        --   CMD    = PRECHARGE (CS_N='0', RAS_N='0', CAS_N='1', WE_N='0')
        --   DQM    = '1'  --> Keep masked
        --   A10    = '1'  --> Precharge ALL banks (critical!)
        --   A9:0   = (don't care)
        --   BA     = (don't care when A10='1')
        --
        -- Timing: Hold command for 1 cycle, then wait tRP (precharge time)

        when ST_INIT_PRECHARGE =>
            cmd_next               <= CMD_NOP;  -- NOP during wait
            if seq_count = 0 then
                state_next         <= ST_INIT_REFRESH;
                cmd_next           <= CMD_REF;  -- Issue first refresh
                refresh_count_next <= 7;  -- 7 more to go
                seq_count_next     <= TRFC_CYCLES;
            else
                seq_count_next <= seq_count - 1;
            end if;					  
                    
        -- INIT_REFRESH State
        -- Purpose: Perform 8 AUTO REFRESH cycles as required by datasheet
        --
        -- Signal Requirements:
        --   CKE    = '1'  --> Clock enabled
        --   CMD    = AUTO REFRESH (CS_N='0', RAS_N='0', CAS_N='0', WE_N='1') for 1 cycle
        --            then CMD = NOP during tRC wait
        --   DQM    = '1'  --> Keep masked during init
        --   ADDR   = (don't care)
        --   BA     = (don't care)
        --
        -- Timing Sequence (per refresh):
        --   Cycle 1:        Issue CMD_REF command
        --   Cycles 2-tRC:   Issue CMD_NOP while waiting for tRC to complete
        --   After tRC:      Either start next refresh or proceed to INIT_MODE
        --
        -- Counter: Repeat 8 times total
        -- Datasheet reference: See timing diagram - commands are single-cycle pulses
        --                      separated by NOP commands during timing delays									 
        when ST_INIT_REFRESH =>
            cmd_next                <= CMD_NOP;  -- NOP during wait
            if seq_count = 0 then
                if refresh_count = 0 then
                    state_next         <= ST_INIT_MODE;
                    cmd_next           <= CMD_MRS;  -- Issue MODE command
                    sdram_ba_next      <= "00";
                    sdram_addr_next    <= MODE_REG;
                    seq_count_next     <= TMRD_CYCLES;
                else
                    cmd_next           <= CMD_REF;  -- Issue next refresh
                    refresh_count_next <= refresh_count - 1;
                    seq_count_next     <= TRFC_CYCLES;
                end if;
            else
                seq_count_next <= seq_count - 1;
            end if;					

        -- INIT_MODE State
        -- Purpose: Configure SDRAM operating parameters
        --
        -- Signal Requirements:
        --   CKE    = '1'  --> Clock enabled
        --   CMD    = LOAD MODE REGISTER (CS_N='0', RAS_N='0', CAS_N='0', WE_N='0')
        --   DQM    = '0' or '1' --> Can unmask now (or keep masked, not critical)
        --   BA     = "00" --> Select standard mode register (not extended)
        --   ADDR   = MODE_REG value
        --
        -- Your MODE_REG = "000" & "1" & "00" & "010" & "0" & "000"
        --   A12:A10 = "000" --> Reserved (must be 000)
        --   A9      = "1"   --> Write Burst Mode = Single Location Access
        --   A8:A7   = "00"  --> Operating Mode = Standard Operation
        --   A6:A4   = "010" --> CAS Latency = 2 cycles
        --   A3      = "0"   --> Burst Type = Sequential
        --   A2:A0   = "000" --> Burst Length = 1 (single word)
        --
        -- Timing: Hold command for 1 cycle, then wait tMRD
                
        when ST_INIT_MODE =>
            if seq_count = 0 then
                state_next     <= ST_IDLE;
                init_done_next <= '1';
                cmd_next       <= CMD_NOP;  -- NOP during wait
            else 
                seq_count_next <= seq_count - 1;
            end if;

	 
        --========================================
        -- IDLE - Wait for request or refresh
        --========================================
        when ST_IDLE =>
            cmd_next       <= CMD_NOP;
            sdram_dqm_next <= "11";
            ready_next     <= '1';
            seq_count_next <= 0;
            
            -- check if we have a request    
            if req = '1' then
                -- Latch address
                addr_bank_latched <= addr(addr'high downto addr'high-1);
                addr_row_latched  <= addr(addr'high-2 downto COL_BITS);
                addr_col_latched  <= addr(COL_BITS-1 downto 0);
                byte_en_latched   <= byte_en;
                wr_n_latched      <= wr_n;
                din_latched       <= din;

                if USE_AUTO_PRECHARGE = true then
                    state_next    <= ST_ACTIVATE;
                    ready_next <= '0';
                else
                    -- Check if accessing same row/bank
                    if row_active = '1' and 
                        active_bank = addr(addr'high downto addr'high-1) and
                        active_row  = addr(addr'high-2 downto COL_BITS) then
                        -- Same row! Go directly to read/write
                        if wr_n = '0' then
                            state_next <= ST_WRITE;
                        else
                            state_next <= ST_READ;
                        end if;
                    else
                        -- Different row, need to activate (precharge first if needed)
                        if row_active = '1' then
                            state_next <= ST_PRECHARGE;
                        else
                            state_next <= ST_ACTIVATE;
                        end if;
                    end if;
                    ready_next <= '0';
               end if;
            -- check if a refresh is needed
            elsif need_refresh = '1' then
                -- Need to precharge first if row is active
                if row_active = '1' then
                    state_next <= ST_PRECHARGE;
                    ready_next <= '0';
                else
                    state_next <= ST_REFRESH;
                    ready_next <= '0';
                end if;
            end if;
            
           
        
        --========================================
        -- REFRESH
        --========================================
        when ST_REFRESH =>
            if seq_count = 0 then
                cmd_next          <= CMD_REF;
                seq_count_next    <= seq_count + 1;
            elsif seq_count = TRFC_CYCLES then
                cmd_next          <= CMD_NOP;
                need_refresh_next <= '0';
                state_next        <= ST_IDLE;
                seq_count_next    <= 0;
            else
                cmd_next          <= CMD_NOP;
                seq_count_next    <= seq_count + 1;
            end if;


        --========================================
        -- PRECHARGE (close current row)
        --========================================
        when ST_PRECHARGE =>
            if seq_count = 0 then
                cmd_next        <= CMD_PRE;
                sdram_addr_next <= (10 => '1', others => '0');  -- Set ALL bits!
                seq_count_next  <= seq_count + 1;
            elsif seq_count = TRP_CYCLES then
                -- according to ISSI datasheet
                -- precharge always retuns to IDLE
                cmd_next        <= CMD_NOP;
                sdram_addr_next <= (others => '0');   -- Clear Address
                row_active_next <= '0';
                state_next      <= ST_IDLE;
                seq_count_next  <= 0;
            else
                cmd_next        <= CMD_NOP;
                seq_count_next  <= seq_count + 1;
            end if;	
        
        --========================================
        -- ACTIVATE ROW
        --========================================
        when ST_ACTIVATE =>
            if seq_count = 0 then
                cmd_next         <= CMD_ACT;
                sdram_ba_next    <= addr_bank_latched;
                sdram_addr_next  <= std_logic_vector(resize(unsigned(addr_row_latched), 13));
                active_row_next  <= addr_row_latched;
                active_bank_next <= addr_bank_latched;
                row_active_next  <= '1';
                seq_count_next   <= seq_count + 1;
            elsif seq_count = TRCD_CYCLES then
                cmd_next         <= CMD_NOP;
                -- Decide read or write AND auto-precharge
                if USE_AUTO_PRECHARGE then
                    if wr_n_latched = '0' then
                        state_next <= ST_WRITEA;
                    else
                        state_next <= ST_READA;
                    end if;
                else
                    if wr_n_latched = '0' then
                        state_next <= ST_WRITE;
                    else
                        state_next <= ST_READ;
                    end if;
                end if;
                seq_count_next <= 0;
            else
                cmd_next         <= CMD_NOP;
                seq_count_next   <= seq_count + 1;
            end if;

        --========================================
        -- READA
        --========================================
        when ST_READA =>
            if seq_count = 0 then
                -- Issue READ command with auto-precharge
                cmd_next                             <= CMD_READ;
                sdram_ba_next                        <= addr_bank_latched;
                sdram_addr_next                      <= (others => '0');
                sdram_addr_next(10)                  <= '1';  -- A10=1, auto-precharge
                sdram_addr_next(COL_BITS-1 downto 0) <= addr_col_latched;
                sdram_dqm_next                       <= not byte_en_latched;
                seq_count_next                       <= seq_count + 1;
            elsif seq_count = CAS_LATENCY + 1 then
                -- Data available (CAS latency = 2)
                cmd_next        <= CMD_NOP;
                dout_next       <= sdram_dq;
                ack_next        <= '1';
                sdram_dqm_next  <= "11";
                row_active_next <= '0';   
                state_next      <= ST_IDLE;
                seq_count_next  <= 0;
            else
                cmd_next        <= CMD_NOP;
                seq_count_next  <= seq_count + 1;
            end if;


        --========================================
        -- READ
        --========================================
        when ST_READ =>
            if seq_count = 0 then
                -- Issue READ command without auto-precharge
                cmd_next                             <= CMD_READ;
                sdram_ba_next                        <= addr_bank_latched;
                sdram_addr_next                      <= (others => '0');
                sdram_addr_next(10)                  <= '0';  -- A10=0, No auto-precharge
                sdram_addr_next(COL_BITS-1 downto 0) <= addr_col_latched;
                sdram_dqm_next                       <= not byte_en_latched;
                seq_count_next                        <= seq_count + 1;
            elsif seq_count = CAS_LATENCY + 1 then
                -- Data available (CAS latency = 2)
                cmd_next       <= CMD_NOP;
                dout_next      <= sdram_dq;
                ack_next       <= '1';
                sdram_dqm_next <= "11";
                state_next     <= ST_IDLE;
                seq_count_next <= 0;
            else
                cmd_next       <= CMD_NOP;
                seq_count_next <= seq_count + 1;
            end if;

        --========================================
        -- WRITEA
        --========================================
        when ST_WRITEA =>
            if seq_count = 0 then
                -- Issue WRITE command with auto-precharge
                cmd_next                             <= CMD_WRITE;
                sdram_ba_next                        <= addr_bank_latched;
                sdram_addr_next                      <= (others => '0');
                sdram_addr_next(10)                  <= '1';  -- A10=1, with auto-precharge
                sdram_addr_next(COL_BITS-1 downto 0) <= addr_col_latched;
                sdram_dqm_next                       <= not byte_en_latched;
                sdram_dq_next                        <= din_latched;
                ack_next                             <= '1';
                seq_count_next                       <= seq_count + 1;
            elsif seq_count = 1 then    
                cmd_next       <= CMD_NOP;
                sdram_dq_next  <= (others => 'Z');  -- Tri-state after write    
                seq_count_next <= seq_count + 1;
            elsif seq_count = TRP_CYCLES then
                cmd_next        <= CMD_NOP;
                sdram_dqm_next  <= "11";
                row_active_next <= '0';  -- Row is closed
                state_next      <= ST_IDLE;
                seq_count_next  <= 0;
            else
                cmd_next        <= CMD_NOP;
                seq_count_next  <= seq_count + 1;
            end if;


        --========================================
        -- WRITE
        --========================================
        when ST_WRITE =>
            if seq_count = 0 then
                -- Issue WRITE command without auto-precharge
                cmd_next                             <= CMD_WRITE;
                sdram_ba_next                        <= addr_bank_latched;
                sdram_addr_next                      <= (others => '0');
                sdram_addr_next(10)                  <= '0';  -- A10=0, NO auto-precharge
                sdram_addr_next(COL_BITS-1 downto 0) <= addr_col_latched;
                sdram_dqm_next                       <= not byte_en_latched;
                sdram_dq_next                        <= din_latched;
                ack_next                             <= '1';
                seq_count_next                       <= seq_count + 1;
            elsif seq_count = 1 then
                cmd_next       <= CMD_NOP;
                sdram_dq_next  <= (others => 'Z');  -- Tri-state after write    
                seq_count_next <= seq_count + 1;
            elsif seq_count = TRP_CYCLES then
                -- Back to idle, row still active
                cmd_next             <= CMD_NOP;
                sdram_dqm_next       <= "11";
                state_next           <= ST_IDLE;
                seq_count_next       <= 0;
            else
                cmd_next  <= CMD_NOP;
                seq_count_next <= seq_count + 1;
            end if;
        
        when others =>
            state_next <= ST_INIT;
                
    end case;
    end process;

end rtl;