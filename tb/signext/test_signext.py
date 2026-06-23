import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import random

@cocotb.test()
async def signext_i_type_test(dut):
    # TEST POSITIVE IMM = 123 WITH SOURCE = 0
    imm = 0b000001111011 # 123
    imm <<= 13 # leave "room" for random junk
    source = 0b00
    # 25 bits sent to sign extend contains data before that will be ignored (rd, f3, ...)
    # masked to leave room for imm "test payload"
    random_junk = 0b000000000000_1010101010101
    raw_data = random_junk | imm
    await Timer(1, unit="ns")
    dut.raw_src.value = raw_data
    dut.imm_source.value = source
    await Timer(1, unit="ns") # advance to calculate
    assert dut.immediate.value == "00000000000000000000000001111011"
    assert int(dut.immediate.value) == 123

    # TEST NEGATIVE IMM = -42 WITH SOURCE = 0
    imm = 0b111111010110 # -42
    imm <<= 13 # leave "room" for random junk
    source = 0b00
    # 25 bits sent to sign extend contains data before that will be ignored (rd, f3, ...)
    # masked to leave room for imm "test payload"
    random_junk = 0b000000000000_1010101010101
    raw_data = random_junk | imm
    await Timer(1, unit="ns")
    dut.raw_src.value = raw_data
    dut.imm_source.value = source
    await Timer(1, unit="ns") # advance to calculate
    assert dut.immediate.value == "11111111111111111111111111010110"
    assert int(dut.immediate.value) - (1 << 32) == -42
