/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module gpio_wrapper (rstb, clk, ena, gpio_start, gpio_stop, gpio_start_cmd, gpio_stop_cmd);

  input logic rstb;
  input logic clk;
  input logic ena;

  // GPIOs
  input logic gpio_start;
  input logic gpio_stop;

  // Commands
  output logic gpio_start_cmd;
  output logic gpio_stop_cmd;

  // Auxiliars
  logic gpio_start_sync;
  logic gpio_stop_sync;

  // Number of stages in each synchronizer
  localparam int SYNC_STAGES = 2;
  localparam int SYNC_WIDTH = 1;

  // Synchronizers
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) sync_gpio_start (.rstb(rstb), .clk(clk), .ena(ena), .data_in(gpio_start), .data_out(gpio_start_sync));
  synchronizer #(.STAGES(SYNC_STAGES), .WIDTH(SYNC_WIDTH)) sync_gpio_stop (.rstb(rstb), .clk(clk), .ena(ena), .data_in(gpio_stop), .data_out(gpio_stop_sync));

  // GPIO commands
  rising_edge_detector gpio_start_cmd_i (.rstb(rstb), .clk(clk), .ena(ena), .data(gpio_start_sync), .pos_edge(gpio_start_cmd));
  rising_edge_detector gpio_stop_cmd_i (.rstb(rstb), .clk(clk), .ena(ena), .data(gpio_stop_sync), .pos_edge(gpio_stop_cmd));

endmodule
