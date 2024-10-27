/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

 module rsa_en_logic (rstb, clk, ena, gpio_start, spi_start, gpio_stop, spi_stop, en_rsa, clear_rsa, eoc_rsa, irq);

  // Inputs
  input logic rstb;
  input logic clk;
  input logic ena;

  // GPIO
  input logic gpio_start;
  input logic gpio_stop;

  // SPI cmd
  input logic spi_start;
  input logic spi_stop;

  // Control outputs for rsa_unit
  output logic en_rsa;
  output logic clear_rsa;

  // End of convertion (encryption from rsa_unit)
  input logic eoc_rsa;
  // IRQ (for GPIO and SPI)
  output logic irq;

  // FSM states type
  typedef enum logic [2:0] {
    STATE_RESET, STATE_IDLE, STATE_EN, STATE_CLEAR_RELEASE, STATE_WAIT_EOC, STATE_IRQ
  } rsa_fsm_state;

  // FSM states
  rsa_fsm_state state, next_state;

  // Auxiliar logic
  logic start_comb;
  logic stop_comb;
  logic en_rsa_i;
  logic clear_rsa_i;
  logic irq_i;

  // Combine both GPIO and SPI
  assign start_comb = gpio_start | spi_start;
  assign stop_comb = gpio_stop | spi_stop;

  // Outputs
  assign en_rsa = en_rsa_i;
  assign clear_rsa = clear_rsa_i;
  assign irq = irq_i;

  // Next state transition
  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      state <= STATE_RESET;
    end else begin
      if (ena == 1'b1) begin
        state <= next_state;
      end
    end
  end

  always_comb begin

    // default assignments
    en_rsa_i = 1'b0;
    clear_rsa_i = 1'b0;
    irq_i = 1'b0;
    next_state = state;

    case (state)

      STATE_RESET : begin
        en_rsa_i = 1'b0;
        clear_rsa_i = 1'b0;
        irq_i = 1'b0;
        next_state = STATE_IDLE;
      end

      STATE_IDLE : begin
        en_rsa_i = 1'b0;
        clear_rsa_i = 1'b0;
        irq_i = 1'b0;
        if (start_comb == 1'b1) begin
          next_state = STATE_EN;
        end else begin
          next_state = STATE_IDLE;
        end
      end

      STATE_EN : begin
        en_rsa_i = 1'b1;
        clear_rsa_i = 1'b0;
        irq_i = 1'b0;
        if (stop_comb == 1'b1) begin
          next_state = STATE_IDLE;
        end else begin
          next_state = STATE_CLEAR_RELEASE;
        end
      end

      STATE_CLEAR_RELEASE : begin
        en_rsa_i = 1'b1;
        clear_rsa_i = 1'b1;
        irq_i = 1'b0;
        if (stop_comb == 1'b1) begin
          next_state = STATE_IDLE;
        end else begin
          next_state = STATE_WAIT_EOC;
        end
      end

      STATE_WAIT_EOC : begin
        en_rsa_i = 1'b1;
        clear_rsa_i = 1'b1;
        irq_i = 1'b0;
        if (stop_comb == 1'b1) begin
          next_state = STATE_IDLE;
        end else begin
          if (eoc_rsa == 1'b1) begin
            next_state = STATE_IRQ;
          end else begin
            next_state = STATE_WAIT_EOC;
          end
        end
      end

      STATE_IRQ : begin
        en_rsa_i = 1'b1;
        clear_rsa_i = 1'b1;
        irq_i = 1'b1;
        next_state = STATE_IDLE;
      end

      default : begin
        en_rsa_i = 1'b0;
        clear_rsa_i = 1'b0;
        irq_i = 1'b0;
        next_state = STATE_RESET;
      end

    endcase

  end

endmodule