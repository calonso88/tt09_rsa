/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module mmm_unit #(parameter int WIDTH = 4) (rstb, clk, ena, clear, ld_a, ld_r, lock, A, B, M, R);

  input logic rstb;
  input logic clk;
  input logic ena;
  input logic clear;
  input logic ld_a;
  input logic ld_r;
  input logic lock;

  input logic [WIDTH-1:0] A;
  input logic [WIDTH-1:0] B;
  input logic [WIDTH-1:0] M;
  output logic [WIDTH-1:0] R;

  logic [WIDTH-1:0] MB;

  logic A_bit;
  logic [WIDTH-1:0] reg_rji;
  logic qj;
  logic [WIDTH-1:0] mux_out;
  logic [WIDTH-1:0] rjo;
  logic [WIDTH-1:0] R_i;

  ripple_carry_adder #(.WIDTH(WIDTH)) adder1 (.a(B), .b(M), .ci(1'b0), .sum(MB), .co());

  generate
    for (genvar j=0; j<=(WIDTH-1); j++) begin : processing_elements_array_loop
      if (j == 0) begin : processing_element_right_border
        processing_element_mux_right_border PE (.mi(M[j]), .bi(B[j]), .mbi(MB[j]), .ai(A_bit), .ri(reg_rji[j]), .qo(qj), .mux_out(mux_out[j]));
      end else begin : processing_element
        processing_element_mux PE (.mi(M[j]), .bi(B[j]), .mbi(MB[j]), .ai(A_bit), .qi(qj), .mux_out(mux_out[j]));
      end
    end
  endgenerate

  ripple_carry_adder #(.WIDTH(WIDTH)) adder2 (.a(reg_rji), .b(mux_out), .ci(1'b0), .sum(rjo), .co());

  shiftreg1 #(.WIDTH(WIDTH)) shiftreg_A_aux   (.ena(ena), .rstb(rstb), .clk(clk), .clear(clear), .load(ld_a), .A(A), .A_bit(A_bit));
  shiftreg2 #(.WIDTH(WIDTH)) shiftreg_reg_rji (.ena(ena), .rstb(rstb), .clk(clk), .clear(clear), .load(ld_a), .rjo(rjo), .reg_rji(reg_rji));
  shiftreg3 #(.WIDTH(WIDTH)) shiftreg_result  (.ena(ena), .rstb(rstb), .clk(clk), .clear(clear), .load(ld_r), .lock(lock), .reg_rji(reg_rji), .A(A), .R_i(R_i));

  assign R = R_i;

endmodule