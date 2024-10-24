/*
 * Copyright (c) 2024 Caio Alonso da Costa
 * SPDX-License-Identifier: Apache-2.0
 */

module rsa_control #(parameter int WIDTH = 8) (rstb, clk, ena, clear, E, clear_mmm, ld_a, ld_r, lock1, lock2, sel1, sel2, eoc);

  input logic rstb;
  input logic clk;
  input logic ena;
  input logic clear;
  input logic [WIDTH-1:0] E;

  output logic clear_mmm;
  output logic ld_a;
  output logic ld_r;
  output logic lock1;
  output logic lock2;
  output logic [1:0] sel1;
  output logic sel2;
  output logic eoc;

  logic [WIDTH-1:0] exp;
  logic clear_exp;
  logic load_exp;
  logic shift_exp;

  logic [($clog2(WIDTH-1))-1:0] counter_steps;
  logic [($clog2(WIDTH-1))-1:0] counter_rounds;
  logic clear_counter_steps;
  logic clear_counter_rounds;
  logic increment_steps;
  logic increment_rounds;
  logic [($clog2(WIDTH-1))-1:0] const_counter_compare;

  // FSM states type
  typedef enum logic [3:0] {
    STATE_RESET, STATE_PRE_MAP, STATE_MAP, STATE_POST_MAP, STATE_PRE_MMM, STATE_MMM, STATE_POST_MMM, STATE_PRE_REMAP, STATE_REMAP, POST_REMAP, STATE_EOC, STATE_IDLE
  } fsm_control_state;

  // FSM states
  fsm_control_state state, next_state;

  // Value for comparison
  assign const_counter_compare = WIDTH-1;

  // Counter steps
  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      counter_steps <= '0;
    end else begin
      if (ena == 1'b1) begin
        if (clear_counter_steps == 1'b1) begin
          counter_steps <= '0;
        end else if (increment_steps == 1'b1) begin
          counter_steps <= counter_steps + 1'b1;
        end
      end
    end
  end

  // Counter rounds
  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      counter_rounds <= '0;
    end else begin
      if (ena == 1'b1) begin
        if (clear_counter_rounds == 1'b1) begin
          counter_rounds <= '0;
        end else if (increment_rounds == 1'b1) begin
          counter_rounds <= counter_rounds + 1'b1;
        end
      end
    end
  end

  // Exponent shift register
  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      exp <= '0;
    end else begin
      if (ena == 1'b1) begin
        if (clear_exp == 1'b0) begin
          exp <= '0;
        end else if (load_exp == 1'b1) begin
          exp <= E;
        end else if (shift_exp == 1'b1) begin
          exp <= (exp >> 1);
        end
      end
    end
  end

  // Next state transition
  always_ff @(negedge(rstb) or posedge(clk)) begin
    if (!rstb) begin
      state <= STATE_RESET;
    end else begin
      if (ena == 1'b1) begin
        if (clear == 1'b0) begin
          state <= STATE_RESET;
        end else begin
          state <= next_state;
        end
      end
    end
  end

  always_comb begin

    // default assignments
    clear_mmm = 1'b0;
    ld_a = 1'b0;
    ld_r = 1'b0;
    lock1 = 1'b0;
    lock2 = 1'b0;
    sel1 = 2'b00;
    sel2 = 1'b0;
    clear_exp = 1'b0;
    shift_exp = 1'b0;
    eoc = 1'b0;
    load_exp = 1'b0;
    clear_counter_steps = 1'b0;
    clear_counter_rounds = 1'b0;
    increment_steps = 1'b0;
    increment_rounds = 1'b0;
    next_state = state;

    case (state)

      STATE_RESET : begin
        clear_mmm = 1'b0;
        ld_a = 1'b0;
        ld_r = 1'b0;
        lock1 = 1'b0;
        lock2 = 1'b0;
        sel1 = 2'b00;
        sel2 = 1'b0;
        clear_exp = 1'b0;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_PRE_MAP;
      end

      STATE_PRE_MAP : begin
        clear_mmm = 1'b1;
        ld_a = 1'b1;
        ld_r = 1'b0;
        lock1 = 1'b1;
        lock2 = 1'b1;
        sel1 = 2'b00;
        sel2 = 1'b0;
        clear_exp = 1'b0;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_MAP;
      end

      STATE_MAP : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b0;
        lock1 = 1'b1;
        lock2 = 1'b1;
        sel1 = 2'b00;
        sel2 = 1'b0;
        clear_exp = 1'b0;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b1;
        increment_rounds = 1'b0;
        if ( counter_steps == const_counter_compare ) begin
          next_state = STATE_POST_MAP;
        end else begin
          next_state = STATE_MAP;
        end
      end

      STATE_POST_MAP : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b1;
        lock1 = 1'b1;
        lock2 = 1'b1;
        sel1 = 2'b00;
        sel2 = 1'b0;
        clear_exp = 1'b1;
        shift_exp = 1'b1;
        eoc = 1'b0;
        load_exp = 1'b1;
        clear_counter_steps = 1'b1;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_PRE_MMM;
      end

      STATE_PRE_MMM : begin
        clear_mmm = 1'b1;
        ld_a = 1'b1;
        ld_r = 1'b0;
        lock1 = exp[0];
        lock2 = 1'b1;
        sel1 = 2'b01;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_MMM;
      end

      STATE_MMM : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b0;
        lock1 = exp[0];
        lock2 = 1'b1;
        sel1 = 2'b01;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b1;
        increment_rounds = 1'b0;
        if ( counter_steps == const_counter_compare ) begin
          next_state = STATE_POST_MMM;
        end else begin
          next_state = STATE_MMM;
        end
      end

      STATE_POST_MMM : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b1;
        lock1 = exp[0];
        lock2 = 1'b1;
        sel1 = 2'b01;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b1;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b1;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b1;
        if ( counter_rounds == const_counter_compare ) begin
          next_state = STATE_PRE_REMAP;
        end else begin
          next_state = STATE_PRE_MMM;
        end
      end

      STATE_PRE_REMAP : begin
        clear_mmm = 1'b1;
        ld_a = 1'b1;
        ld_r = 1'b0;
        lock1 = 1'b1;
        lock2 = 1'b0;
        sel1 = 2'b10;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_REMAP;
      end

      STATE_REMAP : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b0;
        lock1 = 1'b1;
        lock2 = 1'b0;
        sel1 = 2'b10;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b1;
        increment_rounds = 1'b0;
        if ( counter_steps == const_counter_compare ) begin
          next_state = POST_REMAP;
        end else begin
          next_state = STATE_REMAP;
        end
      end

      POST_REMAP : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b1;
        lock1 = 1'b1;
        lock2 = 1'b0;
        sel1 = 2'b10;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_EOC;
      end

      STATE_EOC : begin
        clear_mmm = 1'b1;
        ld_a = 1'b0;
        ld_r = 1'b1;
        lock1 = 1'b1;
        lock2 = 1'b0;
        sel1 = 2'b10;
        sel2 = 1'b1;
        clear_exp = 1'b1;
        shift_exp = 1'b0;
        eoc = 1'b1;
        load_exp = 1'b0;
        clear_counter_steps = 1'b1;
        clear_counter_rounds = 1'b1;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_IDLE;
      end

      STATE_IDLE : begin
        clear_mmm = 1'b0;
        ld_a = 1'b0;
        ld_r = 1'b0;
        lock1 = 1'b0;
        lock2 = 1'b0;
        sel1 = 2'b10;
        sel2 = 1'b0;
        clear_exp = 1'b0;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = STATE_IDLE;
      end

      default : begin
        clear_mmm = 1'b0;
        ld_a = 1'b0;
        ld_r = 1'b0;
        lock1 = 1'b0;
        lock2 = 1'b0;
        sel1 = 2'b00;
        sel2 = 1'b0;
        clear_exp = 1'b0;
        shift_exp = 1'b0;
        eoc = 1'b0;
        load_exp = 1'b0;
        clear_counter_steps = 1'b0;
        clear_counter_rounds = 1'b0;
        increment_steps = 1'b0;
        increment_rounds = 1'b0;
        next_state = state;
      end

    endcase

  end

endmodule