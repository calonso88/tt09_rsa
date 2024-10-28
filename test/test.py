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

  # Number of bits in implementation
  bits = 8
  max_value = (2 ** bits) - 1
  min_prime = 3
  max_upper_boundary = max_value // min_prime

  
  # ITERATIONS 
  iterations = 0
  
  while iterations < 1000:

    while True:
      p = random.randint(min_prime, max_upper_boundary)
      p_is_prime = is_prime(p)
      q = random.randint(min_prime, max_upper_boundary)
      q_is_prime = is_prime(q)
      m = p * q
      #cocotb.log.info(f"RSA RANDOM, P: {p}, Q: {q}, M: {m}")
      if ( ( m <= max_value ) and ( p != q ) and ( p_is_prime == 1 ) and ( q_is_prime == 1 ) ):
        break

    phi_m = (p-1) * (q-1)
    cocotb.log.info(f"RSA, P: {p}, Q: {q}, M: {m}, PHI(M): {phi_m}")
    
    while True:
      e = random.randint(min_prime, phi_m)
      #e_is_prime = is_prime(e)
      e_gdc = math.gcd(e, phi_m)
      #if ( ( e < phi_m ) and ( e_is_prime == 1 ) ):
      if ( ( e < phi_m ) and ( e_gdc == 1 ) ):
        break
      #if (cryptomath.gcd(e, phi_m) == 1):
      #  break
    
    cocotb.log.info(f"Public key: ( {e}, {m} )")
    
    # DEBUG
    #p = 3
    #q = 11
    #m = p * q
    #phi_m = (p-1) * (q-1)
    #e = 7
    # DEBUG

    #d = invmod(e, phi_m)  ->  d*e == 1 mod phi_m
    d = pow(e, -1, phi_m)
    #d = cryptomath.findModInverse(e, phi_m)
    
    cocotb.log.info(f"Private key: ( {d}, {m} )")

    # Number of bits for RSA implementation
    hwbits = bits + 2
    # DEBUG
    #hwbits = 8 + 2
    # DEBUG
    
    # Montgomery constant
    const = (2 ** (2 * hwbits)) % m

    cocotb.log.info(f"Montgomery constant: {const}")

    while True:
      plain_text = random.randint(0, m-1)
      if (plain_text != 0):
        break
    
    cocotb.log.info(f"Plain text: {plain_text}")

    # DEBUG
    #plain_text = 0x1
    #plain_text = 0x2
    #plain_text = 0x58
    # DEBUG
    
    #cocotb.log.info(f"RSA, P: {p}, Q: {q}, M: {m}, PHI(M): {phi_m}")
    #cocotb.log.info(f"Public key: ( {e}, {m} )")
    #cocotb.log.info(f"Private key: ( {d}, {m} )")
    #cocotb.log.info(f"Montgomery constant: {const}")
    #cocotb.log.info(f"Plain text: {plain_text}")

    # Pull CS high
    dut.ui_in.value = 1
    await ClockCycles(dut.clk, 10)

    # CPOL = 0, SPI_CLK low in idle
    temp = dut.ui_in.value;
    result = spi_clk_low(temp)
    dut.ui_in.value = result

    # Wait for some time
    await ClockCycles(dut.clk, 10)
    await ClockCycles(dut.clk, 10)

    # Write config_reg[0] = 0x00
    await spi_write_cpha0 (dut.clk, dut.ui_in, 0, 0)
    # Write config_reg[2] ( plain_text )
    await spi_write_cpha0 (dut.clk, dut.ui_in, 2, plain_text)
    # Write config_reg[3] ( e )
    await spi_write_cpha0 (dut.clk, dut.ui_in, 3, e)
    # Write config_reg[4] ( M )
    await spi_write_cpha0 (dut.clk, dut.ui_in, 4, m)
    # Write config_reg[5] ( const )
    await spi_write_cpha0 (dut.clk, dut.ui_in, 5, const)
    # Write config_reg[1] ( start )
    await spi_write_cpha0 (dut.clk, dut.ui_in, 1, 1)
    
    
    encrypted_text = ( plain_text ** e ) % m
    cocotb.log.info(f"Encrypted text: {encrypted_text}")

    encrypted_text_mem = mem (plain_text, e, m, hwbits)
    cocotb.log.info(f"Encrypted text MMExp: {encrypted_text_mem}")

    decrypted_text = ( encrypted_text ** d ) % m
    cocotb.log.info(f"Decrypted text: {decrypted_text}")

    await ClockCycles(dut.clk, 500)

    # Write config_reg[0] = 0x00
    await spi_write_cpha0 (dut.clk, dut.ui_in, 0, 0)

    # Read reg[6] ( encrypted_text_design )
    encrypted_text_design = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 6, 0x00)
    cocotb.log.info(f"Encrypted text design: {encrypted_text_design}")

    assert plain_text == decrypted_text
    assert encrypted_text == encrypted_text_mem
    # DEBUG
    assert encrypted_text == encrypted_text_design
    # DEBUG


    # Write config_reg[0] = 0x00
    await spi_write_cpha0 (dut.clk, dut.ui_in, 0, 0)
    # Write config_reg[1] = 0xDE
    await spi_write_cpha0 (dut.clk, dut.ui_in, 1, 0xDE)
    # Write config_reg[2] = 0xAD
    await spi_write_cpha0 (dut.clk, dut.ui_in, 2, 0xAD)
    # Write config_reg[3] = 0xBE
    await spi_write_cpha0 (dut.clk, dut.ui_in, 3, 0xBE)
    # Write config_reg[4] = 0xEF
    await spi_write_cpha0 (dut.clk, dut.ui_in, 4, 0xEF)
    # Write config_reg[5] = 0x55
    await spi_write_cpha0 (dut.clk, dut.ui_in, 5, 0x55)
    # Write config_reg[6] = 0xAA
    await spi_write_cpha0 (dut.clk, dut.ui_in, 6, 0xAA)
    # Write config_reg[7] = 0x0F
    await spi_write_cpha0 (dut.clk, dut.ui_in, 7, 0x0F)
    
    # Read config_reg[0]
    reg0 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 0, 0x00)
    # Read config_reg[1]
    reg1 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 1, 0x00)
    # Read config_reg[2]
    reg2 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 2, 0x00)
    # Read config_reg[3]
    reg3 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 3, 0x00)
    # Read config_reg[4]
    reg4 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 4, 0x00)
    # Read config_reg[5]
    reg5 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 5, 0x00)
    # Read config_reg[6]
    reg6 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 6, 0x00)
    # Read config_reg[7]
    reg7 = await spi_read_cpha0 (dut.clk, dut.ui_in, dut.uo_out, 7, 0x00)

    await ClockCycles(dut.clk, 10)

    assert reg0 == 0x00
    assert reg1 == 0xDE
    assert reg2 == 0xAD
    assert reg3 == 0xBE
    assert reg4 == 0xEF
    assert reg5 == 0x55
    assert reg6 == 0xAA
    assert reg7 == 0x0F

    iterations = iterations + 1

  await ClockCycles(dut.clk, 10)

  await ClockCycles(dut.clk, 10)
