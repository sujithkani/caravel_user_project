`timescale 1ns / 1ps
module alu(
  input wire [31:0] a,
  input wire [31:0] b,
  input wire [2:0] funct3,
  input wire [6:0] funct7,
  input wire [6:0] opcode,
  output reg [31:0] result
);

  always @(*) begin
    case (funct3)
      3'b000: result = (opcode == 7'b0110011 && funct7 == 7'b0100000) ? a - b : a + b;  // ADD/SUB
      3'b111: result = a & b;                                                          // AND
      3'b110: result = a | b;                                                          // OR
      3'b100: result = a ^ b;                                                          // XOR
      3'b001: result = a << b[4:0];                                                    // SLL
      3'b101: result = (funct7 == 7'b0100000) ? $signed(a) >>> b[4:0] : a >> b[4:0];    // SRA/SRL
      3'b010: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;                       // SLT
      3'b011: result = (a < b) ? 32'b1 : 32'b0;                                          // SLTU
      default: result = 32'hDEAD_BEEF;
    endcase
  end

endmodule
