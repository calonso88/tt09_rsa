/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module rsa_spi_wrapper #(parameter int WIDTH = 8) (rstb, clk, ena, spi_mode, spi_cs_n, spi_clk, spi_mosi, spi_miso, spi_start_cmd, spi_stop_cmd, rsa_p, rsa_e, rsa_m, rsa_const, rsa_c, irq, spare);

  input logic rstb;
  input logic clk;
  input logic ena;

  input logic [1:0] spi_mode;
  input logic spi_cs_n;
  input logic spi_clk;
  input logic spi_mosi;
  output logic spi_miso;

  output logic spi_start_cmd;
  output logic spi_stop_cmd;

  output logic [WIDTH-1:0] rsa_p;
  output logic  [WIDTH-1:0] rsa_e;
  output logic [WIDTH-1:0] rsa_m;
  output logic [WIDTH-1:0] rsa_const;
  input logic [WIDTH-1:0] rsa_c;

  input logic irq;
  output logic [WIDTH-1:0] spare;

  // Address width for register bank
  localparam int ADDR_WIDTH = 3;
  localparam int NUM_CFG = 8;
  localparam int NUM_STATUS = NUM_CFG;
  localparam int REG_WIDTH = WIDTH;

  //  Address map:
  //  Addr 0 - Read Status, Write is Spare register
  //  Addr 1 - Actions, Bit0 (Start), Bit1 (Stop)
  //  Addr 2 - P;
  //  Addr 3 - E;
  //  Addr 4 - M;
  //  Addr 5 - Const;
  //  Addr 6 - C;
  //  Addr 7 - Spare;

  // Config Regs and Status Regs
  logic [NUM_CFG*REG_WIDTH-1:0] config_regs;
  logic [NUM_STATUS*REG_WIDTH-1:0] status_regs;
  logic spi_start;
  logic spi_stop;

  // Assign config regs
  //assign rsa_p   = config_regs[7:0];    // Addr 0
  assign spi_start = config_regs[8];      // Addr 1 - Only bit 0
  assign spi_stop  = config_regs[9];      // Addr 1 - Only bit 1
  //assign rsa_p   = config_regs[15:10];  // Addr 1 - bits 7 to 2
  assign rsa_p     = config_regs[23:16];  // Addr 2
  assign rsa_e     = config_regs[31:24];  // Addr 3
  assign rsa_m     = config_regs[39:32];  // Addr 4
  assign rsa_const = config_regs[47:40];  // Addr 5
  //assign rsa_p   = config_regs[55:48];  // Addr 6
  assign spare     = config_regs[63:56];  // Addr 7

  // Assign status regs
  assign status_regs[7:0]   = {{7{1'b0}}, irq}; // Addr 0
  assign status_regs[15:8]  = 8'hCA;            // Addr 1
  assign status_regs[23:16] = 8'h10;            // Addr 2
  assign status_regs[31:24] = 8'hDE;            // Addr 3
  assign status_regs[39:32] = 8'hAD;            // Addr 4
  assign status_regs[47:40] = 8'h00;            // Addr 5
  assign status_regs[55:48] = rsa_c;            // Addr 6
  assign status_regs[63:56] = 8'hFF;            // Addr 7

  // Generate SPI start and stop commands
  rising_edge_detector spi_start_cmd_i (.rstb(rstb), .clk(clk), .ena(ena), .data(spi_start), .pos_edge(spi_start_cmd));
  rising_edge_detector spi_stop_cmd_i (.rstb(rstb), .clk(clk), .ena(ena), .data(spi_stop), .pos_edge(spi_stop_cmd));

  // SPI wrapper
  spi_wrapper #(.NUM_CFG(NUM_CFG), .NUM_STATUS(NUM_STATUS), .REG_WIDTH(REG_WIDTH)) spi_wrapper_i (.rstb(rstb), .clk(clk), .ena(ena), .mode(spi_mode), .spi_cs_n(spi_cs_n), .spi_clk(spi_clk), .spi_mosi(spi_mosi), .spi_miso(spi_miso), .config_regs(config_regs), .status_regs(status_regs));

endmodule