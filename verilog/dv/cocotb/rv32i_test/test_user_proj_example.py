import cocotb
from cocotb.triggers import RisingEdge, Timer

@cocotb.test()
async def simple_boot_test(dut):
    """Basic test to check rst and clk"""
    dut._log.info("Starting RV32I test")

    # Reset
    dut.RSTB.value = 0
    dut.CLK.value = 0
    await Timer(2, units="ns")
    dut.RSTB.value = 1

    # Toggle CLK
    for _ in range(20):
        dut.CLK.value = 1
        await Timer(5, units="ns")
        dut.CLK.value = 0
        await Timer(5, units="ns")

    dut._log.info("Test complete. Consider checking RAM or output ports.")
