/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module rsa_unit #(parameter int WIDTH = 8) (rstb, clk, ena, clear, P, E, M, Const, C, eoc);

  input logic rstb;
  input logic clk;
  input logic ena;
  input logic clear;

  input logic [WIDTH-1:0] P;
  input logic [WIDTH-1:0] E;
  input logic [WIDTH-1:0] M;
  input logic [WIDTH-1:0] Const;

  output logic [WIDTH-1:0] C;
  output logic eoc;

  logic clear_mmm;
  logic ld_a;
  logic ld_r;
  logic lock_multiply;
  logic lock_square;
  logic [1:0] sel_multiply;
  logic sel_square;
  logic [WIDTH+1:0] multilpy_a;
  logic [WIDTH+1:0] multilpy_b;
  logic [WIDTH+1:0] square_a;
  logic [WIDTH+1:0] square_b;
  logic [WIDTH+1:0] R_i;
  logic [WIDTH+1:0] P_i;

  logic [WIDTH+1:0] P_ex;
  logic [WIDTH+1:0] E_ex;
  logic [WIDTH+1:0] M_ex;
  logic [WIDTH+1:0] C_ex;
  logic [WIDTH+1:0] Const_ex;

  assign P_ex = {{((WIDTH+1)-(WIDTH-1)){1'b0}}, P};
  assign E_ex = {{((WIDTH+1)-(WIDTH-1)){1'b0}}, E};
  assign M_ex = {{((WIDTH+1)-(WIDTH-1)){1'b0}}, M};
  assign Const_ex = {{((WIDTH+1)-(WIDTH-1)){1'b0}}, Const};
  assign C = C_ex[WIDTH-1:0];

  mux1_unit #(.WIDTH(WIDTH+2)) mux_multiply_a (.a(Const_ex), .b(R_i), .sel(sel_multiply), .dout(multilpy_a));

  mux2_unit #(.WIDTH(WIDTH+2)) mux_multiply_b (.a(P_i), .b(R_i), .sel(sel_multiply), .dout(multilpy_b));

  mmm_unit #(.WIDTH(WIDTH+2)) mmm_multiply (.ena(ena), .rstb(rstb), .clk(clk), .clear(clear_mmm), .ld_a(ld_a), .ld_r(ld_r), .lock(lock_multiply), .A(multilpy_a), .B(multilpy_b), .M(M_ex), .R(R_i));

  mux3_unit #(.WIDTH(WIDTH+2)) mux_square_a (.a(Const_ex), .b(P_i), .sel(sel_square), .dout(square_a));

  mux3_unit #(.WIDTH(WIDTH+2)) mux_square_b (.a(P_ex), .b(P_i), .sel(sel_square), .dout(square_b));

  mmm_unit #(.WIDTH(WIDTH+2)) mmm_square (.ena(ena), .rstb(rstb), .clk(clk), .clear(clear_mmm), .ld_a(ld_a), .ld_r(ld_r), .lock(lock_square), .A(square_a), .B(square_b), .M(M_ex), .R(P_i));

  rsa_control #(.WIDTH(WIDTH+2)) rsa_control_fsm (.ena(ena), .rstb(rstb), .clk(clk), .clear(clear), .E(E_ex), .clear_mmm(clear_mmm), .ld_a(ld_a), .ld_r(ld_r), .lock1(lock_multiply), .lock2(lock_square), .sel1(sel_multiply), .sel2(sel_square), .eoc(eoc));

  register_crypt #(.WIDTH(WIDTH+2)) reg_crypt (.ena(ena), .rstb(rstb), .clk(clk), .clear(1'b1), .load(eoc), .R_i(R_i), .C_ex(C_ex));

endmodule