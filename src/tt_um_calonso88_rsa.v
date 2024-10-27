/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_calonso88_rsa (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  
  // RSA Unit size
  localparam int REG_WIDTH = 8;

  // GPIO Auxiliars
  wire gpio_start;
  wire gpio_stop;
  wire gpio_start_cmd;
  wire gpio_stop_cmd;

  // SPI Auxiliars
  wire cpol;
  wire cpha;
  wire spi_cs_n;
  wire spi_clk;
  wire spi_miso;
  wire spi_mosi;
  
  // Sync'ed
  wire cpol_sync;
  wire cpha_sync;
  wire spi_cs_n_sync;
  wire spi_clk_sync;
  wire spi_mosi_sync;

  wire spi_start_cmd;
  wire spi_stop_cmd;

  // RSA En FSM Auxiliars
  wire ena_rsa;
  wire clear_rsa;
  wire eoc_rsa;
  wire irq;

  // RSA Unit P, E, M, Const and C
  wire [REG_WIDTH-1:0] rsa_p;
  wire [REG_WIDTH-1:0] rsa_e;
  wire [REG_WIDTH-1:0] rsa_m;
  wire [REG_WIDTH-1:0] rsa_const;
  wire [REG_WIDTH-1:0] rsa_c;
  wire [REG_WIDTH-1:0] spare;

  // Bi direction IOs [6:4] as inputs
  assign uio_oe[6:4] = 3'b000;
  // Bi direction IOs [7] and [3:0] as outputs
  assign uio_oe[7]   = 1'b1;
  assign uio_oe[3:0] = 4'b1111;

  // Input ports
  assign cpol      = ui_in[0];
  assign cpha      = ui_in[1];
  assign spi_cs_n  = uio_in[4];
  assign spi_clk   = uio_in[5];
  assign spi_mosi  = uio_in[6];
  assign gpio_start = 1'b0;    // TBD
  assign gpio_stop  = 1'b0;    // TBD

  // MISO Output port
  assign uio_out[3] = spi_miso;

  // OUT
  assign uo_out = 8'h00;
  // GPIO Output ports
  //assign blabla = spare;     // TBD
  //assign blabla = irq;       // TBD
  
  // Unused ouputs needs to be assigned to 0.
  assign uio_out[2:0] = 3'b000;
  assign uio_out[7:4] = 4'b0000;

  // Number of stages in each synchronizer
  localparam int SYNC_STAGES = 2;
  localparam int SYNC_WIDTH = 1;

  // Synchronizers
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_mode_cpol (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(cpol),     .data_out(cpol_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_mode_cpha (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(cpha),     .data_out(cpha_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_cs_n_inst (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(spi_cs_n), .data_out(spi_cs_n_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_clk_inst  (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(spi_clk),  .data_out(spi_clk_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_mosi_inst (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(spi_mosi), .data_out(spi_mosi_sync));
  
  // GPIO wrapper
  gpio_wrapper gpio_wrapper_i (.rstb(rst_n), .clk(clk), .ena(ena), .gpio_start(gpio_start), .gpio_stop(gpio_stop), .gpio_start_cmd(gpio_start_cmd), .gpio_stop_cmd(gpio_stop_cmd));

  // SPI wrapper
  rsa_spi_wrapper #(.WIDTH(REG_WIDTH)) rsa_spi_wrapper_i (.rstb(rst_n), .clk(clk), .ena(ena), .spi_mode ({cpol_sync, cpha_sync}), .spi_cs_n(spi_cs_n_sync), .spi_clk(spi_clk_sync), .spi_mosi(spi_mosi_sync), .spi_miso(spi_miso), .spi_start_cmd(spi_start_cmd), .spi_stop_cmd(spi_stop_cmd), .rsa_p(rsa_p), .rsa_e(rsa_e), .rsa_m(rsa_m), .rsa_const(rsa_const), .rsa_c(rsa_c), .irq(irq), .spare(spare));

  // Controller
  rsa_en_logic rsa_en_logic_i (.rstb(rst_n), .clk(clk), .ena(ena), .gpio_start(gpio_start_cmd), .spi_start(spi_start_cmd), .gpio_stop(gpio_stop_cmd), .spi_stop(spi_stop_cmd), .en_rsa(ena_rsa), .clear_rsa(clear_rsa), .eoc_rsa(eoc_rsa), .irq(irq));

  // RSA Instance
  rsa_unit #(.WIDTH(REG_WIDTH)) rsa_unit_i (.rstb(rst_n), .clk(clk), .ena(ena_rsa), .clear(clear_rsa),  .P(rsa_p), .E(rsa_e), .M(rsa_m), .Const(rsa_const), .eoc(eoc_rsa), .C(rsa_c));

endmodule
