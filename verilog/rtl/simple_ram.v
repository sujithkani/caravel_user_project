`timescale 1ns/1ps
module simple_ram #(
  parameter ADDR_WIDTH = 10,
  parameter INIT_FILE = "boot.hex",
  parameter MEM_NAME = "mem"  // NEW: symbolic name for simulation clarity
)(
  input wire clk,
  input wire we,
  input wire [ADDR_WIDTH-1:0] addr,
  input wire [31:0] din,
  output reg [31:0] dout
);

  // Rename the memory instance symbolically
  (* ram_style = "block" *) reg [31:0] mem_array [0:(1<<ADDR_WIDTH)-1];

  initial begin
    $display("Loading memory from: %s", INIT_FILE);
    $readmemh(INIT_FILE, mem_array);
  end

  always @(posedge clk) begin
    if (we)
      mem_array[addr] <= din;
    dout <= mem_array[addr];
  end

  // Export memory for testbench observation (e.g., dut.data_mem.mem_array)
  // The name "mem_array" now distinguishes each memory block
endmodule
