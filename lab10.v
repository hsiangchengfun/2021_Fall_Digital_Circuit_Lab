`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module final(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    
    );
localparam [2:0] S_MAIN_START = 0,
                 S_MAIN_WAIT = 1, S_MAIN_PLAY1 = 2,
                 S_MAIN_PLAY2 = 3, S_MAIN_PLAY3 = 4,
                 S_MAIN_WIN = 5, S_MAIN_DEAD = 6;

reg  [2:0]  P, P_next;
wire [3:0]  btn_level, btn_pressed;
reg  [3:0]  prev_btn_level;

// Declare system variables
reg  [31:0] snake_clock;
wire [9:0]  pos;


// declare SRAM control signals
wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire        sram_we, sram_en;

localparam SCOREBOARD_HPOS  = 0;
localparam SCOREBOARD_VPOS  = 24;
localparam SCOREBOARD_W     = 320;
localparam SCOREBOARD_H     = 8;

localparam MAPX = 0;
localparam MAPY = 10;

localparam POS_RIGHT = 0;
localparam POS_UP = 1;
localparam POS_LEFT = 2;
localparam POS_DOWN = 3;

localparam GRIDXNUM=32;
localparam GRIDYNUM=23;
localparam GRIDLENGTH=10;

wire snakeclk;
reg [4:0] snakelength;
reg [0:19] enablepart;
reg [5:0] xsnake[0:19], ysnake[0:19], xnexthead, ynexthead;
reg [1:0] dir, dir_next;
reg finished;
wire [5:0] xcurrgrid, ycurrgrid;
reg [5:0] xfood, yfood;
reg [5:0] xflash, yflash;
reg [5:0] xvirus, yvirus;
reg [9:0] xrand, yrand;
reg [0:GRIDXNUM*GRIDYNUM-1] map;
wire margin;
wire grid_line;
reg [0:GRIDXNUM*GRIDYNUM-1] start;
reg [0:GRIDXNUM*GRIDYNUM-1] win;
reg [0:GRIDXNUM*GRIDYNUM-1] dead;
reg [0:GRIDXNUM*GRIDYNUM-1] obstacles [0:2];
wire hit_wall;
wire hit_obstacle;
wire hit_body;
reg [1:0] map_select;
wire flash_region;
wire flash_shape_region;
wire food_region;
wire food_shape_region;
wire virus_region;
wire virus_shape_region;
wire obstacle_region;
wire snake_region;
wire map_region;
wire score_region [0:5];
wire score_shape_region [0:5];
reg [0:10*10-1] score [0:5];
reg [0:10*10-1] digit [0:9];
reg [0:10*10-1] flash;
reg [0:10*10-1] food;
reg [0:10*10-1] virus;
reg [3:0] digital;
reg [3:0] decimal;
wire ate;
wire accelerate;
wire wayin;
reg death;
reg [5:0] acc_clock;
reg [31:0] poison_clock;
reg poison_flag;
//debounce
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

debounce btn_db2(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level[2])
);
debounce btn_db3(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);
// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
 
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;


// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

// Set parameters for the fish images
localparam SNAKE_VPOS   = 64; 
localparam SNAKE_W      = 9; // Width of the fish.
localparam SNAKE_H      = 9; // Height of the fish.
localparam INITIALX = 12;
localparam INITIALY = 11;
reg [17:0] snake_addr;   // Address array for up to 8 fish images.

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(


// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
          
assign sram_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.       
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos = VBUF_H*VBUF_W;//snake_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
                                
always @(posedge clk) begin
  if (~reset_n) begin
    snake_clock <= 0;
  end
  else begin
    snake_clock <= snake_clock + 1;
  end
end

// End of the animation clock code.
// ------------------------------------------------------------------------
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 4'b0000;
  else
    prev_btn_level <= btn_level;
end
assign btn_pressed = (btn_level & ~prev_btn_level);

initial begin
  start = {
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00011101000100111001000100111100,
    32'b00100001000101000101001001000000,
    32'b00100001100101000101010001000000,
    32'b00011001010101111101100001111100,
    32'b00000101001101000101010001000000,
    32'b00000101000101000101001001000000,
    32'b00111001000101000101000100111100,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000001110,
    32'b00000000000000000000000011101000,
    32'b00000000000000000000111010101000,
    32'b00000000000000000000101010101000,
    32'b00000000000000001110101010101000,
    32'b00000000000000000010101010101000,
    32'b00000000000000000011101010101000,
    32'b00000000000000000000001110101000,
    32'b00000000000000000000000000111000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000
  };
  dead = {
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000001000100111001000100000000,
    32'b00000000101001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010000111000111000000000,
    32'b00000000000000000000000000000000,
    32'b00000001111001111100111100000000,
    32'b00000001000100010001000000000000,
    32'b00000001000100010001000000000000,
    32'b00000001000100010001111100000000,
    32'b00000001000100010001000000000000,
    32'b00000001000100010001000000000000,
    32'b00000001111001111100111100000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000
  };
  win = {
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000001000100111001000100000000,
    32'b00000000101001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010001000101000100000000,
    32'b00000000010000111000111000000000,
    32'b00000000000000000000000000000000,
    32'b00000001010101111101000100000000,
    32'b00000001010100010001000100000000,
    32'b00000001010100010001100100000000,
    32'b00000001010100010001010100000000,
    32'b00000001010100010001011100000000,
    32'b00000001010100010001000100000000,
    32'b00000000111001111101000100000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000,
    32'b00000000000000000000000000000000  
  };
   map = {
          32'b11111111111111111111111111111111,    
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b10000000000000000000000000000001, 
          32'b11111111111111111111111111111111
        };
  obstacles[0] = {  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00001111100000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000001000000,  
                  32'b00000000000000000000000001000000,  
                  32'b00000000000000000000000001000000,  
                  32'b00000000000000000000000111110000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000
            };
  obstacles[1] <= {
                  32'b00000000000000000000000000000000,  
                  32'b00001111100000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000000000000001111110000000000,  
                  32'b00000000000000001000000000000000,  
                  32'b00000000000000001000000000000000,  
                  32'b00000000000000001000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,    
                  32'b00000000100000000000000000000000,  
                  32'b00000000100000000000000000000000,  
                  32'b00000000100000000000001111110000,  
                  32'b00000000100000000000000000010000,  
                  32'b00000000111111000000000000010000,  
                  32'b00000000000000000000000000010000,  
                  32'b00000000000000000000001111110000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,
                  32'b00000000000000000000000000000000,
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000
            };
            
  obstacles[2] = { 
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000,  
                  32'b00001111100000000000000000000000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000010000000000000000100000000,  
                  32'b00010010000000000000000100000000,  
                  32'b00010000000000001000000100000000,  
                  32'b00010000000000001000000100000000,  
                  32'b00010000000000001000000111110000,  
                  32'b00010000000000001000000100010000,  
                  32'b00000000000000000000000100010000,  
                  32'b00010000000000001000000100010000,  
                  32'b00010010000000001000000100010000,  
                  32'b00010010000000001000000100010000,
                  32'b00010010000000001000000100010000,  
                  32'b00010010000000001000000000010000,  
                  32'b00010010000000000000000000010000,  
                  32'b00000010000000000000000000010000,  
                  32'b00000010000000000000000000000000,  
                  32'b00000000000000000000000000000000,
                  32'b00000000000000000000000000000000,  
                  32'b00000000000000000000000000000000
            };       
                //S
                score[0]={
                10'b0000000000,
                10'b0011111100,
                10'b0100000000,
                10'b0100000000,
                10'b0100000000,
                10'b0011111100,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0011111100
                };
                
                //C
                score[1]={
                10'b0000000000,
                10'b0011111100,
                10'b0100000100,
                10'b0100000100,
                10'b0100000000,
                10'b0100000000,
                10'b0100000000,
                10'b0100000100,
                10'b0100000100,
                10'b0011111100};
                
                //O
                score[2]={
                10'b0000000000,
                10'b0011111100,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0011111100};
                
                //R
                score[3]={
                10'b0000000000,
                10'b0011111100,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0111111100,
                10'b0100000100,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010};
                
                //E
                score[4]={
                10'b0000000000,
                10'b0011111100,
                10'b0100000000,
                10'b0100000000,
                10'b0100000000,
                10'b0011111100,
                10'b0100000000,
                10'b0100000000,
                10'b0100000000,
                10'b0011111100};
                
                score[5]={
                10'b0000000000,
                10'b0000000000,
                10'b0000000000,
                10'b0000110000,
                10'b0000000000,
                10'b0000000000,
                10'b0000110000,
                10'b0000000000,
                10'b0000000000,
                10'b0000000000};
                
                digit[0]={
                10'b0000000000,
                10'b0001111100,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0001111100
                };
                
                digit[1]={
                10'b0000000000,
                10'b0001110000,
                10'b0000010000,
                10'b0000010000,
                10'b0000010000,
                10'b0000010000,
                10'b0000010000,
                10'b0000010000,
                10'b0000010000,
                10'b0011111110
                };
                
                digit[2]={
                10'b0000000000,
                10'b0011111100,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0001111100,
                10'b0010000000,
                10'b0010000000,
                10'b0010000000,
                10'b0011111110
                };
                
                digit[3]={
                10'b0000000000,
                10'b0011111100,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0011111100,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0011111100
                };
                
                digit[4]={
                10'b0000000000,
                10'b0010000100,
                10'b0010000100,
                10'b0010000100,
                10'b0010000100,
                10'b0011111110,
                10'b0000000100,
                10'b0000000100,
                10'b0000000100,
                10'b0000000100                
                };
                
                digit[5]={
                10'b0000000000,
                10'b0011111110,
                10'b0010000000,
                10'b0010000000,
                10'b0010000000,
                10'b0011111110,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0011111110
                
                };
                
                digit[6]={
                10'b0000000000,
                10'b0001111110,
                10'b0010000000,
                10'b0010000000,
                10'b0010000000,
                10'b0011111100,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0001111100               
                };
                
                digit[7]={
                10'b0000000000,
                10'b0011111100,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010                
                };
                
                digit[8]={
                10'b0000000000,
                10'b0011111100,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0111111110,
                10'b0100000010,
                10'b0100000010,
                10'b0100000010,
                10'b0011111100
                };

                digit[9]={
                10'b0000000000,
                10'b0001111100,
                10'b0010000010,
                10'b0010000010,
                10'b0010000010,
                10'b0001111110,
                10'b0000000010,
                10'b0000000010,
                10'b0000000010,
                10'b0011111100                
                };
                
                flash={
                10'b0000000000,
                10'b0000100000,
                10'b0001100000,
                10'b0011000000,
                10'b0111111000,
                10'b0011111100,
                10'b0000011000,
                10'b0000110000,
                10'b0000100000,
                10'b0000000000
                };
                
                food={
                10'b0000000000,
                10'b0001111000,
                10'b0011111100,
                10'b0111111110,
                10'b0111111110,
                10'b0111111110,
                10'b0111111110,
                10'b0011111100,
                10'b0001111000,
                10'b0000000000
                };
                
                virus={
                10'b0000000000,
                10'b0011111100,
                10'b0100000010,
                10'b0100110010,
                10'b0101001010,
                10'b0101001010,
                10'b0100110010,
                10'b0100000010,
                10'b0011111100,
                10'b0000000000                
                };                
              
end

assign score_shape_region[0]=score[0][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign score_region[0]= pixel_x[9:1]<=9 && pixel_x[9:1]>=0 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign score_shape_region[1]=score[1][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign score_region[1]= pixel_x[9:1]<=19 && pixel_x[9:1]>=10 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign score_shape_region[2]=score[2][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign score_region[2]= pixel_x[9:1]<=29 && pixel_x[9:1]>=20 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign score_shape_region[3]=score[3][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign score_region[3]= pixel_x[9:1]<=39 && pixel_x[9:1]>=30 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign score_shape_region[4]=score[4][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign score_region[4]= pixel_x[9:1]<=49 && pixel_x[9:1]>=40 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign score_shape_region[5]=score[5][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign score_region[5]= pixel_x[9:1]<=59 && pixel_x[9:1]>=50 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign digit_shape_region=digit[digital][pixel_y[9:1]*10+(pixel_x[9:1]%10)];
assign decimal_shape_region=digit[decimal][pixel_y[9:1]*10+(pixel_x[9:1]%10)];

assign decimal_region=pixel_x[9:1]>=60 && pixel_x[9:1]<=69 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;
assign digit_region=pixel_x[9:1]>=70 && pixel_x[9:1]<=79 && pixel_y[9:1]>=0 && pixel_y[9:1]<=9;

assign wayin = snakelength == 20;

always @(posedge clk) begin
  if(~reset_n) begin
    P <= S_MAIN_START;
  end
  else begin
    P <= P_next;
  end
end

// FSM next-state logic
always @(*) begin 
  case(P)
    S_MAIN_START:
      if(finished) P_next <= S_MAIN_WAIT;
      else P_next <= S_MAIN_START;
    S_MAIN_WAIT:
      if(btn_pressed[0]) P_next <= S_MAIN_PLAY1;
      else if(btn_pressed[1]) P_next <= S_MAIN_PLAY2;
      else if(btn_pressed[2]) P_next <= S_MAIN_PLAY3;
      else P_next <= S_MAIN_WAIT;
    S_MAIN_PLAY1:
      if(hit_wall || hit_body || death) P_next <= S_MAIN_DEAD;
      else if(wayin) P_next <= S_MAIN_WIN;
      else P_next <= S_MAIN_PLAY1;
    S_MAIN_PLAY2:
      if(hit_wall || hit_body || death) P_next <= S_MAIN_DEAD;
      else if(wayin) P_next <= S_MAIN_WIN;
      else P_next <= S_MAIN_PLAY2;
    S_MAIN_PLAY3:
      if(hit_wall || hit_body || death) P_next <= S_MAIN_DEAD;
      else if(wayin) P_next <= S_MAIN_WIN;
      else P_next <= S_MAIN_PLAY3;
    S_MAIN_WIN:
      if(btn_pressed[3]) P_next <= S_MAIN_START;
      else P_next <= S_MAIN_WIN; 
    S_MAIN_DEAD:
      if(btn_pressed[3]) P_next <= S_MAIN_START;
      else P_next <= S_MAIN_DEAD; 
    default:
      P_next <= S_MAIN_START;
  endcase
end

always @(posedge clk) begin
  if(~reset_n) begin
    digital <= 0;
    decimal <= 0;
  end
  else if(P==S_MAIN_START)begin
    digital <= 0;
    decimal <= 0;
  end
  else if(P==S_MAIN_PLAY1 || P==S_MAIN_PLAY2 || P==S_MAIN_PLAY3 || P==S_MAIN_WIN || P==S_MAIN_DEAD)begin
    digital <= (snakelength-5)%10;
    decimal <= (snakelength-5)/10;
  end
end

always @(posedge clk) begin 
  if(~reset_n) begin
    dir_next <= POS_RIGHT;
  end  
  else if(P == S_MAIN_START) begin
    dir_next <= POS_RIGHT;
  end
  else if(P == S_MAIN_PLAY1 || P == S_MAIN_PLAY2 || P == S_MAIN_PLAY3) begin
      if(btn_pressed[0] && dir != POS_LEFT) begin
        dir_next <= POS_RIGHT;
      end
      else if(btn_pressed[2] && dir != POS_DOWN) begin
        dir_next <= POS_UP;
      end
      else if(btn_pressed[3] && dir != POS_RIGHT) begin
        dir_next <= POS_LEFT;
      end
      else if(btn_pressed[1] && dir != POS_UP) begin
        dir_next <= POS_DOWN;
      end
  end

end

always @(posedge clk) begin
  if(P == S_MAIN_WAIT) begin
    xnexthead <= INITIALX + 1;
    ynexthead <= INITIALY;
  end
  else if(P == S_MAIN_PLAY1 || P == S_MAIN_PLAY2 || P == S_MAIN_PLAY3) begin
      if(dir_next == POS_RIGHT) begin
        if(snake_at_right) begin
         xnexthead <= 0;
         ynexthead <= ysnake[0];
        end
        else begin 
          xnexthead <= xsnake[0] + 1;
          ynexthead <= ysnake[0];
        end
      end
      else if(dir_next == POS_LEFT) begin
        if(snake_at_left) begin
          xnexthead <= 31;
          ynexthead <= ysnake[0];
        end
        else begin 
          xnexthead <= xsnake[0] - 1;
          ynexthead <= ysnake[0]; 
        end
      end
      else if(dir_next == POS_UP) begin
        if(snake_at_top) begin
          xnexthead <= xsnake[0];
          ynexthead <= 22;
        end
        else begin
          xnexthead <= xsnake[0];
          ynexthead <= ysnake[0] - 1;
        end
      end
      else if(dir_next == POS_DOWN) begin
        if(snake_at_down) begin
          xnexthead <= xsnake[0];
          ynexthead <= 0;
        end
        else begin  
          xnexthead <= xsnake[0];
          ynexthead <= ysnake[0] + 1;
        end
      end
  end
end

assign snake_at_right = (xsnake[0] == 31) && (ysnake[0] == 11) && (dir_next == POS_RIGHT);  
assign snake_at_left = (xsnake[0] == 0) && (ysnake[0] == 11) && (dir_next == POS_LEFT);
assign snake_at_top =  (xsnake[0] == 15) && (ysnake[0] == 0) && (dir_next == POS_UP); 
assign snake_at_down = (xsnake[0] == 15) && (ysnake[0] == 22) && (dir_next == POS_DOWN);
assign snakeclk =  snake_clock[acc_clock];
assign usr_led[0] = poison_clock >= 'd1000000000;
assign usr_led[1] = poison_flag;
assign usr_led[2] = poison_clock > 0;
assign usr_led[3] = P == S_MAIN_DEAD;

always @(posedge clk) begin
    if(~reset_n) begin
        map_select <= 0;
    end
    else if(P == S_MAIN_PLAY1) begin
        map_select <= 0;
    end
    else if(P == S_MAIN_PLAY2) begin
        map_select <= 1;
    end
    else if(P == S_MAIN_PLAY3) begin
        map_select <= 2;
    end
end

integer i;
always @(posedge snakeclk) begin
  if(~reset_n) begin
    snakelength <= 5;
    finished <= 0;
    death <= 0;
    acc_clock <= 24;
    dir <= POS_RIGHT;
  end
  if(P == S_MAIN_START) begin
      dir <= POS_RIGHT;
      death <= 0;
      snakelength <= 5;
      acc_clock <= 24;
      xsnake[0] <= INITIALX;
      xsnake[1] <= INITIALX - 1;
      xsnake[2] <= INITIALX - 2;
      xsnake[3] <= INITIALX - 3;
      xsnake[4] <= INITIALX - 4;
      ysnake[0] <= INITIALY;
      ysnake[1] <= INITIALY;
      ysnake[2] <= INITIALY;
      ysnake[3] <= INITIALY;
      ysnake[4] <= INITIALY;
      finished <= 1;
  end
  else if (P == S_MAIN_PLAY1 || P == S_MAIN_PLAY2 || P == S_MAIN_PLAY3) begin
      dir <= dir_next;
      if(!hit_obstacle) begin
          xsnake[0] <= xnexthead;
          ysnake[0] <= ynexthead;
          for(i = 1; i < snakelength; i = i + 1) begin
              xsnake[i] <= xsnake[i-1];
              ysnake[i] <= ysnake[i-1];
          end
          if(ate) begin
            if(snakelength < 20)
                snakelength <= snakelength + 1;
            xsnake[snakelength] <= xsnake[snakelength-1];
            ysnake[snakelength] <= ysnake[snakelength-1];
          end      
          if(accelerate) begin
            acc_clock <= acc_clock - 1;
          end
      end
      else begin
        if(snakelength <= 5) begin
            death <= 1;
        end
        else begin
            snakelength <= snakelength - 1;
        end
      end
  end
  else if(P == S_MAIN_WIN || P == S_MAIN_DEAD) begin
    finished <= 0;
  end
end

always @(posedge clk) begin
  if(~reset_n) begin
    poison_clock <= 0;
  end
  else if(poison_flag) begin
    if(poison_clock <= 'd1000000000) begin
      poison_clock <= poison_clock + 1;
    end 
  end
end
assign poisoning = poison_flag && poison_clock <= 'd1000000000;
assign xcurrgrid = (pixel_x[9:1] - MAPX) / 10;
assign ycurrgrid = (pixel_y[9:1] - MAPY) / 10;
assign margin = map[ycurrgrid*(GRIDXNUM)+xcurrgrid];  

assign grid_line = (pixel_x[9:1] % 10 == 0) || (pixel_y[9:1] % 10 == 0);
assign hit_wall =  ((xsnake[0] == 0 && dir_next == POS_LEFT) ||
                   (xsnake[0] == GRIDXNUM-1 && dir_next == POS_RIGHT) ||
                   (ysnake[0] == 0 && dir_next == POS_UP) ||
                   (ysnake[0] == GRIDYNUM-1 && dir_next == POS_DOWN) )&& !((xsnake[0]==0 && ysnake[0]==11) || 
                   (xsnake[0]==15  && ysnake[0]==0 )|| (xsnake[0]==15 && ysnake[0]==22) || (xsnake[0]==31 && ysnake[0]==11)); 

assign hit_body = (xnexthead == xsnake[1] && ynexthead == ysnake[1] && enablepart[1]) || 
                  (xnexthead == xsnake[2] && ynexthead == ysnake[2] && enablepart[2]) || 
                  (xnexthead == xsnake[3] && ynexthead == ysnake[3] && enablepart[3]) || 
                  (xnexthead == xsnake[4] && ynexthead == ysnake[4] && enablepart[4]) || 
                  (xnexthead == xsnake[5] && ynexthead == ysnake[5] && enablepart[5]) || 
                  (xnexthead == xsnake[6] && ynexthead == ysnake[6] && enablepart[6]) || 
                  (xnexthead == xsnake[7] && ynexthead == ysnake[7] && enablepart[7]) || 
                  (xnexthead == xsnake[8] && ynexthead == ysnake[8] && enablepart[8]) || 
                  (xnexthead == xsnake[9] && ynexthead == ysnake[9] && enablepart[9]) || 
                  (xnexthead == xsnake[10] && ynexthead == ysnake[10] && enablepart[10]) || 
                  (xnexthead == xsnake[11] && ynexthead == ysnake[11] && enablepart[11]) || 
                  (xnexthead == xsnake[12] && ynexthead == ysnake[12] && enablepart[12]) || 
                  (xnexthead == xsnake[13] && ynexthead == ysnake[13] && enablepart[13]) || 
                  (xnexthead == xsnake[14] && ynexthead == ysnake[14] && enablepart[14]) || 
                  (xnexthead == xsnake[15] && ynexthead == ysnake[15] && enablepart[15]) ||
                  (xnexthead == xsnake[16] && ynexthead == ysnake[16] && enablepart[16]) || 
                  (xnexthead == xsnake[17] && ynexthead == ysnake[17] && enablepart[17]) || 
                  (xnexthead == xsnake[18] && ynexthead == ysnake[18] && enablepart[18]) || 
                  (xnexthead == xsnake[19] && ynexthead == ysnake[19] && enablepart[19]);
                  
assign hit_obstacle = obstacles[map_select][ynexthead*GRIDXNUM+xnexthead];
//assign hit_obstacle = (snake_region==1 && 1 == obstacle_region);
assign start_region = start[ycurrgrid*GRIDXNUM+xcurrgrid];
assign dead_region = dead[ycurrgrid*GRIDXNUM+xcurrgrid];
assign win_region = win[ycurrgrid*GRIDXNUM+xcurrgrid];
assign obstacle_region = obstacles[map_select][ycurrgrid*GRIDXNUM+xcurrgrid];
assign snake_region = (xcurrgrid == xsnake[0] && ycurrgrid == ysnake[0] && enablepart[0]) ||
                      (xcurrgrid == xsnake[1] && ycurrgrid == ysnake[1] && enablepart[1]) || 
                      (xcurrgrid == xsnake[2] && ycurrgrid == ysnake[2] && enablepart[2]) || 
                      (xcurrgrid == xsnake[3] && ycurrgrid == ysnake[3] && enablepart[3]) || 
                      (xcurrgrid == xsnake[4] && ycurrgrid == ysnake[4] && enablepart[4]) || 
                      (xcurrgrid == xsnake[5] && ycurrgrid == ysnake[5] && enablepart[5]) || 
                      (xcurrgrid == xsnake[6] && ycurrgrid == ysnake[6] && enablepart[6]) || 
                      (xcurrgrid == xsnake[7] && ycurrgrid == ysnake[7] && enablepart[7]) || 
                      (xcurrgrid == xsnake[8] && ycurrgrid == ysnake[8] && enablepart[8]) || 
                      (xcurrgrid == xsnake[9] && ycurrgrid == ysnake[9] && enablepart[9]) || 
                      (xcurrgrid == xsnake[10] && ycurrgrid == ysnake[10] && enablepart[10]) || 
                      (xcurrgrid == xsnake[11] && ycurrgrid == ysnake[11] && enablepart[11]) || 
                      (xcurrgrid == xsnake[12] && ycurrgrid == ysnake[12] && enablepart[12]) || 
                      (xcurrgrid == xsnake[13] && ycurrgrid == ysnake[13] && enablepart[13]) || 
                      (xcurrgrid == xsnake[14] && ycurrgrid == ysnake[14] && enablepart[14]) || 
                      (xcurrgrid == xsnake[15] && ycurrgrid == ysnake[15] && enablepart[15]) ||
                      (xcurrgrid == xsnake[16] && ycurrgrid == ysnake[16] && enablepart[16]) || 
                      (xcurrgrid == xsnake[17] && ycurrgrid == ysnake[17] && enablepart[17]) || 
                      (xcurrgrid == xsnake[18] && ycurrgrid == ysnake[18] && enablepart[18]) || 
                      (xcurrgrid == xsnake[19] && ycurrgrid == ysnake[19] && enablepart[19]);
                      
assign food_at_snake = (xfood == xsnake[0] && yfood == ysnake[0] && enablepart[0]) ||
                     (xfood == xsnake[1] && yfood == ysnake[1] && enablepart[1]) || 
                     (xfood == xsnake[2] && yfood == ysnake[2] && enablepart[2]) || 
                     (xfood == xsnake[3] && yfood == ysnake[3] && enablepart[3]) || 
                     (xfood == xsnake[4] && yfood == ysnake[4] && enablepart[4]) || 
                     (xfood == xsnake[5] && yfood == ysnake[5] && enablepart[5]) || 
                     (xfood == xsnake[6] && yfood == ysnake[6] && enablepart[6]) || 
                     (xfood == xsnake[7] && yfood == ysnake[7] && enablepart[7]) || 
                     (xfood == xsnake[8] && yfood == ysnake[8] && enablepart[8]) || 
                     (xfood == xsnake[9] && yfood == ysnake[9] && enablepart[9]) || 
                     (xfood == xsnake[10] && yfood == ysnake[10] && enablepart[10]) || 
                     (xfood == xsnake[11] && yfood == ysnake[11] && enablepart[11]) || 
                     (xfood == xsnake[12] && yfood == ysnake[12] && enablepart[12]) || 
                     (xfood == xsnake[13] && yfood == ysnake[13] && enablepart[13]) || 
                     (xfood == xsnake[14] && yfood == ysnake[14] && enablepart[14]) || 
                     (xfood == xsnake[15] && yfood == ysnake[15] && enablepart[15]) ||
                     (xfood == xsnake[16] && yfood == ysnake[16] && enablepart[16]) || 
                     (xfood == xsnake[17] && yfood == ysnake[17] && enablepart[17]) || 
                     (xfood == xsnake[18] && yfood == ysnake[18] && enablepart[18]) || 
                     (xfood == xsnake[19] && yfood == ysnake[19] && enablepart[19]); 
                     
assign flash_at_snake =  (xflash == xsnake[0] && yflash == ysnake[0] && enablepart[0]) ||
                     (xflash == xsnake[1] && yflash == ysnake[1] && enablepart[1]) || 
                     (xflash == xsnake[2] && yflash == ysnake[2] && enablepart[2]) || 
                     (xflash == xsnake[3] && yflash == ysnake[3] && enablepart[3]) || 
                     (xflash == xsnake[4] && yflash == ysnake[4] && enablepart[4]) || 
                     (xflash == xsnake[5] && yflash == ysnake[5] && enablepart[5]) || 
                     (xflash == xsnake[6] && yflash == ysnake[6] && enablepart[6]) || 
                     (xflash == xsnake[7] && yflash == ysnake[7] && enablepart[7]) || 
                     (xflash == xsnake[8] && yflash == ysnake[8] && enablepart[8]) || 
                     (xflash == xsnake[9] && yflash == ysnake[9] && enablepart[9]) || 
                     (xflash == xsnake[10] && yflash == ysnake[10] && enablepart[10]) || 
                     (xflash == xsnake[11] && yflash == ysnake[11] && enablepart[11]) || 
                     (xflash == xsnake[12] && yflash == ysnake[12] && enablepart[12]) || 
                     (xflash == xsnake[13] && yflash == ysnake[13] && enablepart[13]) || 
                     (xflash == xsnake[14] && yflash == ysnake[14] && enablepart[14]) || 
                     (xflash == xsnake[15] && yflash == ysnake[15] && enablepart[15]) ||
                     (xflash == xsnake[16] && yflash == ysnake[16] && enablepart[16]) || 
                     (xflash == xsnake[17] && yflash == ysnake[17] && enablepart[17]) || 
                     (xflash == xsnake[18] && yflash == ysnake[18] && enablepart[18]) || 
                     (xflash == xsnake[19] && yflash == ysnake[19] && enablepart[19]); 
                     
assign food_at_obstacle = obstacles[map_select][yfood*GRIDXNUM+xfood];
assign food_at_margin = xfood == 0 || xfood == GRIDXNUM-1 || yfood == 0 || yfood == GRIDYNUM-1;
assign food_at_flash = (xfood == xflash && yfood == yflash);
assign flash_at_obstacle = obstacles[map_select][yflash*GRIDXNUM+xflash];
assign flash_at_margin = xflash == 0 || xflash == GRIDXNUM-1 || yflash == 0 || yflash == GRIDYNUM-1;
assign food_region = (xcurrgrid == xfood) && (ycurrgrid == yfood);
assign food_shape_region = food[(pixel_y[9:1]%10)*10+(pixel_x[9:1]%10)];
assign flash_region = (xcurrgrid == xflash) && (ycurrgrid == yflash);
assign flash_shape_region = flash[(pixel_y[9:1]%10)*10+(pixel_x[9:1]%10)];
assign virus_region = (xcurrgrid == xvirus) && (ycurrgrid == yvirus);
assign virus_shape_region = virus[(pixel_y[9:1]%10)*10+(pixel_x[9:1]%10)];
assign ate = (xnexthead == xfood && ynexthead == yfood);
assign accelerate = (xnexthead == xflash && ynexthead == yflash);
assign poisoned = (xnexthead == xvirus && ynexthead == yvirus);
assign map_region = pixel_x >= MAPX<<1 && pixel_x < (MAPX + GRIDXNUM*GRIDLENGTH)<<1 &&
                    pixel_y >= MAPY<<1 && pixel_y < (MAPY + GRIDYNUM*GRIDLENGTH)<<1;

// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
always @(posedge clk) begin
    if(~reset_n)begin
        xfood <= INITIALX+10;
        yfood <= INITIALY;
        xflash <= INITIALX;
        yflash <= INITIALY+5;
        xvirus <= INITIALX+15;
        yvirus <= INITIALY-5;
        xrand <= 0;
        yrand <= 0;
        poison_flag <= 0;
    end
    else if (P == S_MAIN_PLAY1 || P == S_MAIN_PLAY2 || P == S_MAIN_PLAY3) begin
      if(food_at_snake || food_at_obstacle || food_at_margin || food_at_flash) begin
        xfood <= xrand % GRIDXNUM;
        yfood <= yrand % GRIDYNUM;
      end
      else if(flash_at_snake || flash_at_obstacle || flash_at_margin || food_at_flash) begin
        xflash <= xrand % GRIDXNUM;
        yflash <= yrand % GRIDYNUM;
      end
      else if(poisoned) begin
        xvirus <= 31;
        yvirus <= 22;
        poison_flag <= 1;
      end
      xrand <= xrand > 1000 ? 0 : xrand + 1;
      yrand <= yrand > 1000 ? 0 : yrand + 1;
    end

end

// ------------------------------------------------------------------------
integer idx;
always @(posedge clk) begin
  for(idx = 0;idx < 20; idx = idx + 1)
    enablepart[idx] <= idx < snakelength;
end
// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else begin
    if(P == S_MAIN_START || P == S_MAIN_WAIT) begin
      if(map_region) begin
        if((pixel_x[9:1]>=0&&pixel_x[9:1]<10&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=310&&pixel_x[9:1]<320&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=10&&pixel_y[9:1]<20) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=230&&pixel_y[9:1]<240))begin
            rgb_next<=12'h666;        
        end
        else if(pixel_y[9:1]>170 && pixel_y[9:1]<180 && pixel_x[9:1] >100 && pixel_x[9:1]<=109)begin
            rgb_next=12'hf00;
        end
        else if(margin && !grid_line) begin
          rgb_next = 12'h333;
        end
        else if(grid_line) begin
          rgb_next = 12'h666;
        end
        else if(start_region) begin
          rgb_next = 12'h7f7;
        end
        else begin
          rgb_next = 12'h555;
        end      
      end
      else if(digit_region)begin
        if(digit_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if(decimal_region)begin
        if(decimal_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if (score_region[0])begin
        if(score_shape_region[0])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[1])begin
        if(score_shape_region[1])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[2])begin
        if(score_shape_region[2])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[3])begin
        if(score_shape_region[3])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[4])begin
        if(score_shape_region[4])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[5])begin
        if(score_shape_region[5])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else begin
        rgb_next = 12'h000;
      end
    end
    else if(P == S_MAIN_PLAY1 || P == S_MAIN_PLAY2 || P == S_MAIN_PLAY3) begin
      if(map_region) begin
        if((pixel_x[9:1]>=0&&pixel_x[9:1]<10&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=310&&pixel_x[9:1]<320&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=10&&pixel_y[9:1]<20) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=230&&pixel_y[9:1]<240))begin
            rgb_next<=12'h666;        
        end
        else if(margin && !grid_line) begin
          rgb_next = 12'h333;
        end
        else if(grid_line) begin
          rgb_next = 12'h666;
        end
        else if(obstacle_region) begin
          rgb_next = 12'hffd;
        end
        else if(snake_region) begin
          if(poisoning) begin
            rgb_next = 12'h000+4*snake_clock[30:19];
          end
          else begin  
            rgb_next = 12'h7f7;
          end
        end
        else if(food_region) begin
          if(food_shape_region) begin
            rgb_next = 12'hf00;
          end
          else begin
            rgb_next = 12'h555;
          end
        end
        else if(flash_region) begin
          if(flash_shape_region) begin
            rgb_next = 12'hff0;
          end
          else begin
            rgb_next = 12'h555;
          end
        end
        else if(virus_region) begin
          if(virus_shape_region) begin
            rgb_next = 12'hfff;
          end
          else begin
            rgb_next = 12'h83b; 
          end
        end
        else begin
          rgb_next = 12'h555;
        end
      end
      else if(digit_region)begin
        if(digit_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if(decimal_region)begin
        if(decimal_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if (score_region[0])begin
        if(score_shape_region[0])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[1])begin
        if(score_shape_region[1])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[2])begin
        if(score_shape_region[2])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[3])begin
        if(score_shape_region[3])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[4])begin
        if(score_shape_region[4])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[5])begin
        if(score_shape_region[5])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else begin
        rgb_next = 12'h000;
      end
    end
    else if(P == S_MAIN_WIN) begin
      if(map_region) begin
        if((pixel_x[9:1]>=0&&pixel_x[9:1]<10&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=310&&pixel_x[9:1]<320&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=10&&pixel_y[9:1]<20) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=230&&pixel_y[9:1]<240))begin
            rgb_next<=12'h666;        
        end
        
        else if(margin && !grid_line) begin
          rgb_next = 12'h333;
        end
        else if(grid_line) begin
          rgb_next = 12'h666;
        end
        else if(win_region) begin
          rgb_next = 12'hfd0;
        end
        else begin
          rgb_next = 12'h555;
        end      
      end
      else if(digit_region)begin
        if(digit_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if(decimal_region)begin
        if(decimal_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if (score_region[0])begin
        if(score_shape_region[0])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[1])begin
        if(score_shape_region[1])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[2])begin
        if(score_shape_region[2])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[3])begin
        if(score_shape_region[3])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[4])begin
        if(score_shape_region[4])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[5])begin
        if(score_shape_region[5])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else begin
        rgb_next = 12'h000;
      end    
    end
    else if(P == S_MAIN_DEAD) begin
      if(map_region) begin
        if((pixel_x[9:1]>=0&&pixel_x[9:1]<10&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=310&&pixel_x[9:1]<320&&pixel_y[9:1]>=120&&pixel_y[9:1]<130) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=10&&pixel_y[9:1]<20) ||
            (pixel_x[9:1]>=150&&pixel_x[9:1]<160&&pixel_y[9:1]>=230&&pixel_y[9:1]<240))begin
            rgb_next<=12'h666;        
        end
        else if(margin && !grid_line) begin
          rgb_next = 12'h333;
        end
        else if(grid_line) begin
          rgb_next = 12'h666;
        end
        else if(dead_region) begin
          rgb_next = 12'hfcc;
        end
        else begin
          rgb_next = 12'h555;
        end      
      end
      else if(digit_region)begin
        if(digit_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if(decimal_region)begin
        if(decimal_shape_region)begin
            rgb_next=12'hfff;
        end      
        else rgb_next=12'h000;
      end
      else if (score_region[0])begin
        if(score_shape_region[0])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[1])begin
        if(score_shape_region[1])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[2])begin
        if(score_shape_region[2])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[3])begin
        if(score_shape_region[3])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[4])begin
        if(score_shape_region[4])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else if (score_region[5])begin
        if(score_shape_region[5])rgb_next=12'hfff;
        else rgb_next=12'h000;
      end
      else begin
        rgb_next = 12'h000;
      end    
    end
  end
end
// End of the video data display code.
// ------------------------------------------------------------------------
endmodule
