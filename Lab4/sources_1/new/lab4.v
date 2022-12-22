`timescale 1ns / 1ps
module lab4(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

reg signed[3:0]counter=4'b0000;//計算加減
//wire [3:0]de;
reg [3:0]tmp;//記錄前一次按下按鍵   用以避免長按會有多次輸入信號
reg [3:0]mix;//用來丟給led
reg [31:0]bounce;//加一個超大數字 用來延遲
reg [2:0]brightness = 3'b000;

assign usr_led = mix;


pwm bright(brightness,clk,light);

always @(posedge clk)begin
    if(light==1)begin
        mix<=counter;
    end
    else if(light==0)begin
        mix=0;
    end
    if(!reset_n)begin
        counter=4'b0000;
        mix=4'b0000;
        bounce=0;
    end
    bounce<=bounce+1;
    tmp<=usr_btn;
    if(usr_btn[0]==1'b1 && usr_btn[0]!=tmp[0] && bounce>'d20000000)begin
        bounce<=0;
        if(counter==4'b1000)begin
            counter<=4'b1000;
        end
        else begin
            counter<=counter-4'b0001;
        end
    end    
    if(usr_btn[1]==1'b1 && usr_btn[1]!=tmp[1] && bounce>'d20000000)begin
        bounce<=0;
        if(counter==4'b0111)begin
            counter<=4'b0111;
        end
        else begin
            counter<=counter+4'b0001;
        end
    end
    
    if(usr_btn[2]==1 && usr_btn[2]!=tmp[2])begin
        brightness<=brightness-3'b001;
        if(brightness==3'b000)begin
            brightness<=3'b000;
        end
    end
    
    if(usr_btn[3]==1 && usr_btn[3]!=tmp[3])begin
        brightness<=brightness+3'b001;
        if(brightness==3'b100)begin
            brightness<=3'b100;
        end
    end
    
end

endmodule


module pwm(
    input [2:0]brightness,
    input clk,
    output reg light
    );
    reg [30:0]ticks;


//1000000為單位 在同個mode下 超過一定clk就變暗 => 越大clk(頻率)亮度變化越明顯
always@(posedge clk)begin
    
    ticks<=ticks+1'b1;
    if(brightness==3'b000 && ticks>='d50000)begin
        light<=0;
    end
    else if(brightness==3'b001 && ticks>='d250000)begin
        light<=0;
    end
    else if(brightness==3'b010 && ticks>='d500000)begin
        light<=0;
    end
    else if(brightness==3'b011 && ticks>='d750000)begin
        light<=0;
    end
    else if(brightness==3'b100 && ticks>='d1000000)begin
        light<=0;
    end
    else begin
        light<=1;
    end    
    if(ticks>=1000000)begin
       ticks<=0;
    end
  end

    
    
endmodule