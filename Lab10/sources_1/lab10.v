`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
//
// Create Date: 2018/12/11 16:04:41
// Design Name:
// Module Name: lab9
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
 
module lab10(
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
 
// Declare system variables

wire [3:0]  btn_level, btn_pressed;
reg  [3:0]  prev_btn_level;


reg  [31:0] fish1_clock;
wire [9:0]  pos1;
wire        fish1_region;

reg  [31:0] fish2_clock;
wire [9:0]  pos2;
wire        fish2_region;

reg  [31:0] fish3_clock;
wire [9:0]  pos3;
wire        fish3_region;


reg  [31:0] fish4_clock;
wire [9:0]  pos4;
wire        fish4_region;

reg  [31:0] fish5_clock;
wire [9:0]  pos5;
wire        fish5_region;

reg  [31:0] dog_clock;
wire [9:0]  posdog;
wire        dog_region;

reg  [31:0] ldv_clock;
wire [9:0]  posldv;
wire        ldv_region;

 
// declare SRAM control signals
wire [16:0] sram_addr;
wire [16:0] sram_addr_fish1;
wire [16:0] sram_addr_fish2;
wire [16:0] sram_addr_fish3;
wire [16:0] sram_addr_fish4;
wire [16:0] sram_addr_fish5;
wire [16:0] sram_addr_dog;
wire [16:0] sram_addr_ldv;


wire [11:0] data_in;
wire [11:0] data_out;
wire [11:0] data_out_fish1;
wire [11:0] data_out_fish2;
wire [11:0] data_out_fish3;
wire [11:0] data_out_fish4;
wire [11:0] data_out_fish5;
wire [11:0] data_out_ldv;
wire [11:0] data_out_dog;


wire        sram_we, sram_en;
 
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
reg  [17:0] pixel_addr_fish1;
reg  [17:0] pixel_addr_fish2;
reg  [17:0] pixel_addr_fish3;
reg  [17:0] pixel_addr_fish4;
reg  [17:0] pixel_addr_fish5;
reg  [17:0] pixel_addr_ldv;
reg  [17:0] pixel_addr_dog;
 
// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height
 
// Set parameters for the fish images
localparam FISH1_VPOS   = 64; // Vertical location of the fish in the sea image.
localparam FISH1_W      = 64; // Width of the fish.
localparam FISH1_H      = 32; // Height of the fish.
reg [17:0] fish1_addr[0:7];   // Address array for up to 8 fish images.


localparam FISH2_VPOS   = 120; // Vertical location of the fish in the sea image.
localparam FISH2_W      = 64; // Width of the fish.
localparam FISH2_H      = 44; // Height of the fish.
reg [17:0] fish2_addr[0:7];

localparam FISH3_VPOS   = 20; // Vertical location of the fish in the sea image.
localparam FISH3_W      = 64; // Width of the fish.
localparam FISH3_H      = 72; // Height of the fish.
reg [17:0] fish3_addr[0:7];

localparam dog_VPOS   = 180; // Vertical location of the fish in the sea image.
localparam dog_W      = 220; // Width of the fish.
localparam dog_H      = 220; // Height of the fish.
reg [17:0] dog_addr[0:7];


localparam FISH4_VPOS   = 170; // Vertical location of the fish in the sea image.
localparam FISH4_W      = 64; // Width of the fish.
localparam FISH4_H      = 72; // Height of the fish.
reg [17:0] fish4_addr[0:7];

localparam FISH5_VPOS   = 150; // Vertical location of the fish in the sea image.
localparam FISH5_W      = 64; // Width of the fish.
localparam FISH5_H      = 32; // Height of the fish.
reg [17:0] fish5_addr[0:7];  

localparam ldv_VPOS   = 100; // Vertical location of the fish in the sea image.
localparam ldv_W      = 64; // Width of the fish.
localparam ldv_H      = 73; // Height of the fish.
reg [17:0] ldv_addr[0:7];

reg[30:0]cnt;



always @(posedge clk) begin
    
    if(~reset_n)flag<=0;
    if(btn_pressed[2])cnt<=cnt+1;

end


reg [30:0]t;


always @(posedge clk) begin
    
    if(~reset_n)t<=0;
    if(btn_pressed[0])t<=t+1;

end





always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

reg[1:0]flag;


function [11:0] change; 
    input[11:0]init;
    if(cnt%5==1)begin
        change={init[11:8]>>2,init[7:4]<<1,init[3:0]<<1};
    end
    else if(cnt%5==2 )begin
        change={init[11:8]>>1,init[7:4]>>1,init[3:0]<<2};
    end
    else if(cnt%5==3  )begin
        change={init[11:8]>>2,init[7:4],init[3:0]<<2};
    end
    else if(cnt%5==4 || t%2==1)begin
        change={init[11:8],init[7:4]>>1,init[3:0]<<1};
    end
    
    else if(t%2==0)begin
        change=init;
    end
    
    else change=init;

endfunction

assign btn_pressed = (btn_level & ~prev_btn_level);

 
// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(
initial begin
  fish1_addr[0] =  18'd0;         /* Addr for fish image #1 */
  fish1_addr[1] =  FISH1_W*FISH1_H; /* Addr for fish image #2 */
  fish1_addr[2] =  FISH1_W*FISH1_H*2; /* Addr for fish image #2 */
  fish1_addr[3] =  FISH1_W*FISH1_H*3; /* Addr for fish image #2 */
  fish1_addr[4] =  FISH1_W*FISH1_H*4; /* Addr for fish image #2 */
  fish1_addr[5] =  FISH1_W*FISH1_H*5; /* Addr for fish image #2 */
  fish1_addr[6] =  FISH1_W*FISH1_H*6; /* Addr for fish image #2 */
  fish1_addr[7] =  FISH1_W*FISH1_H*7; /* Addr for fish image #2 */
  
  
  fish2_addr[0] =  18'd0;         /* Addr for fish image #1 */
  fish2_addr[1] =  FISH2_W*FISH2_H; /* Addr for fish image #2 */
  fish2_addr[2] =  FISH2_W*FISH2_H*2; /* Addr for fish image #2 */
  fish2_addr[3] =  FISH2_W*FISH2_H*3; /* Addr for fish image #2 */
  //fish2_addr[4] =  FISH2_W*FISH2_H*4; /* Addr for fish image #2 */
  //fish2_addr[5] =  FISH2_W*FISH2_H*5; /* Addr for fish image #2 */
  //fish2_addr[6] =  FISH2_W*FISH2_H*6; /* Addr for fish image #2 */
  //fish2_addr[7] =  FISH2_W*FISH2_H*7; /* Addr for fish image #2 */
  
  fish3_addr[0] =  18'd0;         /* Addr for fish image #1 */
  fish3_addr[1] =  FISH3_W*FISH3_H; /* Addr for fish image #2 */
  fish3_addr[2] =  FISH3_W*FISH3_H*2; /* Addr for fish image #2 */
  fish3_addr[3] =  FISH3_W*FISH3_H*3; /* Addr for fish image #2 */
  //fish3_addr[4] =  FISH3_W*FISH3_H*4; /* Addr for fish image #2 */
  //fish3_addr[5] =  FISH3_W*FISH3_H*5; /* Addr for fish image #2 */
  //fish3_addr[6] =  FISH3_W*FISH3_H*6; /* Addr for fish image #2 */
  //fish3_addr[7] =  FISH3_W*FISH3_H*7; /* Addr for fish image #2 */
  
  
  
  fish4_addr[0] =  18'd0;         /* Addr for fish image #1 */
  fish4_addr[1] =  FISH4_W*FISH4_H; /* Addr for fish image #2 */
  fish4_addr[2] =  FISH4_W*FISH4_H*2; /* Addr for fish image #2 */
  fish4_addr[3] =  FISH4_W*FISH4_H*3; /* Addr for fish image #2 */
  //fish3_addr[4] =  FISH3_W*FISH3_H*4; /* Addr for fish image #2 */
  //fish3_addr[5] =  FISH3_W*FISH3_H*5; /* Addr for fish image #2 */
  //fish3_addr[6] =  FISH3_W*FISH3_H*6; /* Addr for fish image #2 */
  //fish3_addr[7] =  FISH3_W*FISH3_H*7; /* Addr for fish image #2 */
  
  
  fish5_addr[0] =  18'd0;         /* Addr for fish image #1 */
  fish5_addr[1] =  FISH5_W*FISH5_H; /* Addr for fish image #2 */
  fish5_addr[2] =  FISH5_W*FISH5_H*2; /* Addr for fish image #2 */
  fish5_addr[3] =  FISH5_W*FISH5_H*3;
  
  
  ldv_addr[0] =  18'd0;      
  
  dog_addr[0] =  18'd0;         /* Addr for fish image #1 */
  dog_addr[1] =  dog_W*dog_H; /* Addr for fish image #2 */
  //dog_addr[2] =  dog_W*dog_H*2; /* Addr for fish image #2 */
  //dog_addr[3] =  dog_W*dog_H*3; /* Addr for fish image #2 */
  //dog_addr[4] =  dog_W*dog_H*4; /* Addr for fish image #2 */
  //dog_addr[5] =  dog_W*dog_H*5; /* Addr for fish image #2 */
  //dog_addr[6] =  dog_W*dog_H*6; /* Addr for fish image #2 */
 // dog_addr[7] =  dog_W*dog_H*7; /* Addr for fish image #2 */
  
  
  
  
  
  
  
end
 
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
 
 
 
 //assign FISH4_VPOS=FISH4_VPOS+fish4_clock[0]*10;
 
 
// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.
sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H+FISH1_W*FISH1_H*2))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));
          
       
       
//fish1
sram_fish1 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH1_W*FISH1_H*8))
  ram_fish1 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish1), .data_i(data_in), .data_o(data_out_fish1));
          
assign sram_addr_fish1 = (fish1_region)?pixel_addr_fish1:pixel_addr_fish5;       


sram_fish2 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH2_W*FISH2_H*4))
  ram_fish2 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish2), .data_i(data_in), .data_o(data_out_fish2));
          
assign sram_addr_fish2 = pixel_addr_fish2;


sram_fish3 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(FISH3_W*FISH3_H*4))
  ram_fish3 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_fish3 ), .data_i(data_in), .data_o(data_out_fish3));
          
assign sram_addr_fish3 = (fish3_region)?pixel_addr_fish3: pixel_addr_fish4;

sram_ldv #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(ldv_W*ldv_H))
  ram_ldv (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_ldv ), .data_i(data_in), .data_o(data_out_ldv));
          
assign sram_addr_ldv = pixel_addr_ldv;


/*
sram_dog #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(dog_W*dog_H))
  ram_dog (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_dog), .data_i(data_in), .data_o(data_out_dog));
          
assign sram_addr_dog = pixel_addr_dog; 
*/

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------


 
// VGA color pixel generator
//assign {VGA_RED, VGA_GREEN, VGA_BLUE} = (!flag) ? rgb_reg:{rgb_reg[7:4],rgb_reg[3:0],rgb_reg[11:8]};
 assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;
// ------------------------------------------------------------------------
// An animation clock for the motion of the fish, upper bits of the
// fish clock is the x position of the fish on the VGA screen.
// Note that the fish will move one screen pixel every 2^20 clock cycles,
// or 10.49 msec
assign pos5=(t%2==0)?fish5_clock[31:20]*3:fish5_clock[31:20]*15; // the x position of the right edge of the fish image

assign posldv=(t%2==0)?0 :VBUF_W+fish1_clock[31:25]*10; // the x position of the right edge of the fish image
//assign posldv=VBUF_W; // the x position of the right edge of the fish image
always @(posedge clk) begin
  if (~reset_n || fish5_clock[31:21] > VBUF_W + 3*FISH5_W)
    fish5_clock <= 0;
  else
    fish5_clock <= fish5_clock + 1;
end


assign pos1 = (t%2==0)?fish1_clock[31:20]:fish1_clock[31:20]*10; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
always @(posedge clk) begin
  if (~reset_n || fish1_clock[31:21] > VBUF_W + FISH1_W)
    fish1_clock <= 0;
  else
    fish1_clock <= fish1_clock + 1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------

assign pos2 = (t%2==0)? fish2_clock[31:19]:fish2_clock[31:19]*10; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
always @(posedge clk) begin
  if (~reset_n || fish2_clock[31:21] > VBUF_W + 2*FISH2_W)
    fish2_clock <= 0;
  else
    fish2_clock <= fish2_clock + 1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------
 assign pos4 = (t%2==0)? 2*VBUF_W+2*FISH4_W-fish1_clock[31:20]:8*(2*VBUF_W+2*FISH4_W-fish1_clock[31:20]);
//assign pos3 = VBUF_W-fish3_clock[31:20]; // the x position of the right edge of the fish image
assign pos3 = (t%2==0)?8*(2*VBUF_W+2*FISH3_W-fish3_clock[31:20]):16*(2*VBUF_W+2*FISH3_W-fish3_clock[31:20]);
//assign pos3 = VBUF_W-pos1; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
always @(posedge clk) begin
  if(fish3_clock[31:20]==VBUF_W)begin
    fish3_clock<=0;
  end
  if (~reset_n || fish3_clock[31:21] > VBUF_W + 2*FISH3_W)
    fish3_clock <= 0;
  else
    fish3_clock <= fish3_clock + 1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------
 


assign posdog = dog_clock[31:20]; // the x position of the right edge of the fish image
                                // in the 640x480 VGA screen
always @(posedge clk) begin
  if (~reset_n || dog_clock[31:21] > VBUF_W + FISH1_W)
    dog_clock <= 0;
  else
    dog_clock <= dog_clock + 1;
end
// End of the animation clock code.
// ------------------------------------------------------------------------
 






 
// ------------------------------------------------------------------------
// Video frame buffer address generation unit (AGU) with scaling control
// Note that the width x height of the fish image is 64x32, when scaled-up
// on the screen, it becomes 128x64. 'pos' specifies the right edge of the
// fish image.
assign fish1_region =
           pixel_y >= (FISH1_VPOS<<1) && pixel_y < (FISH1_VPOS+FISH1_H)<<1 &&
           (pixel_x + 127) >= pos1 && pixel_x < pos1 + 1;
 
assign fish2_region =
           pixel_y >= (FISH2_VPOS<<1) && pixel_y < (FISH2_VPOS+FISH2_H)<<1 &&
           (pixel_x + 127) >= pos2 && pixel_x < pos2 + 1;

assign fish3_region =
           pixel_y >= (FISH3_VPOS<<1) && pixel_y < (FISH3_VPOS+FISH3_H)<<1 &&
           (pixel_x + 127) >= pos3 && pixel_x < pos3 + 1;

assign fish4_region =
           pixel_y >= (FISH4_VPOS<<1) && pixel_y < (FISH4_VPOS+FISH4_H)<<1 &&
           (pixel_x + 127) >= pos4 && pixel_x < pos4 + 1;

assign fish5_region =
           pixel_y >= (FISH5_VPOS<<1) && pixel_y < (FISH5_VPOS+FISH5_H)<<1 &&
           (pixel_x + 127) >= pos5 && pixel_x < pos5 + 1;

assign dog_region =
           pixel_y >= (dog_VPOS<<1) && pixel_y < (dog_VPOS+dog_H)<<1 &&
           (pixel_x + 127) >= posdog && pixel_x < posdog + 1;

assign ldv_region =
           pixel_y >= (ldv_VPOS<<1) && pixel_y < (ldv_VPOS+ldv_H)<<1 &&
           (pixel_x + 127) >= posldv && pixel_x < posldv + 1;
 
always @ (posedge clk) begin
  if (~reset_n)begin
    pixel_addr<=0;
    pixel_addr_fish1 <= 0;
    pixel_addr_fish2 <= 0;
    pixel_addr_fish3 <= 0;
    pixel_addr_fish4 <= 0;
    pixel_addr_fish5 <= 0;
    pixel_addr_ldv <= 0;
    end
  else if (fish1_region ||  fish2_region || fish3_region ||  fish4_region || fish5_region || ldv_region )begin
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);

    pixel_addr_fish1 <= fish1_addr[fish1_clock[25:23]] +
                  ((pixel_y>>1)-FISH1_VPOS)*FISH1_W +
                  ((pixel_x +(FISH1_W*2-1)-pos1)>>1);
                  
    pixel_addr_fish2 <= fish2_addr[fish2_clock[25:23]] +
                  ((pixel_y>>1)-FISH2_VPOS)*FISH2_W +
                  ((pixel_x +(FISH2_W*2-1)-pos2)>>1);                  
                  
    pixel_addr_fish3 <= fish3_addr[fish3_clock[25:23]] +
                  ((pixel_y>>1)-FISH3_VPOS)*FISH3_W +
                  ((pixel_x +(FISH3_W*2-1)-pos3)>>1);
                  
    pixel_addr_fish4 <= fish3_addr[fish3_clock[25:23]] +
                  ((pixel_y>>1)-FISH4_VPOS)*FISH4_W +
                  ((pixel_x +(FISH4_W*2-1)-pos4)>>1);

    pixel_addr_fish5 <= fish1_addr[fish1_clock[25:23]] +
                  ((pixel_y>>1)-FISH5_VPOS)*FISH5_W +
                  ((pixel_x +(FISH5_W*2-1)-pos5)>>1);
    pixel_addr_ldv <= ldv_addr[0] +
                  ((pixel_y>>1)-ldv_VPOS)*ldv_W +
                  ((pixel_x +(ldv_W*2-1)-posldv)>>1);

                
    pixel_addr_dog <= dog_addr[dog_clock[25:23]] +
                  ((pixel_y>>1)-dog_VPOS)*dog_W +
                  ((pixel_x +(dog_W*2-1)-posdog)>>1);
                
    end
  else begin
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
    end
end
// End of the AGU code.
// ------------------------------------------------------------------------
 
// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end
 
always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else begin
    if(fish1_region && data_out_fish1 != 12'h1f1)begin
      rgb_next = data_out_fish1;
    end
    
    else if(fish2_region && data_out_fish2 != 12'h1f1)begin
      rgb_next = data_out_fish2;
    end
    
    else if(fish3_region && data_out_fish3 != 12'h1f1)begin
      rgb_next = data_out_fish3;
    end
    
    else if(fish4_region && data_out_fish3 != 12'h1f1)begin
      rgb_next = data_out_fish3;
    end
    
    else if(fish5_region && data_out_fish1 != 12'h1f1)begin
      rgb_next = data_out_fish1;
    end
    
    /*else if(ldv_region && data_out_ldv > 12'h353)begin
      rgb_next = data_out_ldv;
    end*/
    
    else if(ldv_region && data_out_ldv != 12'h0f0  && data_out_ldv != 12'h3f0 
    && data_out_ldv != 12'h0f3 && data_out_ldv != 12'h3f3 && data_out_ldv != 12'h003 
    && data_out_ldv != 12'h0a0 && data_out_ldv != 12'h303 && data_out_ldv != 12'h000
    && data_out_ldv != 12'h020  && data_out_ldv != 12'h023&& data_out_ldv != 12'h320 
    && data_out_ldv != 12'h080  && data_out_ldv != 12'h350&& data_out_ldv != 12'h353 
    && data_out_ldv != 12'h300 && data_out_ldv != 12'h0d3 && data_out_ldv != 12'h050 
    && data_out_ldv != 12'h0d0 && data_out_ldv != 12'h3a0 && data_out_ldv != 12'h3d0
    && data_out_ldv != 12'h083 )begin
      rgb_next = data_out_ldv;
    end
    
    /*else if(dog_region && data_out_dog != 12'h1f1)begin
      rgb_next = data_out_dog;
    end
    */
    
    else  rgb_next = change(data_out); // RGB value at (pixel_x, pixel_y)
  end
end
// End of the video data display code.
// ------------------------------------------------------------------------
 
endmodule
 
 
 

