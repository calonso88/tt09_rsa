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

  // GPIO Auxiliars
  wire gpio_start;
  wire gpio_stop;
  wire gpio_irq;
  wire gpio_start_cmd;
  wire gpio_stop_cmd;

  // SPI Auxiliars
  wire spi_cs_n;
  wire spi_clk;
  wire spi_miso;
  wire spi_mosi;
  wire cpol;
  wire cpha;
  
  // Sync'ed
  wire spi_cs_n_sync;
  wire spi_clk_sync;
  wire spi_mosi_sync;
  wire cpol_sync;
  wire cpha_sync;

  wire spi_start_cmd;
  wire spi_stop_cmd;

  // RSA En FSM Auxiliars
  wire ena_rsa;
  wire clear_rsa;
  wire eoc_rsa;
  wire irq;

  // RSA Unit size
  localparam int REG_WIDTH = 8;

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

  // MISO Output port
  assign uio_out[3] = spi_miso;
  // Unused ouputs needs to be assigned to 0.
  assign uio_out[2:0] = 3'b000;
  assign uio_out[7:4] = 4'b0000;

  // Number of stages in each synchronizer
  localparam int SYNC_STAGES = 2;
  localparam int SYNC_WIDTH = 1;

  // Synchronizers
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_cs_n_inst (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(spi_cs_n), .data_out(spi_cs_n_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_clk_inst  (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(spi_clk),  .data_out(spi_clk_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_mosi_inst (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(spi_mosi), .data_out(spi_mosi_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_mode_cpol (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(cpol), .data_out(cpol_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) synchronizer_spi_mode_cpha (.rstb(rst_n), .clk(clk), .ena(ena), .data_in(cpha), .data_out(cpha_sync));

  // Amount of CFG Regs and Status Regs + Regs Width
  localparam int NUM_CFG = 8;
  localparam int NUM_STATUS = NUM_CFG;
  //localparam int REG_WIDTH = 8;

  // Config Regs and Status Regs
  wire [NUM_CFG*REG_WIDTH-1:0] config_regs;
  wire [NUM_STATUS*REG_WIDTH-1:0] status_regs;

  // Auxiliar mapping signals
  //wire [7:0] a, b;
  //wire [3:0] s;
  //wire c_in0, m, c_out0, equal0, p0, g0;
  //wire [7:0] f;
  //wire c_out1, equal1, p1, g1;
  //wire [2:0] decod_sel;
  //wire [3:0] bin;
  //wire [7:0] decod;
  //wire [7:0] decod_reg;
  
  // Assign config regs
  //assign a = config_regs[7:0];    // [0][7:0]
  //assign b = config_regs[15:8];   // [1][7:0]
  //assign s = config_regs[19:16];  // [2][3:0]
  //assign m = config_regs[20];     // [2][4]
  //assign c_in0 = config_regs[21]; // [2][5]
                                    // [2][7:6] unused
  //assign decod_sel = config_regs[26:24]; // [3][2:0]

  // Assign status regs
  assign status_regs[7:0]   = '0;
  assign status_regs[15:8]  = '0;
  assign status_regs[23:16] = '0;
  assign status_regs[31:24] = '0;
  assign status_regs[39:32] = '0;
  assign status_regs[47:40] = '0;
  assign status_regs[55:48] = '0;
  assign status_regs[63:56] = '0;

  assign spi_start_cmd = 1'b0;
  assign spi_stop_cmd = 1'b0;

  // GPIO wrapper
  gpio_wrapper gpio_wrapper_i (.rstb(rst_n), .clk(clk), .ena(ena), .gpio_start(gpio_start), .gpio_stop(gpio_stop), .gpio_start_cmd(gpio_start_cmd), .gpio_stop_cmd(gpio_stop_cmd));

  // SPI wrapper
  spi_wrapper #(.NUM_CFG(NUM_CFG), .NUM_STATUS(NUM_STATUS), .REG_WIDTH(REG_WIDTH)) spi_wrapper_i (.rstb(rst_n), .clk(clk), .ena(ena), .mode({cpol_sync, cpha_sync}), .spi_cs_n(spi_cs_n_sync), .spi_clk(spi_clk_sync), .spi_mosi(spi_mosi_sync), .spi_miso(spi_miso), .config_regs(config_regs), .status_regs(status_regs));

  // Controller
  rsa_en_logic rsa_en_logic_i (.rstb(rst_n), .clk(clk), .ena(ena), .gpio_start(gpio_start_cmd), .spi_start(spi_start_cmd), .gpio_stop(gpio_stop_cmd), .spi_stop(spi_stop_cmd), .en_rsa(ena_rsa), .clear_rsa(clear_rsa), .eoc_rsa(eoc_rsa), .irq(irq));

  // RSA Instance
  rsa_unit #(.WIDTH(REG_WIDTH)) rsa_unit_i (.rstb(rst_n), .clk(clk), .ena(ena_rsa), .clear(clear_rsa),  .P(rsa_p), .E(rsa_e), .M(rsa_m), .Const(rsa_const), .eoc(eoc_rsa), .C(rsa_c));

endmodule