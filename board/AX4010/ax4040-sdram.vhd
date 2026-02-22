----------------------------------------------------------------------------------
-- SDRAM Controller - Converted from Alinx Verilog
-- Original author: Alinx (meisq@qq.com)
-- Converted to VHDL for comparison/testing
----------------------------------------------------------------------------------
library IEEE;
    use IEEE.std_logic_1164.all;
    use IEEE.numeric_std.all;

entity sdram_core is
    generic (
        T_RP            : integer := 4;   -- Precharge period
        T_RC            : integer := 6;   -- Auto refresh period
        T_MRD           : integer := 6;   -- Mode register program time
        T_RCD           : integer := 2;   -- Active to Read/Write delay
        T_WR            : integer := 3;   -- Write recovery time
        CASn            : integer := 3;   -- CAS latency
        SDR_BA_WIDTH    : integer := 2;
        SDR_ROW_WIDTH   : integer := 13;
        SDR_COL_WIDTH   : integer := 9;
        SDR_DQ_WIDTH    : integer := 16;
        SDR_DQM_WIDTH   : integer := 2;
        APP_ADDR_WIDTH  : integer := 24;  -- BA + ROW + COL
        APP_BURST_WIDTH : integer := 9
    );
    port (
        clk                  : in    std_logic;
        rst                  : in    std_logic;  -- Active high reset
        -- Write interface
        wr_burst_req         : in    std_logic;
        wr_burst_data        : in    std_logic_vector(SDR_DQ_WIDTH-1 downto 0);
        wr_burst_len         : in    std_logic_vector(APP_BURST_WIDTH-1 downto 0);
        wr_burst_addr        : in    std_logic_vector(APP_ADDR_WIDTH-1 downto 0);
        wr_burst_data_req    : out   std_logic;
        wr_burst_finish      : out   std_logic;
        -- Read interface
        rd_burst_req         : in    std_logic;
        rd_burst_len         : in    std_logic_vector(APP_BURST_WIDTH-1 downto 0);
        rd_burst_addr        : in    std_logic_vector(APP_ADDR_WIDTH-1 downto 0);
        rd_burst_data        : out   std_logic_vector(SDR_DQ_WIDTH-1 downto 0);
        rd_burst_data_valid  : out   std_logic;
        rd_burst_finish      : out   std_logic;
        -- SDRAM interface
        sdram_cke            : out   std_logic;
        sdram_cs_n           : out   std_logic;
        sdram_ras_n          : out   std_logic;
        sdram_cas_n          : out   std_logic;
        sdram_we_n           : out   std_logic;
        sdram_ba             : out   std_logic_vector(SDR_BA_WIDTH-1 downto 0);
        sdram_addr           : out   std_logic_vector(SDR_ROW_WIDTH-1 downto 0);
        sdram_dqm            : out   std_logic_vector(SDR_DQM_WIDTH-1 downto 0);
        sdram_dq             : inout std_logic_vector(SDR_DQ_WIDTH-1 downto 0)
    );
end sdram_core;

architecture rtl of sdram_core is

    -- State machine states
    type state_type is (
        S_INIT_NOP,  S_INIT_PRE,  S_INIT_TRP,  S_INIT_AR1,  S_INIT_TRF1,
        S_INIT_AR2,  S_INIT_TRF2, S_INIT_MRS,  S_INIT_TMRD, S_INIT_DONE,
        S_IDLE,      S_ACTIVE,    S_TRCD,      S_READ,      S_CL,
        S_RD,        S_RWAIT,     S_WRITE,     S_WD,        S_TDAL,
        S_AR,        S_TRFC
    );
    
    signal state : state_type;
    
    -- Internal signals
    signal read_flag           : std_logic;
    signal done_200us          : std_logic;
    signal sdram_ref_req       : std_logic;
    signal sdram_ref_ack       : std_logic;
    signal sdram_ba_r          : std_logic_vector(SDR_BA_WIDTH-1 downto 0);
    signal sdram_addr_r        : std_logic_vector(SDR_ROW_WIDTH-1 downto 0);
    signal ras_n_r             : std_logic;
    signal cas_n_r             : std_logic;
    signal we_n_r              : std_logic;
    signal sys_addr            : std_logic_vector(APP_ADDR_WIDTH-1 downto 0);
    signal cnt_200us           : unsigned(14 downto 0);
    signal cnt_7p5us           : unsigned(10 downto 0);
    signal sdr_dq_out          : std_logic_vector(SDR_DQ_WIDTH-1 downto 0);
    signal sdr_dq_in           : std_logic_vector(SDR_DQ_WIDTH-1 downto 0);
    signal sdr_dq_oe           : std_logic;
    signal cnt_clk_r           : unsigned(8 downto 0);
    signal cnt_rst_n           : std_logic;
    
    signal wr_burst_data_req_d0   : std_logic;
    signal wr_burst_data_req_d1   : std_logic;
    signal rd_burst_data_valid_d0 : std_logic;
    signal rd_burst_data_valid_d1 : std_logic;
    
    signal wr_burst_data_req_i    : std_logic;
    signal rd_burst_data_valid_i  : std_logic;
    
    -- End condition signals
    signal end_trp      : std_logic;
    signal end_trfc     : std_logic;
    signal end_tmrd     : std_logic;
    signal end_trcd     : std_logic;
    signal end_tcl      : std_logic;
    signal end_rdburst  : std_logic;
    signal end_tread    : std_logic;
    signal end_wrburst  : std_logic;
    signal end_twrite   : std_logic;
    signal end_tdal     : std_logic;
    signal end_trwait   : std_logic;

begin

    -- End conditions
    end_trp     <= '1' when cnt_clk_r = T_RP else '0';
    end_trfc    <= '1' when cnt_clk_r = T_RC else '0';
    end_tmrd    <= '1' when cnt_clk_r = T_MRD else '0';
    end_trcd    <= '1' when cnt_clk_r = (T_RCD-1) else '0';
    end_tcl     <= '1' when cnt_clk_r = (CASn-1) else '0';
    end_rdburst <= '1' when cnt_clk_r = (unsigned(rd_burst_len)-4) else '0';
    end_tread   <= '1' when cnt_clk_r = (unsigned(rd_burst_len)+2) else '0';
    end_wrburst <= '1' when cnt_clk_r = (unsigned(wr_burst_len)-1) else '0';
    end_twrite  <= '1' when cnt_clk_r = (unsigned(wr_burst_len)-1) else '0';
    end_tdal    <= '1' when cnt_clk_r = T_WR else '0';
    end_trwait  <= '1' when cnt_clk_r = T_RP else '0';

    -- Edge detection for finish signals
    process(clk, rst)
    begin
        if rst = '1' then
            wr_burst_data_req_d0   <= '0';
            wr_burst_data_req_d1   <= '0';
            rd_burst_data_valid_d0 <= '0';
            rd_burst_data_valid_d1 <= '0';
        elsif rising_edge(clk) then
            wr_burst_data_req_d0   <= wr_burst_data_req_i;
            wr_burst_data_req_d1   <= wr_burst_data_req_d0;
            rd_burst_data_valid_d0 <= rd_burst_data_valid_i;
            rd_burst_data_valid_d1 <= rd_burst_data_valid_d0;
        end if;
    end process;

    wr_burst_finish <= (not wr_burst_data_req_d0) and wr_burst_data_req_d1;
    rd_burst_finish <= (not rd_burst_data_valid_d0) and rd_burst_data_valid_d1;
    rd_burst_data   <= sdr_dq_in;

    -- SDRAM outputs
    sdram_dqm   <= (others => '0');
    sdram_dq    <= sdr_dq_out when sdr_dq_oe = '1' else (others => 'Z');
    sdram_cke   <= '1';
    sdram_cs_n  <= '0';
    sdram_ba    <= sdram_ba_r;
    sdram_addr  <= sdram_addr_r;
    sdram_ras_n <= ras_n_r;
    sdram_cas_n <= cas_n_r;
    sdram_we_n  <= we_n_r;
    
    sys_addr <= rd_burst_addr when read_flag = '1' else wr_burst_addr;

    -- Power-on 200us timer
    process(clk, rst)
    begin
        if rst = '1' then
            cnt_200us <= (others => '0');
        elsif rising_edge(clk) then
            if cnt_200us < 20000 then
                cnt_200us <= cnt_200us + 1;
            end if;
        end if;
    end process;

    done_200us <= '1' when cnt_200us = 20000 else '0';

    -- 7.5us refresh timer
    process(clk, rst)
    begin
        if rst = '1' then
            cnt_7p5us <= (others => '0');
        elsif rising_edge(clk) then
            if cnt_7p5us < 750 then
                cnt_7p5us <= cnt_7p5us + 1;
            else
                cnt_7p5us <= (others => '0');
            end if;
        end if;
    end process;

    -- Refresh request generation
    process(clk, rst)
    begin
        if rst = '1' then
            sdram_ref_req <= '0';
        elsif rising_edge(clk) then
            if cnt_7p5us = 749 then
                sdram_ref_req <= '1';
            elsif sdram_ref_ack = '1' then
                sdram_ref_req <= '0';
            end if;
        end if;
    end process;

    -- Main state machine
    process(clk, rst)
    begin
        if rst = '1' then
            state <= S_INIT_NOP;
            read_flag <= '1';
        elsif rising_edge(clk) then
            case state is
                when S_INIT_NOP =>
                    if done_200us = '1' then
                        state <= S_INIT_PRE;
                    end if;
                    
                when S_INIT_PRE =>
                    state <= S_INIT_TRP;
                    
                when S_INIT_TRP =>
                    if end_trp = '1' then
                        state <= S_INIT_AR1;
                    end if;
                    
                when S_INIT_AR1 =>
                    state <= S_INIT_TRF1;
                    
                when S_INIT_TRF1 =>
                    if end_trfc = '1' then
                        state <= S_INIT_AR2;
                    end if;
                    
                when S_INIT_AR2 =>
                    state <= S_INIT_TRF2;
                    
                when S_INIT_TRF2 =>
                    if end_trfc = '1' then
                        state <= S_INIT_MRS;
                    end if;
                    
                when S_INIT_MRS =>
                    state <= S_INIT_TMRD;
                    
                when S_INIT_TMRD =>
                    if end_tmrd = '1' then
                        state <= S_INIT_DONE;
                    end if;
                    
                when S_INIT_DONE =>
                    state <= S_IDLE;
                    
                when S_IDLE =>
                    if sdram_ref_req = '1' then
                        state <= S_AR;
                        read_flag <= '1';
                    elsif wr_burst_req = '1' then
                        state <= S_ACTIVE;
                        read_flag <= '0';
                    elsif rd_burst_req = '1' then
                        state <= S_ACTIVE;
                        read_flag <= '1';
                    end if;
                    
                when S_ACTIVE =>
                    if T_RCD = 0 then
                        if read_flag = '1' then
                            state <= S_READ;
                        else
                            state <= S_WRITE;
                        end if;
                    else
                        state <= S_TRCD;
                    end if;
                    
                when S_TRCD =>
                    if end_trcd = '1' then
                        if read_flag = '1' then
                            state <= S_READ;
                        else
                            state <= S_WRITE;
                        end if;
                    end if;
                    
                when S_READ =>
                    state <= S_CL;
                    
                when S_CL =>
                    if end_tcl = '1' then
                        state <= S_RD;
                    end if;
                    
                when S_RD =>
                    if end_tread = '1' then
                        state <= S_IDLE;
                    end if;
                    
                when S_RWAIT =>
                    if end_trwait = '1' then
                        state <= S_IDLE;
                    end if;
                    
                when S_WRITE =>
                    state <= S_WD;
                    
                when S_WD =>
                    if end_twrite = '1' then
                        state <= S_TDAL;
                    end if;
                    
                when S_TDAL =>
                    if end_tdal = '1' then
                        state <= S_IDLE;
                    end if;
                    
                when S_AR =>
                    state <= S_TRFC;
                    
                when S_TRFC =>
                    if end_trfc = '1' then
                        state <= S_IDLE;
                    end if;
                    
                when others =>
                    state <= S_INIT_NOP;
            end case;
        end if;
    end process;

    sdram_ref_ack <= '1' when state = S_AR else '0';

    -- Write/Read data request signals
    wr_burst_data_req_i <= '1' when ((state = S_TRCD and read_flag = '0') or 
                                      state = S_WRITE or 
                                      (state = S_WD and cnt_clk_r < (unsigned(wr_burst_len) - 2))) else '0';
                                      
    rd_burst_data_valid_i <= '1' when (state = S_RD and 
                                       cnt_clk_r >= 1 and 
                                       cnt_clk_r < (unsigned(rd_burst_len) + 1)) else '0';

    wr_burst_data_req   <= wr_burst_data_req_i;
    rd_burst_data_valid <= rd_burst_data_valid_i;

    -- Clock counter for timing
    process(clk, rst)
    begin
        if rst = '1' then
            cnt_clk_r <= (others => '0');
        elsif rising_edge(clk) then
            if cnt_rst_n = '0' then
                cnt_clk_r <= (others => '0');
            else
                cnt_clk_r <= cnt_clk_r + 1;
            end if;
        end if;
    end process;

    -- Counter reset logic
    process(state, end_trp, end_trfc, end_tmrd, end_trcd, end_tcl, 
            end_tread, end_trwait, end_twrite, end_tdal)
    begin
        case state is
            when S_INIT_NOP  => cnt_rst_n <= '0';
            when S_INIT_PRE  => cnt_rst_n <= '1';
            when S_INIT_TRP  => cnt_rst_n <= not end_trp;
            when S_INIT_AR1 | S_INIT_AR2 => cnt_rst_n <= '1';
            when S_INIT_TRF1 | S_INIT_TRF2 => cnt_rst_n <= not end_trfc;
            when S_INIT_MRS  => cnt_rst_n <= '1';
            when S_INIT_TMRD => cnt_rst_n <= not end_tmrd;
            when S_IDLE      => cnt_rst_n <= '0';
            when S_ACTIVE    => cnt_rst_n <= '1';
            when S_TRCD      => cnt_rst_n <= not end_trcd;
            when S_CL        => cnt_rst_n <= not end_tcl;
            when S_RD        => cnt_rst_n <= not end_tread;
            when S_RWAIT     => cnt_rst_n <= not end_trwait;
            when S_WD        => cnt_rst_n <= not end_twrite;
            when S_TDAL      => cnt_rst_n <= not end_tdal;
            when S_TRFC      => cnt_rst_n <= not end_trfc;
            when others      => cnt_rst_n <= '0';
        end case;
    end process;

    -- SDRAM data output
    process(clk, rst)
    begin
        if rst = '1' then
            sdr_dq_out <= (others => '0');
        elsif rising_edge(clk) then
            if state = S_WRITE or state = S_WD then
                sdr_dq_out <= wr_burst_data;
            end if;
        end if;
    end process;

    -- Bidirectional data control
    process(clk, rst)
    begin
        if rst = '1' then
            sdr_dq_oe <= '0';
        elsif rising_edge(clk) then
            if state = S_WRITE or state = S_WD then
                sdr_dq_oe <= '1';
            else
                sdr_dq_oe <= '0';
            end if;
        end if;
    end process;

    -- Read data from SDRAM
    process(clk, rst)
    begin
        if rst = '1' then
            sdr_dq_in <= (others => '0');
        elsif rising_edge(clk) then
            if state = S_RD then
                sdr_dq_in <= sdram_dq;
            end if;
        end if;
    end process;

    -- Command generation
    process(clk, rst)
    begin
        if rst = '1' then
            ras_n_r     <= '1';
            cas_n_r     <= '1';
            we_n_r      <= '1';
            sdram_ba_r  <= (others => '1');
            sdram_addr_r <= (others => '1');
        elsif rising_edge(clk) then
            case state is
                when S_INIT_NOP | S_INIT_TRP | S_INIT_TRF1 | S_INIT_TRF2 | S_INIT_TMRD =>
                    ras_n_r      <= '1';
                    cas_n_r      <= '1';
                    we_n_r       <= '1';
                    sdram_ba_r   <= (others => '1');
                    sdram_addr_r <= (others => '1');
                    
                when S_INIT_PRE =>
                    ras_n_r      <= '0';
                    cas_n_r      <= '1';
                    we_n_r       <= '0';
                    sdram_ba_r   <= (others => '1');
                    sdram_addr_r <= (others => '1');
                    
                when S_INIT_AR1 | S_INIT_AR2 =>
                    ras_n_r      <= '0';
                    cas_n_r      <= '0';
                    we_n_r       <= '1';
                    sdram_ba_r   <= (others => '1');
                    sdram_addr_r <= (others => '1');
                    
                when S_INIT_MRS =>
                    ras_n_r      <= '0';
                    cas_n_r      <= '0';
                    we_n_r       <= '0';
                    sdram_ba_r   <= (others => '0');
                    sdram_addr_r <= "000" & '0' & "00" & "011" & '0' & "111";
                    -- Mode: burst write, standard, CAS=3, sequential, full page
                    
                when S_IDLE | S_TRCD | S_CL | S_TRFC | S_TDAL =>
                    ras_n_r      <= '1';
                    cas_n_r      <= '1';
                    we_n_r       <= '1';
                    sdram_ba_r   <= (others => '1');
                    sdram_addr_r <= (others => '1');
                    
                when S_ACTIVE =>
                    ras_n_r      <= '0';
                    cas_n_r      <= '1';
                    we_n_r       <= '1';
                    sdram_ba_r   <= sys_addr(APP_ADDR_WIDTH-1 downto APP_ADDR_WIDTH-SDR_BA_WIDTH);
                    sdram_addr_r <= sys_addr(SDR_COL_WIDTH+SDR_ROW_WIDTH-1 downto SDR_COL_WIDTH);
                    
                when S_READ =>
                    ras_n_r      <= '1';
                    cas_n_r      <= '0';
                    we_n_r       <= '1';
                    sdram_ba_r   <= sys_addr(APP_ADDR_WIDTH-1 downto APP_ADDR_WIDTH-SDR_BA_WIDTH);
                    sdram_addr_r <= "0010" & sys_addr(8 downto 0);  -- A10=1 for auto-precharge
                    
                when S_RD =>
                    if end_rdburst = '1' then
                        ras_n_r  <= '1';
                        cas_n_r  <= '1';
                        we_n_r   <= '0';  -- Burst terminate
                    else
                        ras_n_r      <= '1';
                        cas_n_r      <= '1';
                        we_n_r       <= '1';
                        sdram_ba_r   <= (others => '1');
                        sdram_addr_r <= (others => '1');
                    end if;
                    
                when S_WRITE =>
                    ras_n_r      <= '1';
                    cas_n_r      <= '0';
                    we_n_r       <= '0';
                    sdram_ba_r   <= sys_addr(APP_ADDR_WIDTH-1 downto APP_ADDR_WIDTH-SDR_BA_WIDTH);
                    sdram_addr_r <= "0010" & sys_addr(8 downto 0);  -- A10=1 for auto-precharge
                    
                when S_WD =>
                    if end_wrburst = '1' then
                        ras_n_r  <= '1';
                        cas_n_r  <= '1';
                        we_n_r   <= '0';  -- Burst terminate
                    else
                        ras_n_r      <= '1';
                        cas_n_r      <= '1';
                        we_n_r       <= '1';
                        sdram_ba_r   <= (others => '1');
                        sdram_addr_r <= (others => '1');
                    end if;
                    
                when S_AR =>
                    ras_n_r      <= '0';
                    cas_n_r      <= '0';
                    we_n_r       <= '1';
                    sdram_ba_r   <= (others => '1');
                    sdram_addr_r <= (others => '1');
                    
                when others =>
                    ras_n_r      <= '1';
                    cas_n_r      <= '1';
                    we_n_r       <= '1';
                    sdram_ba_r   <= (others => '1');
                    sdram_addr_r <= (others => '1');
            end case;
        end if;
    end process;

end rtl;