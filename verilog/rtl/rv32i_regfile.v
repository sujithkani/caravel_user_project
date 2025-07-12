`timescale 1ns/1ps
module reg_file (input wire clk, input wire [4:0] rs1, rs2, rd, input wire we, input wire [31:0] wd, output wire [31:0] rd1, rd2);

  reg [31:0] regs [0:31];
  integer i;

  initial begin
    for (i=0; i<32; i=i+1)
      regs[i]=0;
  end

  assign rd1=(rs1==0)?0:regs[rs1];
  assign rd2=(rs2==0)?0:regs[rs2];

  always @(posedge clk) begin
    if (we && rd!=0)
      regs[rd]<=wd;
  end

endmodule
