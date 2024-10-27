/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module ripple_carry_adder #(parameter int WIDTH = 4) (a, b, ci, sum, co);

  input logic [WIDTH-1:0] a;
  input logic[WIDTH-1:0] b;
  input logic ci;
  output logic[WIDTH-1:0] sum;
  output logic co;

  logic [WIDTH-1:0] carry;

  full_adder fa_bit0 (.a(a[0]), .b(b[0]), .ci(ci), .sum(sum[0]), .co(carry[0]));

  generate
    for (genvar i=1; i<WIDTH; i++) begin : gen_fa
      full_adder fa (.a(a[i]), .b(b[i]), .ci(carry[i-1]), .sum(sum[i]), .co(carry[i]));
    end
  endgenerate

  assign co = carry[WIDTH-1];

endmodule