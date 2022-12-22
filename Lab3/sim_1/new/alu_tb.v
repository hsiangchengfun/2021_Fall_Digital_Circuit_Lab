/*********************************************************************
 * Stimulus for the ALU design - Verilog Training Course
 *********************************************************************/
`timescale 1ns / 1ns
module alu_test;
  wire [7:0] alu_out;
  reg  [7:0] data, accum;
  reg  [2:0] opcode;
  
  wire [7:0] mask;
  
  reg clk, reset;
  
  
// Instantiate the ALU.  Named mapping allows the designer to have freedom
//    with the order of port declarations

  alu   alu1 (.alu_out(alu_out), .zero(zero),               //outputs from ALU
	      .opcode(opcode), .data(data & mask), .accum(accum & mask), .clk(clk), .reset(reset)); //inputs to ALU

  //define mnemonics to represent opcodes
  `define PASSA 3'b000
  `define ADD   3'b001
  `define SUB   3'b010
  `define AND   3'b011
  `define XOR   3'b100
  `define ABS   3'b101
  `define MUL   3'b110
  `define PASSD 3'b111

// Define a safe delay between each strobing of the ALU inputs/outputs
  `define strobe      20
  `define testnumber  10

// To perform a 4-bit multiplication, set the first 4 bits of the input to 4'b0000 when opcode is 3'b110 (Multiplication)
assign mask = (opcode == 3'b110)? 8'h0f: 8'hff;

// clock generate
initial   clk = 0;
always #(`strobe/2) clk = ~clk;

// pattern generate
  initial
    begin
      
      // SET UP THE OUTPUT FORMAT FOR THE TEXT DISPLAY
      $display("\t\t\t\t\t\t\t            INPUTS                      REAL    OUTPUT  \n");
      $display("\t\t\t\t\t\t CODE     DATA IN    ACCUM IN      ALU OUT   ZERO BIT");
      $display("\t\t\t\t\t      ------   --------   --------      --------  --------");
      $timeformat(-9, 1, " ns", 9); //Display time in nanoseconds 
      reset = 0;
      # `strobe;
      reset = 1;
      # `strobe;
      reset = 0;
      @(negedge clk)
        #(`strobe/4) opcode = 3'b010;
      accum = 8'h37;
      data = 8'h98;
      # (`strobe*3/2) check_outputs;
      
       @(negedge clk)
        #(`strobe/4) opcode = 3'b101;
      accum = 8'hD6;
      data = 8'hD6;
      # (`strobe*3/2) check_outputs;
      
      @(negedge clk)
        #(`strobe/4) opcode = 3'b001;
      accum = 8'hF3;
      data = 8'hA5;
      # (`strobe*3/2) check_outputs;
      
      @(negedge clk)
        #(`strobe/4) opcode = 3'b110;
      accum = 8'h37;
      data = 8'hD6;
      # (`strobe*3/2) check_outputs;
      
    end

/**********************************************************************
 * SUBROUTINES TO COMPARE THE ALU OUTPUTS TO EXPECTED RESULTS
 *********************************************************************/
  task check_outputs;
    casez (opcode)
        `PASSA  : begin
                   $display("PASS ACCUM OPERATION:",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
        `ADD    : begin
                   $display("ADD OPERATION       :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
        `SUB    : begin
                   $display("SUB OPERATION       :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
        `AND    : begin
                   $display("AND OPERATION       :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
        `XOR   :  begin
                   $display("XOR OPERATION       :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
		`ABS    : begin
                   $display("ABS OPERATION       :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
		`MUL    : begin
                   $display("MUL OPERATION       :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data & mask, accum & mask, alu_out, zero);
                  end
        `PASSD  : begin
                   $display("PASS DATA OPERATION :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
        default : begin
                   $display("UNKNOWN OPERATION   :",
                            "      %b     %b   %b  |   %b      %b",
                            opcode, data, accum, alu_out, zero);
                  end
    endcase
  endtask

endmodule
