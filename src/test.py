import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

async def select_cpu(dut):
    dut.select.value = 0x1
    dut.testnumber.value = dut.testnumber.value + 1

async def select_stack_register(dut):
    dut.select.value = 0x2

async def reset_for_start(dut):
    dut._log.info("start")
    clock = Clock(dut.globclk, 1, units="us")
    cocotb.start_soon(clock.start())

    await ClockCycles(dut.globclk, 1)
    
    dut._log.info("reset")
    dut.mode.value = 7

    for n in range(3):
        dut.clk.value = 0
        await ClockCycles(dut.globclk, 5)
        dut.clk.value = 1
        await ClockCycles(dut.globclk, 5)

    dut.io_ins.value = 0
    dut.mode.value = 0

async def latch_input(dut, input4):
    dut.clk.value = 0
    await ClockCycles(dut.globclk, 4)

    dut.io_ins.value = input4
    await ClockCycles(dut.globclk, 1)

    dut.clk.value = 1
    await ClockCycles(dut.globclk, 5)

async def wait_one_cycle(dut):
    dut.clk.value = 0
    await ClockCycles(dut.globclk, 4)

    dut.io_ins.value = 0
    await ClockCycles(dut.globclk, 1)

    dut.clk.value = 1
    await ClockCycles(dut.globclk, 5)

@cocotb.test()
async def init(dut):
    dut._log.info("start")
    clock = Clock(dut.globclk, 1, units="us")
    cocotb.start_soon(clock.start())

    await ClockCycles(dut.globclk, 1)
    
    dut._log.info("initialize")
    dut.testnumber.value = 0
    await wait_one_cycle(dut)

@cocotb.test()
async def echo_input(dut):
    await select_cpu(dut)
    await reset_for_start(dut)
    dut.mode.value = 1

    await latch_input(dut, 0x5)

    assert int(dut.io_outs.value) == 0x5

@cocotb.test()
async def echo_lastinput(dut):
    await select_cpu(dut)
    await reset_for_start(dut)

    dut.mode.value = 1
    await latch_input(dut, 0x4)
    await latch_input(dut, 0x5)

    assert int(dut.io_outs.value) == 0x5

    dut.mode.value = 2
    await ClockCycles(dut.globclk, 1)
    assert int(dut.io_outs.value) == 0x4


@cocotb.test()
async def push_op(dut):
    await select_cpu(dut)
    await reset_for_start(dut)

    dut.mode.value = 3
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x5) # 0x5

    await wait_one_cycle(dut)
    assert int(dut.io_outs.value) == 0x5


@cocotb.test()
async def push_op2(dut):
    await select_cpu(dut)
    await reset_for_start(dut)

    dut.mode.value = 3
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x7) # 0x7
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x6) # 0x6
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x5) # 0x5
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x4) # 0x4

    await wait_one_cycle(dut)
    assert int(dut.io_outs.value) == 0x54


@cocotb.test()
async def pop_op(dut):
    await select_cpu(dut)
    await reset_for_start(dut)

    dut.mode.value = 3
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x7) # 0x7
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x6) # 0x6
    await latch_input(dut, 0x1) # PUSH
    await latch_input(dut, 0x5) # 0x5
    await latch_input(dut, 0x2) # POP
    await latch_input(dut, 0x0) # 0x0

    await wait_one_cycle(dut)
    assert int(dut.io_outs.value) == 0x76

