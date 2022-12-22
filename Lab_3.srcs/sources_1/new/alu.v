`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/12 19:59:41
// Design Name: 
// Module Name: alu
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


module alu( alu_out,data,accum,opcode, clk, reset,zero);

output  reg signed [7:0] alu_out;
input  wire signed [7:0] data;
input  wire signed [7:0] accum;
input wire [2:0] opcode;
input wire clk;
input wire reset;
output reg zero;

always@(posedge clk) begin
    if(accum == 0) begin
        zero <= 1;
    end
    else begin 
        zero <= 0;
    end
    if(reset) begin
        alu_out <= 0;
    end
    else begin
        case(opcode)
            3'b000: alu_out = accum;
            3'b001: alu_out = accum + data;
            3'b010: alu_out = accum - data;
            3'b011: alu_out = accum & data;
            3'b100: alu_out = accum | data;
            3'b101: if(accum < 0) begin
                        alu_out = -accum;
                    end
                    else begin
                        alu_out = accum;
                    end
            3'b110: alu_out = accum * data;
            3'b111: alu_out = data;
            3'bxxx: alu_out = 0;
            default:
                    alu_out=0;
        endcase
    end
end

endmodule
