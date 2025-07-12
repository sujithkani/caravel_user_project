`timescale 1ns / 1ps
module rv32i_core #(parameter XLEN=32, REG_COUNT=32)(
  input wire clk,
  input wire rst,
  input wire [31:0] instr,
  input wire [31:0] mem_rdata,
  output reg signed [31:0] pc,
  output wire [31:0] mem_addr,
  output wire [31:0] mem_wdata,
  output wire mem_we
);

  reg [31:0] instr_reg;
  reg [31:0] pc_reg;

  // === Instruction Decode ===
  wire [6:0] opcode = instr_reg[6:0];
  wire [4:0] rd     = instr_reg[11:7];
  wire [2:0] funct3 = instr_reg[14:12];
  wire [4:0] rs1    = instr_reg[19:15];
  wire [4:0] rs2    = instr_reg[24:20];
  wire [6:0] funct7 = instr_reg[31:25];

  // === Immediates ===
  wire signed [31:0] imm_i = $signed({{20{instr_reg[31]}}, instr_reg[31:20]});
  wire signed [31:0] imm_s = $signed({{20{instr_reg[31]}}, instr_reg[31:25], instr_reg[11:7]});
  wire signed [31:0] imm_b = $signed({{19{instr_reg[31]}}, instr_reg[31], instr_reg[7], instr_reg[30:25], instr_reg[11:8], 1'b0});
  wire [31:0]         imm_u = {instr_reg[31:12], 12'b0};
  wire signed [31:0] imm_j = $signed({{11{instr_reg[31]}}, instr_reg[31], instr_reg[19:12], instr_reg[20], instr_reg[30:21], 1'b0});

  // === Register File ===
  wire [31:0] reg_rdata1, reg_rdata2;
  wire [31:0] writeback_data;
  wire writeback_en;

  reg_file regfile (
    .clk(clk),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd),
    .we(writeback_en),
    .wd(writeback_data),
    .rd1(reg_rdata1),
    .rd2(reg_rdata2)
  );

  // === ALU ===
  wire [31:0] alu_operand_b = (opcode == 7'b0010011 || opcode == 7'b0000011 || opcode == 7'b1100111) ? imm_i :
                              (opcode == 7'b0100011) ? imm_s :
                              reg_rdata2;

  wire [31:0] alu_result;

  alu alu_inst (
    .a(reg_rdata1),
    .b(alu_operand_b),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .result(alu_result)
  );

  assign writeback_en = (opcode == 7'b0010011 ||  // I-type
                         opcode == 7'b0110011 ||  // R-type
                         opcode == 7'b0000011 ||  // LW
                         opcode == 7'b1101111 ||  // JAL
                         opcode == 7'b1100111 ||  // JALR
                         opcode == 7'b0010111 ||  // AUIPC
                         opcode == 7'b0110111);   // LUI

  assign writeback_data = (opcode == 7'b0000011) ? mem_rdata :
                          (opcode == 7'b1101111 || opcode == 7'b1100111) ? pc_reg + 4 :
                          (opcode == 7'b0010111 || opcode == 7'b0110111) ? imm_u :
                          alu_result;

  // === Memory Signals ===
  reg [31:0] mem_addr_reg, mem_wdata_reg;
  reg mem_we_reg;

  assign mem_addr  = mem_addr_reg;
  assign mem_wdata = mem_wdata_reg;
  assign mem_we    = mem_we_reg;

  // === Branch Logic ===
  reg branch_taken;
  reg signed [31:0] branch_target;

  always @(*) begin
    branch_taken  = 0;
    branch_target = pc_reg + 4;

    if (opcode == 7'b1100011) begin
      case (funct3)
        3'b000: branch_taken = (reg_rdata1 == reg_rdata2);
        3'b001: branch_taken = (reg_rdata1 != reg_rdata2);
        3'b100: branch_taken = ($signed(reg_rdata1) < $signed(reg_rdata2));
        3'b101: branch_taken = ($signed(reg_rdata1) >= $signed(reg_rdata2));
        3'b110: branch_taken = (reg_rdata1 < reg_rdata2);
        3'b111: branch_taken = (reg_rdata1 >= reg_rdata2);
      endcase
      branch_target = pc_reg + imm_b;
    end
  end

  // === Sequential Logic ===
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      pc <= 0;
      pc_reg <= 0;
      instr_reg <= 0;
      mem_addr_reg <= 0;
      mem_wdata_reg <= 0;
      mem_we_reg <= 0;
    end else begin
      pc_reg <= pc;
      instr_reg <= instr;

      case (opcode)
        7'b1100011: pc <= branch_taken ? branch_target : pc_reg + 4;
        7'b1101111: pc <= pc_reg + imm_j;
        7'b1100111: pc <= (reg_rdata1 + imm_i) & ~32'b1;
        default:    pc <= pc_reg + 4;
      endcase

      mem_we_reg <= 0;
      case (opcode)
        7'b0100011: begin
          mem_addr_reg  <= reg_rdata1 + imm_s;
          mem_wdata_reg <= reg_rdata2;
          mem_we_reg    <= 1;
        end
        7'b0000011: begin
          mem_addr_reg <= reg_rdata1 + imm_i;
        end
      endcase
    end
  end

endmodule


