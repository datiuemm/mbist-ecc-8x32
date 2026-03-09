import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles


@cocotb.test()
async def test_project(dut):

    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    dut._log.info("Reset")

    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0

    await ClockCycles(dut.clk, 10)

    dut.rst_n.value = 1

    dut._log.info("Hi")

    await ClockCycles(dut.clk, 5)

    dut._log.info("Start MBIST")

    dut.ui_in.value = 0b00000001

    await ClockCycles(dut.clk, 200)

    results = dut.uo_out.value & 0b111

    dut._log.info(f"MBIST results = {results}")

    assert results == 0b101, "MBIST FAILED"

    dut._log.info("MBIST PASSED")
