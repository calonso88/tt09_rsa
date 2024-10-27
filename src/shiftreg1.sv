/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module shiftreg1 #(parameter int WIDTH = 4) (rstb, clk, ena, clear, load, A, A_bit);

  input logic rstb;
  input logic clk;
  input logic ena;
  input logic clear;
  input logic load;
  input logic [WIDTH-1:0] A;

  output logic A_bit;

  logic [WIDTH-1:0] A_aux;

  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      A_aux <= '0;
    end else begin
      if (ena == 1'b1) begin
        if (clear == 1'b0) begin
          A_aux <= '0;
        end else begin
          if (load == 1'b1) begin
            A_aux <= A;
          end else begin
            A_aux <= {A_aux >> 1};
          end
        end
      end
    end
  end

  assign A_bit = A_aux[0];

endmodule