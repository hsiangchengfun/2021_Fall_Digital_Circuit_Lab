`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/05 23:34:19
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



module lab9(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);




wire [3:0]  btn_level, btn_pressed;
reg  [3:0]  prev_btn_level;

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level[3])
);




always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

//parameters
localparam [2:0]  S_MAIN_WAIT=0,S_MAIN_CRACK=1,S_MAIN_SHOW=2,S_MAIN_INIT=3;


localparam [4:0] NUMOFMD5=5'd20;

localparam [$clog2(100000000):0] MD5_START_GAP = 100000000/NUMOFMD5;


reg [2:0] P=0,P_next=0;




//cracker vars
reg [4:0] r[0:63];
reg [31:0] k [0:63];



reg [6:0]itr;
wire [19:0]cracked;
reg [20:0]cracked_ptr;
wire done;


wire [63:0] answer;

reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "Crack           "; // Initialize the text of the second row.


wire [4:0] rchoose;
wire [31:0] kchoose;


reg [55:0]cnt;
reg [20:0]clock;




function [63:0]toascandadd;
  input [63:0]ascipt;
  integer i;
  begin
    toascandadd=ascipt+1;
    for(i=0;i<7;i=i+1)begin
      if(toascandadd[8*i+:8]==("9"+1))begin//if == 9+1
        toascandadd[8*i+:8]="0";//to 0
        toascandadd[(8*(i+1))+:8]=toascandadd[(8*(i+1))+:8]+1;
      end
    end
  end
endfunction



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


always @(posedge clk) begin
  if(~reset_n) begin
    r[0] <= 7;      r[1] <= 12;     r[2] <= 17;     r[3] <= 22;     
    r[4] <= 7;      r[5] <= 12;     r[6] <= 17;     r[7] <= 22;     
    r[8] <= 7;      r[9] <= 12;     r[10] <= 17;    r[11] <= 22;    
    r[12] <= 7;     r[13] <= 12;    r[14] <= 17;    r[15] <= 22;    
    r[16] <= 5;     r[17] <= 9;     r[18] <= 14;    r[19] <= 20;    
    r[20] <= 5;     r[21] <= 9;     r[22] <= 14;    r[23] <= 20;    
    r[24] <= 5;     r[25] <= 9;     r[26] <= 14;    r[27] <= 20;    
    r[28] <= 5;     r[29] <= 9;     r[30] <= 14;    r[31] <= 20;    
    r[32] <= 4;     r[33] <= 11;    r[34] <= 16;    r[35] <= 23;
    r[36] <= 4;     r[37] <= 11;    r[38] <= 16;    r[39] <= 23;
    r[40] <= 4;     r[41] <= 11;    r[42] <= 16;    r[43] <= 23;
    r[44] <= 4;     r[45] <= 11;    r[46] <= 16;    r[47] <= 23;    
    r[48] <= 6;     r[49] <= 10;    r[50] <= 15;    r[51] <= 21;
    r[52] <= 6;     r[53] <= 10;    r[54] <= 15;    r[55] <= 21;
    r[56] <= 6;     r[57] <= 10;    r[58] <= 15;    r[59] <= 21;
    r[60] <= 6;     r[61] <= 10;    r[62] <= 15;    r[63] <= 21;
  end
end


always @(posedge clk) begin
  if(~reset_n) begin
    k[0] <= -680876936;     k[1] <= -389564586;     k[2] <= 606105819;      k[3] <= -1044525330;    
    k[4] <= -176418897;     k[5] <= 1200080426;     k[6] <= -1473231341;    k[7] <= -45705983;
    k[8] <= 1770035416;     k[9] <= -1958414417;    k[10] <= -42063;        k[11] <= -1990404162;   
    k[12] <= 1804603682;    k[13] <= -40341101;     k[14] <= -1502002290;   k[15] <= 1236535329;
    k[16] <= -165796510;    k[17] <= -1069501632;   k[18] <= 643717713;     k[19] <= -373897302;
    k[20] <= -701558691;    k[21] <= 38016083;      k[22] <= -660478335;    k[23] <= -405537848;
    k[24] <= 568446438;     k[25] <= -1019803690;   k[26] <= -187363961;    k[27] <= 1163531501;
    k[28] <= -1444681467;   k[29] <= -51403784;     k[30] <= 1735328473;    k[31] <= -1926607734;
    k[32] <= -378558;       k[33] <= -2022574463;   k[34] <= 1839030562;    k[35] <= -35309556;
    k[36] <= -1530992060;   k[37] <= 1272893353;    k[38] <= -155497632;    k[39] <= -1094730640;
    k[40] <= 681279174;     k[41] <= -358537222;    k[42] <= -722521979;    k[43] <= 76029189;
    k[44] <= -640364487;    k[45] <= -421815835;    k[46] <= 530742520;     k[47] <= -995338651;
    k[48] <= -198630844;    k[49] <= 1126891415;    k[50] <= -1416354905;   k[51] <= -57434055;
    k[52] <= 1700485571;    k[53] <= -1894986606;   k[54] <= -1051523;      k[55] <= -2054922799;
    k[56] <= 1873313359;    k[57] <= -30611744;     k[58] <= -1560198380;   k[59] <= 1309151649;
    k[60] <= -145523070;    k[61] <= -1120210379;   k[62] <= 718787259;     k[63] <= -343485551;
  end
end



assign answer = try[cracked_ptr];
assign usr_led[2] = (P==S_MAIN_INIT || P==S_MAIN_SHOW);
assign usr_led[1] = (P==S_MAIN_INIT || P==S_MAIN_CRACK);
assign usr_led[0] = (P==S_MAIN_INIT || P==S_MAIN_WAIT);
assign usr_led[3]=1;



always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end



always @(posedge clk ) begin
  
  if(~reset_n)begin
    
    itr<=0;
  end
  
  else if(~done)begin
    
    if(itr<=67)itr<=itr+1;
    else itr<=0;


  end

end

always @(*) begin 
  case (P)

    S_MAIN_INIT:

      #200
      P_next<=S_MAIN_WAIT;
    
    S_MAIN_WAIT:
    
      if(btn_pressed) begin
        P_next<=S_MAIN_CRACK;
      end
      else P_next<=S_MAIN_WAIT;
    
    S_MAIN_CRACK:
    
      if(done) begin
        P_next<=S_MAIN_SHOW;
      end
      else P_next<=S_MAIN_CRACK;
    
    S_MAIN_SHOW:
    
      P_next<=S_MAIN_SHOW;
    
  endcase
end









always @(posedge clk ) begin
  
  if(~reset_n)begin
    clock<=0;
    cnt<="0000000";
  end
  
  else if(P==S_MAIN_CRACK) begin
    if(clock==1000000)begin
      clock<=0;
      cnt<=toascandadd(cnt);
    end
    else clock<=clock+1;
    

  end
  else if(P==S_MAIN_SHOW)begin
    
  end

end





always @(posedge clk ) begin
  if(~reset_n)begin
    row_A <= "Press BTN3 to   ";
    row_B <= "Crack           ";
  end
  else if(P==S_MAIN_CRACK || P==S_MAIN_SHOW) begin
    row_A <= {"Passwd: ",answer};
    row_B <= {"Time: ",cnt," ms"};

  end
end





reg [63:0]try[0:19];
reg [63:0] tmp;


integer j,num;


always @(posedge clk ) begin
  if(~reset_n)begin
    try[0]="00000000";
    for( j = 1 ; j < 20 ; j = j + 1 )begin
      
      num=j*MD5_START_GAP;
    
      $sformat(tmp,"%0d",num);

      try[j]=tmp;

    
    end
  
  end
  
  else if(P==S_MAIN_CRACK && itr==68 && ~done)begin
    
    for( j = 0 ; j < 20 ; j = j + 1 )begin
      
      try[j]<=toascandadd(try[j]);
    
    end
  
  end

end




assign done = |cracked;

integer slct;


always @(cracked)begin
  for(slct=0;slct<20;slct=slct+1)begin
    if(cracked[slct])begin
      cracked_ptr = slct;
    end
  end
end




assign rchoose = r[(itr>0 && itr<65)? itr-1:63];
assign kchoose = k[(itr>0 && itr<65)? itr-1:63];

generate
genvar i;
for( i = 0 ; i < 20 ; i = i + 1 )begin:crackers
  mmd5 crackers(
    .clk(clk),
    .reset(reset_n),
    .guess(try[i]),
    .itr(itr),
    .r(rchoose),
    .k(kchoose),
    .cracked(cracked[i])
  );
end
endgenerate


endmodule









