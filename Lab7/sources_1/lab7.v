`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2018/11/01 11:16:50
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  input  uart_rx,
  output uart_tx,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [2:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001, S_MAIN_CALCU = 3'b100,
                 S_MAIN_SHOW = 3'b010, S_MAIN_WAIT = 3'b011;

localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
             
localparam INIT_DELAY = 100_000; // 1 msec @ 100 MHz
localparam PROMPT_STR = 0;  // starting index of the prompt message
localparam PROMPT_LEN = 169; // length of the prompt message
localparam MEM_SIZE   = PROMPT_LEN;

// declare system variables
wire [1:0]  btn_level, btn_pressed;
reg  [1:0]  prev_btn_level;
reg  [2:0]  P, P_next;
reg  [11:0] user_addr;
reg  [7:0]  user_data;
wire enter_pressed;
wire print_enable, print_done;
reg [$clog2(MEM_SIZE):0] send_counter;
reg [1:0] Q, Q_next;
reg [$clog2(INIT_DELAY):0] init_counter;
reg [7:0] data[0:MEM_SIZE-1];
reg  [0:PROMPT_LEN*8-1] msa = {"\015\012The matrix multiplication result is:\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012",
                                "[ 00000, 00000, 00000, 00000 ]\015\012", 8'h00 };
reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;


// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;  // if recevied is true, rx_temp latches rx_byte for ONLY ONE CLOCK CYCLE!
wire [7:0] tx_byte;
wire [7:0] echo_key; // keystrokes to be echoed to the terminal
wire is_num_key;
wire is_receiving;
wire is_transmitting;
wire recv_error;



uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

assign usr_led = 4'h00;

LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
  
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);


integer i;

reg[19:0] product[0:15];

always @(posedge clk) begin
  if (~reset_n) begin
    for (i = 0; i < PROMPT_LEN; i = i + 1) data[i] = msa[i*8 +: 8];
  end
  else if (P == S_MAIN_CALCU) begin
    for(i = 0; i < 4; i = i + 1)begin
      data[42+i*32] <= ((product[i][ 19: 16] > 9)? "7" : "0") + product[i][ 19: 16];
      data[43+i*32] <= ((product[i][ 15: 12] > 9)? "7" : "0") + product[i][ 15: 12];
      data[44+i*32] <= ((product[i][ 11: 8] > 9)? "7" : "0") + product[i][ 11: 8];
      data[45+i*32] <= ((product[i][ 7: 4] > 9)? "7" : "0") + product[i][ 7: 4];
      data[46+i*32] <= ((product[i][ 3: 0] > 9)? "7" : "0") + product[i][ 3: 0];
      data[49+i*32] <= ((product[i+4][ 19: 16] > 9)? "7" : "0") + product[i+4][ 19: 16];
      data[50+i*32] <= ((product[i+4][ 15: 12] > 9)? "7" : "0") + product[i+4][ 15: 12];
      data[51+i*32] <= ((product[i+4][ 11: 8] > 9)? "7" : "0") + product[i+4][ 11: 8];
      data[52+i*32] <= ((product[i+4][ 7: 4] > 9)? "7" : "0") + product[i+4][ 7: 4];
      data[53+i*32] <= ((product[i+4][ 3: 0] > 9)? "7" : "0") + product[i+4][ 3: 0];
      data[56+i*32] <= ((product[i+8][ 19: 16] > 9)? "7" : "0") + product[i+8][ 19: 16];
      data[57+i*32] <= ((product[i+8][ 15: 12] > 9)? "7" : "0") + product[i+8][ 15: 12];
      data[58+i*32] <= ((product[i+8][ 11: 8] > 9)? "7" : "0") + product[i+8][ 11: 8];
      data[59+i*32] <= ((product[i+8][ 7: 4] > 9)? "7" : "0") + product[i+8][ 7: 4];
      data[60+i*32] <= ((product[i+8][ 3: 0] > 9)? "7" : "0") + product[i+8][ 3: 0];
      data[63+i*32] <= ((product[i+12][ 19: 16] > 9)? "7" : "0") + product[i+12][ 19: 16];
      data[64+i*32] <= ((product[i+12][ 15: 12] > 9)? "7" : "0") + product[i+12][ 15: 12];
      data[65+i*32] <= ((product[i+12][ 11: 8] > 9)? "7" : "0") + product[i+12][ 11: 8];
      data[66+i*32] <= ((product[i+12][ 7: 4] > 9)? "7" : "0") + product[i+12][ 7: 4];
      data[67+i*32] <= ((product[i+12][ 3: 0] > 9)? "7" : "0") + product[i+12][ 3: 0];
    end
  end
end



always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);




sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = user_addr[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.




always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_ADDR; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

reg[7:0] a[0:15];
reg[7:0] b[0:15];
reg[11:0] readcnt = 0,usr_store_sram_addr = 0;
reg[2:0] calcucnt = 0;
wire[11:0] store_sram_addr;
wire[7:0] store_data;
reg[7:0] usr_store_data;

sram ram1(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(store_sram_addr), .data_i(data_in), .data_o(store_data));

assign store_sram_addr = usr_store_sram_addr[11:0];

always @(posedge clk) begin
  if (~reset_n) usr_store_data <= 8'b0;
  else if (sram_en && !sram_we) usr_store_data <= store_data;
end


always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_ADDR: // send an address to the SRAM 
     if (init_counter < INIT_DELAY) P_next = S_MAIN_ADDR;
		  else P_next =  S_MAIN_READ;
    S_MAIN_READ: // fetch the sample from the SRAM
      if (readcnt >= 64) P_next = S_MAIN_CALCU; 
      else P_next = S_MAIN_READ;
    S_MAIN_CALCU:
      if (calcucnt >= 4) P_next = S_MAIN_SHOW; 
      else P_next = S_MAIN_CALCU;
    S_MAIN_SHOW:
      if (print_done) P_next = S_MAIN_WAIT;
      else P_next = S_MAIN_SHOW;
    S_MAIN_WAIT: // wait for a button click
      if (| btn_pressed == 1 ) P_next = S_MAIN_ADDR;
      else P_next = S_MAIN_WAIT;
  endcase
end




assign print_enable = (P == S_MAIN_CALCU && P_next == S_MAIN_SHOW );
assign print_done = (tx_byte == 8'h0);



always @(posedge clk) begin
  if (P == S_MAIN_ADDR) init_counter <= init_counter + 1;
  else init_counter <= 0;
  if (P == S_MAIN_READ) begin 
    if(readcnt % 2 == 0) begin
      usr_store_sram_addr <= (usr_store_sram_addr < 2048)? usr_store_sram_addr + 1 : usr_store_sram_addr;
    end
    else begin
      if(usr_store_sram_addr < 17) a[usr_store_sram_addr-1] = usr_store_data ;
      else b[usr_store_sram_addr-17] = usr_store_data;
    end
    readcnt <= readcnt + 1;
  end
  else begin
    readcnt <= 0;
    usr_store_sram_addr <= 8'h00;
  end
  if(P == S_MAIN_CALCU)begin
    product[4*calcucnt]<=a[0]*b[4*calcucnt]+a[4]*b[4*calcucnt+1]+a[8]*b[4*calcucnt+2]+a[12]*b[4*calcucnt+3];
    product[4*calcucnt+1]<=a[1]*b[4*calcucnt]+a[5]*b[4*calcucnt+1]+a[9]*b[4*calcucnt+2]+a[13]*b[4*calcucnt+3];
    product[4*calcucnt+2]<=a[2]*b[4*calcucnt]+a[6]*b[4*calcucnt+1]+a[10]*b[4*calcucnt+2]+a[14]*b[4*calcucnt+3];
    product[4*calcucnt+3]<=a[3]*b[4*calcucnt]+a[7]*b[4*calcucnt+1]+a[11]*b[4*calcucnt+2]+a[15]*b[4*calcucnt+3];
    
    calcucnt<=calcucnt+1;
  end
  else calcucnt <= 0;
end



always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end



assign transmit = (Q_next == S_UART_WAIT ||
                   print_enable);
assign tx_byte  = data[send_counter];



always @(posedge clk) begin
  case (P_next)
    S_MAIN_ADDR: send_counter <= PROMPT_STR;
    default: send_counter <= send_counter + (Q_next == S_UART_INCR);
  endcase
end



always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end




always @(posedge clk) begin
  if (~reset_n) user_data <= 8'b0;
  else if (sram_en && !sram_we) user_data <= data_out;
end




always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Data at [0x---] ";
  end
  else if (P == S_MAIN_SHOW) begin
    row_A[39:32] <= ((user_addr[11:08] > 9)? "7" : "0") + user_addr[11:08];
    row_A[31:24] <= ((user_addr[07:04] > 9)? "7" : "0") + user_addr[07:04];
    row_A[23:16] <= ((user_addr[03:00] > 9)? "7" : "0") + user_addr[03:00];
  end
end

always @(posedge clk) begin
  if (~reset_n) begin
    row_B <= "is equal to 0x--";
  end
  else if (P == S_MAIN_SHOW) begin
    row_B[15:08] <= ((user_data[7:4] > 9)? "7" : "0") + user_data[7:4];
    row_B[07: 0] <= ((user_data[3:0] > 9)? "7" : "0") + user_data[3:0];
  end
end





always @(posedge clk) begin
  if (~reset_n)
    user_addr <= 12'h000;
  else if (btn_pressed[1])
    user_addr <= (user_addr < 2048)? user_addr + 1 : user_addr;
  else if (btn_pressed[0])
    user_addr <= (user_addr > 0)? user_addr - 1 : user_addr;
end



endmodule
