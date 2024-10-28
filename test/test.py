# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import math
import random

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

def mmm (a, b, m, nbits):
  r = 0
  idx = 0
  while idx < nbits:
    r0 = r % 2
    b0 = b % 2
    a_bit = ( get_bit(a, idx) >> idx )
    q0 = r0 + b0 * a_bit
    q0 = q0 % 2
    r = ( r + a_bit * b + q0 * m ) // 2
    idx = idx + 1
  return r;

def mem (p, e, m, nbits):
  # Mapping constant
  const_m = (2 ** (2 * nbits)) % m

  # Mapping
  p_int = mmm (const_m, p, m, nbits)
  r_int = mmm (const_m, 1, m, nbits)

  cocotb.log.info(f"MEM mapping P, R: ( {p_int}, {r_int} )")
  
  idx = 0
  while idx < nbits:
    if ( ( get_bit(e, idx) >> idx ) == 1 ):
      r_int = mmm (r_int, p_int, m, nbits)
    
    p_int = mmm (p_int, p_int, m, nbits)
    cocotb.log.info(f"MEM idx, P, R: ( {idx}, {p_int}, {r_int} )")
    idx = idx + 1

  # Remapping  
  r = mmm (1, r_int, m, nbits)
  return r

def is_prime(num):
  if (num < 2) :
    return 0;
  else :
    # Iterate from 2 to n // 2
    for i in range(2, ((num // 2) + 1)) :
      # If num is divisible by any number between
      # 2 and n / 2, it is not prime
      if (num % i) == 0:
        #print(num, "is not a prime number")
        return 0

      return 1


def get_bit(value, bit_index):
  temp = value & (1 << bit_index)
  return temp

def set_bit(value, bit_index):
  temp = value | (1 << bit_index)
  return temp

def clear_bit(value, bit_index):
  temp = value & ~(1 << bit_index)
  return temp

def xor_bit(value, bit_index):
  temp = value ^ (1 << bit_index)
  return temp

def pull_cs_high(value):
  temp = set_bit(value, 0)
  return temp

def pull_cs_low(value):
  temp = clear_bit(value, 0)
  return temp

def spi_clk_high(value):
  temp = set_bit(value, 1)
  return temp

def spi_clk_low(value):
  temp = clear_bit(value, 1)
  return temp

def spi_clk_invert(value):
  temp = xor_bit(value, 1)
  return temp

def spi_mosi_high(value):
  temp = set_bit(value, 2)
  return temp

def spi_mosi_low(value):
  temp = clear_bit(value, 2)
  return temp

def spi_miso_read(port):
  return (get_bit (port.value, 3) >> 3)

async def spi_write (clk, port, address, data):

  temp = port.value;
  result = pull_cs_high(temp)
  port.value = result
  await ClockCycles(clk, 10)
  temp = port.value;
  result = pull_cs_low(temp)
  port.value = result
  await ClockCycles(clk, 10)

  # Write command bit - bit 7 - MSBIT in first byte
  temp = port.value;
  result = spi_clk_invert(temp)
  result2 = spi_mosi_high(result)
  port.value = result2
  await ClockCycles(clk, 10)
  temp = port.value;
  result = spi_clk_invert(temp)
  port.value = result
  await ClockCycles(clk, 10)

  iterator = 0
  while iterator < 3:
    # Don't care - bit 6, bit 5 and bit 4
    temp = port.value;
    result = spi_clk_invert(temp)
    result2 = spi_mosi_low(result)
    port.value = result2
    await ClockCycles(clk, 10)
    temp = port.value;
    result = spi_clk_invert(temp)
    port.value = result
    await ClockCycles(clk, 10)
    iterator += 1

  iterator = 3
  while iterator >= 0:
    # Address[iterator] - bit 3, bit 2, bit 1 and bit 0
    temp = port.value;
    result = spi_clk_invert(temp)
    address_bit = get_bit(address, iterator)
    if (address_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port.value = result2
    await ClockCycles(clk, 10)
    temp = port.value;
    result = spi_clk_invert(temp)
    port.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  iterator = 7
  while iterator >= 0:
    # Data[iterator]
    temp = port.value;
    result = spi_clk_invert(temp)
    data_bit = get_bit(data, iterator)
    if (data_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port.value = result2
    await ClockCycles(clk, 10)
    temp = port.value;
    result = spi_clk_invert(temp)
    port.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  temp = port.value;
  result = pull_cs_high(temp)
  port.value = result
  await ClockCycles(clk, 10)  


async def spi_read (clk, port_in, port_out, address, data):
  
  temp = port_in.value;
  result = pull_cs_high(temp)
  port_in.value = result
  await ClockCycles(clk, 10)
  temp = port_in.value;
  result = pull_cs_low(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  # Read command bit - bit 7 - MSBIT in first byte
  temp = port_in.value;
  result = spi_clk_invert(temp)
  result2 = spi_mosi_low(result)
  port_in.value = result2
  await ClockCycles(clk, 10)
  temp = port_in.value;
  result = spi_clk_invert(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  iterator = 0
  while iterator < 3:
    # Don't care - bit 6, bit 5 and bit 4
    temp = port_in.value;
    result = spi_clk_invert(temp)
    result2 = spi_mosi_low(result)
    port_in.value = result2
    await ClockCycles(clk, 10)
    temp = port_in.value;
    result = spi_clk_invert(temp)
    port_in.value = result
    await ClockCycles(clk, 10)
    iterator += 1

  iterator = 3
  while iterator >= 0:
    # Address[iterator] - bit 3, bit 2, bit 1 and bit 0
    temp = port_in.value;
    result = spi_clk_invert(temp)
    address_bit = get_bit(address, iterator)
    if (address_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port_in.value = result2
    await ClockCycles(clk, 10)
    temp = port_in.value;
    result = spi_clk_invert(temp)
    port_in.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  miso_byte = 0
  miso_bit = 0

  iterator = 7
  while iterator >= 0:
    # Data[iterator]
    temp = port_in.value;
    result = spi_clk_invert(temp)
    data_bit = get_bit(data, iterator)
    if (data_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port_in.value = result2
    await ClockCycles(clk, 10)
    miso_bit = spi_miso_read(port_out)
    miso_byte = miso_byte | (miso_bit << iterator)
    temp = port_in.value;
    result = spi_clk_invert(temp)
    port_in.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  temp = port_in.value;
  result = pull_cs_high(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  return miso_byte


async def spi_write_cpha0 (clk, port, address, data):

  temp = port.value;
  result = pull_cs_high(temp)
  port.value = result
  await ClockCycles(clk, 10)

  # Pull CS low + Write command bit - bit 7 - MSBIT in first byte
  temp = port.value;
  result = pull_cs_low(temp)
  result2 = spi_mosi_high(result)
  port.value = result2
  await ClockCycles(clk, 10)
  temp = port.value;
  result = spi_clk_invert(temp)
  port.value = result
  await ClockCycles(clk, 10)

  iterator = 0
  while iterator < 3:
    # Don't care - bit 6, bit 5 and bit 4
    temp = port.value;
    result = spi_clk_invert(temp)
    result2 = spi_mosi_low(result)
    port.value = result2
    await ClockCycles(clk, 10)
    temp = port.value;
    result = spi_clk_invert(temp)
    port.value = result
    await ClockCycles(clk, 10)
    iterator += 1

  iterator = 3
  while iterator >= 0:
    # Address[iterator] - bit 3, bit 2, bit 1 and bit 0
    temp = port.value;
    result = spi_clk_invert(temp)
    address_bit = get_bit(address, iterator)
    if (address_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port.value = result2
    await ClockCycles(clk, 10)
    temp = port.value;
    result = spi_clk_invert(temp)
    port.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  iterator = 7
  while iterator >= 0:
    # Data[iterator]
    temp = port.value;
    result = spi_clk_invert(temp)
    data_bit = get_bit(data, iterator)
    if (data_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port.value = result2
    await ClockCycles(clk, 10)
    temp = port.value;
    result = spi_clk_invert(temp)
    port.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  temp = port.value;
  result = spi_clk_invert(temp)
  port.value = result
  await ClockCycles(clk, 10)

  temp = port.value;
  result = pull_cs_high(temp)
  port.value = result
  await ClockCycles(clk, 10)  


async def spi_read_cpha0 (clk, port_in, port_out, address, data):
  
  temp = port_in.value;
  result = pull_cs_high(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  # Pull CS low + Read command bit - bit 7 - MSBIT in first byte
  temp = port_in.value;
  result = pull_cs_low(temp)
  result2 = spi_mosi_low(result)
  port_in.value = result2
  await ClockCycles(clk, 10)
  temp = port_in.value;
  result = spi_clk_invert(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  iterator = 0
  while iterator < 3:
    # Don't care - bit 6, bit 5 and bit 4
    temp = port_in.value;
    result = spi_clk_invert(temp)
    result2 = spi_mosi_low(result)
    port_in.value = result2
    await ClockCycles(clk, 10)
    temp = port_in.value;
    result = spi_clk_invert(temp)
    port_in.value = result
    await ClockCycles(clk, 10)
    iterator += 1

  iterator = 3
  while iterator >= 0:
    # Address[iterator] - bit 3, bit 2, bit 1 and bit 0
    temp = port_in.value;
    result = spi_clk_invert(temp)
    address_bit = get_bit(address, iterator)
    if (address_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port_in.value = result2
    await ClockCycles(clk, 10)
    temp = port_in.value;
    result = spi_clk_invert(temp)
    port_in.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  miso_byte = 0
  miso_bit = 0

  iterator = 7
  while iterator >= 0:
    # Data[iterator]
    temp = port_in.value;
    result = spi_clk_invert(temp)
    data_bit = get_bit(data, iterator)
    if (data_bit == 0):
      result2 = spi_mosi_low(result)
    else:
      result2 = spi_mosi_high(result)
    port_in.value = result2
    await ClockCycles(clk, 10)
    miso_bit = spi_miso_read(port_out)
    miso_byte = miso_byte | (miso_bit << iterator)
    temp = port_in.value;
    result = spi_clk_invert(temp)
    port_in.value = result
    await ClockCycles(clk, 10)
    iterator -= 1

  temp = port_in.value;
  result = spi_clk_invert(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  temp = port_in.value;
  result = pull_cs_high(temp)
  port_in.value = result
  await ClockCycles(clk, 10)

  return miso_byte



@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Set the clock period to 10 us (100 KHz)
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # Reset
    dut._log.info("Reset")
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    dut._log.info("Test project behavior")

    # Set the input values you want to test
    dut.ui_in.value = 20
    dut.uio_in.value = 30

    # Wait for one clock cycle to see the output values
    await ClockCycles(dut.clk, 1)

    # The following assersion is just an example of how to check the output values.
    # Change it to match the actual expected output of your module:
    assert dut.uo_out.value == 50

    # Keep testing the module by changing the input values, waiting for
    # one or more clock cycles, and asserting the expected output values.
