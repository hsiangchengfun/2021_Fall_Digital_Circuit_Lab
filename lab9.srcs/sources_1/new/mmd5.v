`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/12/05 15:29:12
// Design Name: 
// Module Name: mmd5
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

module mmd5(
  input clk,
  input reset,
  input [63:0]guess,
  input [6:0]itr,
  
  input [4:0] r,
  input [31:0] k,

  output cracked
);

reg [0:127] passwd_hash = 128'hE8CD0953ABDFDE433DFEC7FAA70DF7F6;


reg [0:127] md5_guess = 0;

assign cracked = (md5_guess==passwd_hash);





reg [31:0]a;//h0
reg [31:0]b;//h1
reg [31:0]c;//h2
reg [31:0]d;//h3

reg [6:0] nextitr;

reg [31:0]f;
reg [31:0]g;

wire [31:0]w[1:0];


assign w[0]={
  guess[39:32],
  guess[47:40],
  guess[55:48],
  guess[63:56]
};

assign w[1]={
  guess[7:0],
  guess[15:8],
  guess[23:16],
  guess[31:24]
};


function [31:0]leftrotate;
  input [31:0]x;
  input [4:0] c;
  begin
    leftrotate=((x) << (c)) | ((x) >> (32 - (c)));
  end
endfunction



integer j;

always @(posedge clk ) begin

  if(~reset)begin
  md5_guess<=0;
  nextitr <= 1;
  a<=32'h67452301;
  b<=32'hefcdab89;
  c<=32'h98badcfe;
  d<=32'h10325476;
  end

  else if(itr==nextitr)begin
    
    
    if(itr<=67)nextitr<=itr+1;
    else nextitr<=0;
    
    if(itr==0)begin
      a<=32'h67452301;
      b<=32'hefcdab89;
      c<=32'h98badcfe;
      d<=32'h10325476;
    end

    else if(itr>0 && itr<65)begin

      if(itr<=16)begin
        f = (b & c) | ((~b) & d);
        g = itr-1;
      end

      else if(itr<=32)begin
        f = (d & b) | ((~d) & c);
        g = (5*(itr-1)+1 ) & 32'd15;
      end
      
      else if(itr<=48)begin
        f = b ^ c ^ d;
        g = (3*(itr-1) +5) & 32'd15;
      end
      
      else if(itr<=64)begin
        f = c ^ (b | (~d));
        g = (7*(itr-1)) & 32'd15;
      end
      
      d <= c;
      c <= b;
      b <= b + leftrotate((a + f + k + ((g<=1)? w[g]:((g==2)? 128 : ((g==14)? 32'd64:0)))), r);//w[14]=64
      a <= d;

    end 
    



    if( itr == 65 )begin
      a<= 32'h67452301 + a;
      b<= 32'hefcdab89 + b;
      c<= 32'h98badcfe + c;
      d<= 32'h10325476 + d;
    end 
    

    if( itr == 66 )begin
      for( j = 0 ; j < 4 ; j = j+1 )begin
        md5_guess[8*(j+0)+:8]<=a[8*j+:8];
        md5_guess[8*(j+4)+:8]<=b[8*j+:8];
        md5_guess[8*(j+8)+:8]<=c[8*j+:8];
        md5_guess[8*(j+12)+:8]<=d[8*j+:8];
      end
    end 
    

  end
end

endmodule