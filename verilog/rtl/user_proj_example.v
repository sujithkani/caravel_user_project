`timescale 1ns/1ps
module user_proj_example (
    input  wire        clk,
    input  wire [7:0]  io_in,
    output wire [7:0]  io_out,
    input  wire [37:0] la_data_in,
    output wire [31:0] la_data_out
);

  wire rst;
  assign rst = io_in[0];  // external reset from io_in[0]

  wire [31:0] pc;
  wire [31:0] mem_addr, mem_wdata, mem_rdata;
  wire mem_we;

  wire [31:0] instr_rdata;
  wire [31:0] data_rdata;

  rv32i_core core (
    .clk(clk),
    .rst(rst),
    .instr(instr_rdata),
    .pc(pc),
    .mem_addr(mem_addr),
    .mem_we(mem_we),
    .mem_wdata(mem_wdata),
    .mem_rdata(data_rdata)
  );

  // Instruction and data RAMs (synthesizable for tapeout)
  simple_ram #(.INIT_FILE("boot.hex")) instr_mem (
    .clk(clk),
    .we(1'b0),
    .addr(pc[11:2]),
    .din(32'b0),
    .dout(instr_rdata)
  );

  simple_ram #(.INIT_FILE("data.hex")) data_mem (
    .clk(clk),
    .we(mem_we),
    .addr(mem_addr[11:2]),
    .din(mem_wdata),
    .dout(data_rdata)
  );

  // Expose signals
  assign la_data_out = pc;
  assign io_out = mem_addr[9:2];

endmodule
