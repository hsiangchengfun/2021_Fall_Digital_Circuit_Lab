`timescale 1ns / 1ps
/////////////////////////////////////////////////////////
module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.."; // Initialize the text of the second row.
reg [399:0] fibonacci;

reg [15:0] num[24:0];
reg [5:0] count=0;
reg sign;



function [7:0] ashex;
    input [3:0] num;
    begin
        if(num <= 9 &&  num>=0)begin
            ashex = num+48;
        end
        else begin
            ashex = num-10+65;
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
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);


integer j;
reg [7:0]countA=0,countB=1;
reg flag = 0;//add mode or sub mode
reg bool = 0;//test if is the first time press
reg bpsed = 0;
reg switch = 0;
reg [29:0] bounce;
  
always @(posedge clk) begin
  if (~bpsed || ~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
    flag = 0;
    bool = 0;
    bpsed = 0;
    switch = 0;
    countA = 25;
    countB = 1;
    fibonacci[15:0]=0;
    fibonacci[31:16]=1;
    bounce = 0;
    
    for(j = 2 ; j < 25 ; j = j + 1)begin
        fibonacci[16*(j+1)-1 -:16] = fibonacci[16*(j)-1 -:16] + fibonacci[16*(j-1)-1 -:16];
    end
  end 
  
  if(btn_pressed) begin
    
    bpsed = 1;
    
    if(~bool) begin
        flag <= 0;
        bool <= 1;
        switch = 1;
    end
    
    else begin
        flag <= ~flag;
        switch = 0;
    end
  end
  
  if (bpsed && ~flag) begin
    bounce <= bounce + 1;
    
    if(~switch) begin
            countA <= countA - 1;
            countB <= countB - 1;
            switch <= 1;
    end
    
    if(bounce >= 70000000) begin    
    
        row_A <= {"Fibo #", 
        ashex(countA[7:4]), 
        ashex(countA[3:0]),
        " is ",
        ashex(fibonacci[16*(countA) - 1 -:4]),
        ashex(fibonacci[16*(countA)-1-4 -:4]),
        ashex(fibonacci[16*(countA)-1-8 -:4]),
        ashex(fibonacci[16*(countA)-1-12 -:4])};
        
        row_B <= {"Fibo #", 
        ashex(countB[7:4]), 
        ashex(countB[3:0]),
        " is ",
        ashex(fibonacci[16*(countB)-1 -:4]),
        ashex(fibonacci[16*(countB)-1-4 -:4]),
        ashex(fibonacci[16*(countB)-1-8 -:4]),
        ashex(fibonacci[16*(countB)-1-12 -:4])};
        
        if(countA == 25)begin
            countA <= 1;
        end
        else begin
            countA <= countA + 1;
        end
        bounce <= 0;
        if(countB == 25)begin
            countB <= 1;
        end
        else begin
            countB <= countB + 1;
        end
    end
  end
  
  else if(bpsed && flag) begin
    
    bounce <= bounce + 1;
    
    if(~switch) begin
            countA <= countA + 1;
            countB <= countB + 1;
            switch <= 1;
    end
    
    if(bounce >= 70000000) begin
        
        row_A <= {"Fibo #", 
        ashex(countA[7:4]), 
        ashex(countA[3:0]),
        " is ",
        ashex(fibonacci[16*(countA) - 1 -:4]),
        ashex(fibonacci[16*(countA)-1-4 -:4]),
        ashex(fibonacci[16*(countA)-1-8 -:4]),
        ashex(fibonacci[16*(countA)-1-12 -:4])};
        
        row_B <= {"Fibo #", 
        ashex(countB[7:4]), 
        ashex(countB[3:0]),
        " is ",
        ashex(fibonacci[16*(countB)-1 -:4]),
        ashex(fibonacci[16*(countB)-1-4 -:4]),
        ashex(fibonacci[16*(countB)-1-8 -:4]),
        ashex(fibonacci[16*(countB)-1-12 -:4])};
        
        
        if(countA == 1)begin
            countA <= 25;
        end
        
        else begin
            countA <= countA - 1;
        end
        
        bounce <= 0;
        
        if(countB == 1)begin
            countB <= 25;
        end
        
        else begin
            countB <= countB - 1;
        end
    end
  end
end

endmodule

module debounce(
    input clk,
    input btn_input,
    output btn_output
    );
    //assign btn_output = btn_input;
    reg [29:0] shift = 30'b0;
    assign btn_output = shift[29];

    always @ ( posedge clk ) begin
        
            shift <= shift << 1; shift[0] <= btn_input;
        
    end
endmodule

  