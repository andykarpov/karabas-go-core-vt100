-------------------------------------------------------------------------------
-- MCU SPI comm module
-------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.conv_integer;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity mcu is
	port
	(
	 CLK			 : in std_logic;
	 N_RESET 	 : in std_logic := '1';

	 -- spi
    MCU_MOSI    : in std_logic;
    MCU_MISO    : out std_logic := 'Z';
    MCU_SCK     : in std_logic;
	 MCU_SS 		 : in std_logic;

	 -- ps/2 scancode
	 KB_SCANCODE : out std_logic_vector(7 downto 0) := "00000000";
	 KB_SCANCODE_UPD : buffer std_logic := '0';

	 -- hw buttons
	 BTNS				: out std_logic_vector(1 downto 0) := "00";

	 -- usb uart
	 UART_RX_DATA			: out std_logic_vector(7 downto 0);
	 UART_RX_IDX	: out std_logic_vector(7 downto 0) := (others => '0');
	 UART_TX_DATA			: in std_logic_vector(7 downto 0);
	 UART_TX_WR				: in std_logic := '0';
	 
	 -- soft switches command
	 SOFTSW_COMMAND : out std_logic_vector(15 downto 0);
	 
	 -- debug
	 DEBUG_ADDR : in std_logic_vector(15 downto 0) := (others => '0');
	 DEBUG_DATA : in std_logic_vector(15 downto 0) := (others => '0');	 

	 -- hw setup
	 HWID 		: out std_logic_vector(7 downto 0) := (others => '0');
	 DVI_ONLY 	: out std_logic := '0';

    -- osd command
	 OSD_COMMAND: out std_logic_vector(15 downto 0);
	 
	 -- busy
	 BUSY: buffer std_logic := '1'
	 
	);
    end mcu;
architecture rtl of mcu is

	-- spi commands
	constant CMD_KBD			: std_logic_vector(7 downto 0) := x"01";
	constant CMD_MOUSE 		: std_logic_vector(7 downto 0) := x"02";
	constant CMD_JOY   		: std_logic_vector(7 downto 0) := x"03";
	constant CMD_BTNS			: std_logic_vector(7 downto 0) := x"04";
	constant CMD_SWITCHES   : std_logic_vector(7 downto 0) := x"05";
	constant CMD_ROMBANK    : std_logic_vector(7 downto 0) := x"06";
	constant CMD_ROMDATA    : std_logic_vector(7 downto 0) := x"07";
	constant CMD_ROMLOADER  : std_logic_vector(7 downto 0) := x"08";
	constant CMD_FT    		: std_logic_vector(7 downto 0) := x"09";
	constant CMD_FT_DATA		: std_logic_vector(7 downto 0) := x"0A";
	constant CMD_PS2_SCANCODE : std_logic_vector(7 downto 0) := x"0B";

	-- 11, 12 - usb gamepad, joy : todo

	constant CMD_OSD 			: std_logic_vector(7 downto 0) := x"20";
	constant CMD_DEBUG_ADDR : std_logic_vector(7 downto 0) := x"30";
	constant CMD_DEBUG_DATA : std_logic_vector(7 downto 0) := x"31";	
	constant CMD_HW_SETUP	: std_logic_vector(7 downto 0) := x"F9"; 
	constant CMD_RTC 			: std_logic_vector(7 downto 0) := x"FA";
	constant CMD_FLASHBOOT  : std_logic_vector(7 downto 0) := x"FB";
	constant CMD_UART			: std_logic_vector(7 downto 0) := x"FC";
	constant CMD_INIT_START	: std_logic_vector(7 downto 0) := x"FD";
	constant CMD_INIT_DONE	: std_logic_vector(7 downto 0) := x"FE";	
	constant CMD_NOPE			: std_logic_vector(7 downto 0) := x"FF";

	 -- spi
	 signal spi_do_valid 	: std_logic := '0';
	 signal prev_spi_do_valid : std_logic := '0';
	 signal spi_di 			: std_logic_vector(23 downto 0);
	 signal spi_do 			: std_logic_vector(23 downto 0);
	 signal spi_di_req 		: std_logic;
	 signal prev_spi_di_req : std_logic := '0';
	 signal spi_miso 		 	: std_logic;
	 
	-- spi fifo 
	signal queue_di			: std_logic_vector(23 downto 0);
	signal queue_wr_req		: std_logic := '0';
	signal queue_wr_full		: std_logic;
		
	signal queue_rd_req		: std_logic := '0';
	signal queue_do			: std_logic_vector(23 downto 0);
	signal queue_rd_empty   : std_logic;
	
	-- debug
	signal prev_debug_addr  : std_logic_vector(15 downto 0) := (others => '0');
	signal prev_debug_data  : std_logic_vector(15 downto 0) := (others => '0');
		 
begin
	
	--------------------------------------------------------------------------
	-- MCU SPI communication
	--------------------------------------------------------------------------		  
	
	U_SPI: entity work.spi_slave
	generic map(
			N             => 24 -- 3 bytes (cmd + addr + data)       
	 )
	port map(
		  clk_i          => CLK,
		  spi_sck_i      => MCU_SCK,
		  spi_ssel_i     => MCU_SS,
		  spi_mosi_i     => MCU_MOSI,
		  spi_miso_o     => spi_miso,

		  di_req_o       => spi_di_req,
		  di_i           => spi_di,
		  wren_i         => '1',
		  
		  do_valid_o     => spi_do_valid,
		  do_o           => spi_do,

		  do_transfer_o  => open,
		  wren_o         => open,
		  wren_ack_o     => open,
		  rx_bit_reg_o   => open,
		  state_dbg_o    => open
	);

	spi_di <= queue_do; 
	
	MCU_MISO <= 
		spi_miso when MCU_SS = '0' else 
		'1';
	
	-- pull queue data  
	process (CLK)
	begin 
		if rising_edge(CLK) then 
			queue_rd_req <= '0';
			if (spi_di_req = '1' and prev_spi_di_req = '0') then 
				queue_rd_req <= '1';
			end if;
			prev_spi_di_req <= spi_di_req;
		end if;
	end process;

	process (CLK)
	begin
		if (rising_edge(CLK)) then
			KB_SCANCODE_UPD <= '0';
			
			prev_spi_do_valid <= spi_do_valid;
		
			if spi_do_valid = '1' and prev_spi_do_valid = '0' then
				case spi_do(23 downto 16) is 
						
					-- hw buttons
					when CMD_BTNS => 
						case spi_do(15 downto 8) is
							when x"00" => BTNS(0) <= spi_do(0);
							when x"01" => BTNS(1) <= spi_do(1);
							when others => null;
						end case;

					-- soft switches
					when CMD_SWITCHES => SOFTSW_COMMAND <= spi_do(15 downto 0);
							
					-- osd commands					
					when CMD_OSD => OSD_COMMAND <= spi_do(15 downto 0);
					
					-- uart
					when CMD_UART =>
						UART_RX_DATA <= spi_do(7 downto 0);
						UART_RX_IDX <= spi_do(15 downto 8);
						
					-- ps/2 scancode from mcu
					when CMD_PS2_SCANCODE => 
						case spi_do(15 downto 8) is
							when x"00" => KB_SCANCODE <= spi_do(7 downto 0); KB_SCANCODE_UPD <= '1' ;
							when others => null;
						end case;
					
					-- hw setup
					when CMD_HW_SETUP => 
						case spi_do(15 downto 8) is
							when x"00" => HWID <= spi_do(7 downto 0);
							when x"01" => DVI_ONLY <= spi_do(0);
							when others => null;
						end case;

					-- init start
					when CMD_INIT_START => BUSY <= '1';

					-- init done
					when CMD_INIT_DONE => BUSY <= '0';

					-- nope
					when CMD_NOPE => null;
					
					when others => null;
				end case;
			end if;
		end if;
	end process;
	
	-- fifo for write commands to send them on mcu side 
	UFIFO: entity work.fifo
	generic map (
		ADDR_WIDTH => 9,
		DATA_WIDTH => 24
	)
	port map (
		clk 	=> CLK,
		reset  => not N_RESET,

		empty  => queue_rd_empty,
		full   => queue_wr_full,
		
		rd     => queue_rd_req,
		dout  => queue_do,
		
		wr     => queue_wr_req,
		din 		=> queue_di
	);
	
	-- fifo handling / queue commands to mcu side
	process(CLK)
	begin
		if rising_edge(CLK) then
			queue_wr_req <= '0';
			if UART_TX_WR = '1' then -- send UART byte
				queue_wr_req <= '1';
				queue_di <= CMD_UART & "00000000" & UART_TX_DATA;
			elsif DEBUG_ADDR /= prev_debug_addr then -- debug address
				queue_wr_req <= '1';
				queue_di <= CMD_DEBUG_ADDR & DEBUG_ADDR;
				prev_debug_addr <= DEBUG_ADDR;
			elsif DEBUG_DATA /= prev_debug_data then -- debug data
				queue_wr_req <= '1';
				queue_di <= CMD_DEBUG_DATA & DEBUG_DATA;
				prev_debug_data <= DEBUG_DATA;
			elsif queue_rd_empty = '1' then -- anti-empty queue
				queue_wr_req <= '1';
				queue_di <= CMD_NOPE & x"0000";
			end if;
						
		end if;
	end process;
	
end RTL;

