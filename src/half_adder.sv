/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module half_adder (a, b, sum, co);

  input logic a;
  input logic b;
  output logic sum;
  output logic co;

  assign sum = a ^ b;
  assign co = a & b;

endmodule