/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module shiftreg2 #(parameter int WIDTH = 4) (rstb, clk, ena, clear, load, rjo, reg_rji);

  input logic rstb;
  input logic clk;
  input logic ena;
  input logic clear;
  input logic load;
  input logic [WIDTH-1:0] rjo;

  output logic [WIDTH-1:0] reg_rji;

  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      reg_rji <= '0;
    end else begin
      if (ena == 1'b1) begin
        if (load == 1'b1 || clear == 1'b0) begin
          reg_rji <= '0;
        end else begin
          reg_rji <= (rjo >> 1);
        end
      end
    end
  end

endmodule