`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/09/30 03:08:29
// Design Name: 
// Module Name: mmut
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

module mmult(
  input  clk,// Clock signal.
  input  reset_n,// Reset signal (negative logic).
  input  enable,// Activation signal for matrix
  input  [0:9*8-1] A_mat,// multiplication (tells the circuit // that A and B are ready for use). // A matrix.
  input  [0:9*8-1] B_mat,// B matrix.
  output valid,// Signals that the output is valid // to read.
  output reg [0:9*17-1] C_mat
   );// The result of A x B.

    wire [0:71] A_mat;
    wire [0:71] B_mat;
    
    reg [0:7] a;
    reg [0:7] b;
    reg [0:7] c;
    reg [0:71] temp;
    integer i,j,k;
    reg [0:1] count = 2'b00;
    assign valid = ( count == 3 );
    //assign valid = 1;
    always@ (posedge clk)begin
        if(!reset_n)begin
            count = 0;
            temp = B_mat;
            a = temp[0:7];
            b = temp[24:31];
            c = temp[48:55];
            C_mat = 0;
        end
        
        if(enable) begin
            count <= count + 1;
            if(count < 3 ) begin
                C_mat[34:50] = A_mat[0:7]*a + A_mat[8:15]*b + A_mat[16:23]*c;
                C_mat[85:101] = A_mat[24:31]*a + A_mat[32:39]*b + A_mat[40:47]*c;
                C_mat[136:152] = A_mat[48:55]*a + A_mat[56:63]*b + A_mat[64:71]*c;
            end
            if(count < 2 ) begin
                temp = temp << 8;
                C_mat = C_mat << 17;
            end
            a = temp[0:7];
            b = temp[24:31];
            c = temp[48:55];
            if(count == 3)begin
                temp = B_mat;
                a = temp[0:7];
                b = temp[24:31];
                c = temp[48:55];
            end
            
        end
    end
endmodule
////    i=0;
////    j=0;
////    k=0;
////    for(i=0;i < 3;i=i+1)
////            for(j=0;j < 3;j=j+1)
////                for(k=0;k < 3;k=k+1)
////                    C_mat1[i][j] = C_mat1[i][j] + (A_mat1[i][k] * B_mat1[k][j]);
////        //final output assignment - 3D array to 1D array conversion.            
////        C_mat = {C_mat1[0][0],C_mat1[0][1],C_mat1[0][2],C_mat1[1][0],C_mat1[1][1],C_mat1[1][2],C_mat1[2][0],C_mat1[2][1],C_mat1[2][2]};                
////    end 


////        if(count == 1) begin
////            C_mat[0:15] = A_mat[0:7]*a + A_mat[8:15]*b + A_mat[16:23]*c;
////            temp = temp >> 8;
////            C_mat[16:31] = A_mat[0:7]*a + A_mat[8:15]*b + A_mat[16:23]*c;
////            temp = temp >> 8;
////            C_mat[32:47] = A_mat[0:7]*a + A_mat[8:15]*b + A_mat[16:23]*c;
////            temp = temp << 16;
////        end
////        if(count == 2) begin
////            C_mat[48:63] = A_mat[24:31]*a + A_mat[32:39]*b + A_mat[40:47]*c;
////            temp = temp >> 8;
////            C_mat[64:79] = A_mat[24:31]*a + A_mat[32:39]*b + A_mat[40:47]*c;
////            temp = temp >> 8;
////            C_mat[80:95] = A_mat[24:31]*a + A_mat[32:39]*b + A_mat[40:47]*c;
////            temp = temp << 16;
////        end
////        if(count == 3) begin
////            C_mat[96:111] = A_mat[48:55]*a + A_mat[56:63]*b + A_mat[64:71]*c;
////            temp = temp >> 8;
////            C_mat[112:127] = A_mat[48:55]*a + A_mat[56:63]*b + A_mat[64:71]*c;
////            temp = temp >> 8;
////            C_mat[128:153] = A_mat[48:55]*a + A_mat[56:63]*b + A_mat[64:71]*c;
////            temp = temp << 16;
////        end


