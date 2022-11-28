`ifndef CONSTANTS
  `define CONSTANTS
  `include "constants.v"
`endif

module op_decoder (
  input wire clk,
  input wire rst,
  input wire [3:0] inbits,
  output reg move_next,
  output reg stack_accept,
  output reg stack_pop
);

  reg [2:0] op_progress;
  reg [3:0] curop;

  always @ (posedge clk) begin
    if (rst) begin
      op_progress <= 0;
      curop <= 0;
      move_next <= 1;
      stack_accept <= 0;
      stack_pop <= 0;
    end
    else begin
      op_progress <= op_progress + 1;

      if (move_next == 1) begin
        curop <= inbits;
        op_progress <= 0;
        move_next <= 0;
        stack_accept <= 0;
      end
      else if (curop == 1) begin
        move_next <= 0;
        if (op_progress == 0) begin
          stack_accept <= 1;
          move_next <= 1;
        end
      end
      else if (curop == 2) begin
        move_next <= 0;
        if (op_progress == 0) begin
          stack_pop <= 1;
          move_next <= 1;
        end
      end
      else begin
        move_next <= 1;
      end

    end
  end

endmodule

module mode_decoder (
  input wire [2:0] mode,
  output wire rst
);

  assign rst = mode[0] & mode[1] & mode[2];
endmodule

module memory (
  input clk,
  input rst,
  input mode,
  input [3:0] address,
  input [3:0] data_in,
  output reg [3:0] data_out
);
  
  reg [3:0] memory_cell0;
  reg [3:0] memory_cell1;
  reg [3:0] memory_cell2;
  reg [3:0] memory_cell3;
  reg [3:0] memory_cell4;
  reg [3:0] memory_cell5;
  reg [3:0] memory_cell6;
  reg [3:0] memory_cell7;

  reg [3:0] memory_cell8;
  reg [3:0] memory_cell9;
  reg [3:0] memory_cella;
  reg [3:0] memory_cellb;
  reg [3:0] memory_cellc;
  reg [3:0] memory_celld;
  reg [3:0] memory_celle;
  reg [3:0] memory_cellf;

  always @ (posedge clk) begin
    if (rst) begin
      data_out <= 0;
    end
    else if (mode == 0) begin
      case(address)
        4'b0000: data_out <= memory_cell0;
        4'b0001: data_out <= memory_cell1;
        4'b0010: data_out <= memory_cell2;
        4'b0011: data_out <= memory_cell3;
        4'b0100: data_out <= memory_cell4;
        4'b0101: data_out <= memory_cell5;
        4'b0110: data_out <= memory_cell6;
        4'b0111: data_out <= memory_cell7;

        4'b1000: data_out <= memory_cell8;
        4'b1001: data_out <= memory_cell9;
        4'b1010: data_out <= memory_cella;
        4'b1011: data_out <= memory_cellb;
        4'b1100: data_out <= memory_cellc;
        4'b1101: data_out <= memory_celld;
        4'b1110: data_out <= memory_celle;
        4'b1111: data_out <= memory_cellf;
      endcase;
    end
    else if (mode == 1) begin
      case(address)
        4'b0000: memory_cell0 <= data_in;
        4'b0001: memory_cell1 <= data_in;
        4'b0010: memory_cell2 <= data_in;
        4'b0011: memory_cell3 <= data_in;
        4'b0100: memory_cell4 <= data_in;
        4'b0101: memory_cell5 <= data_in;
        4'b0110: memory_cell6 <= data_in;
        4'b0111: memory_cell7 <= data_in;

        4'b1000: memory_cell8 <= data_in;
        4'b1001: memory_cell9 <= data_in;
        4'b1010: memory_cella <= data_in;
        4'b1011: memory_cellb <= data_in;
        4'b1100: memory_cellc <= data_in;
        4'b1101: memory_celld <= data_in;
        4'b1110: memory_celle <= data_in;
        4'b1111: memory_cellf <= data_in;
      endcase;
    end
  end

endmodule

module stack_register #(
  parameter DEPTH=4
) (
  input clk,
  input rst,
  input stack_accept,
  input stack_pop,
  input wire [3:0] in,
  output wire [3:0] v0, v1
);

  reg [DEPTH*4-1:0] entire_stack;

  assign v0 = entire_stack[3:0];
  assign v1 = entire_stack[7:4];

  always @ (posedge clk) begin
    if (rst) begin
      entire_stack <= 0;
    end
    else if (stack_accept) begin
      // push
      entire_stack <= { entire_stack[(DEPTH-1)*4-1:0], in };
    end
    else if (stack_pop) begin
      // pop
      entire_stack <= { 4'b0000, entire_stack[DEPTH*4-1:4] };
    end
    else begin
      entire_stack <= entire_stack;
    end
  end

endmodule

module stack_cpu (
  input wire [7:0] io_in,
  output wire [7:0] io_out
);
  // define the inputs
  wire clk;
  wire [3:0] inbits;
  wire [2:0] mode;

  // assign the inputs
  assign clk = io_in[0];
  assign inbits = io_in[5:2];
  assign mode = { io_in[1], io_in[7:6] };

  // ===== PROCESSOR STATE =====
  // input latch
  reg [7:0] in_dff;

  // output latch
  reg [7:0] out_dff;
  // ===== PROCESSOR STATE =====

  // reset
  wire rst;
  mode_decoder mode_dec(
    .mode(mode),
    .rst(rst)
  );

  wire move_next;
  wire stack_accept;
  op_decoder dec(
    .clk(clk),
    .rst(rst),
    .inbits(inbits),
    .move_next(move_next),
    .stack_accept(stack_accept),
    .stack_pop(stack_pop)
  );

  wire [3:0] v0, v1;
  stack_register #(
    .DEPTH(8)
  ) stack (
    .clk(clk),
    .rst(rst),
    .stack_accept(stack_accept),
    .stack_pop(stack_pop),
    .in(in_dff[3:0]),
    .v0(v0), .v1(v1)
  );

  reg [3:0] ram_address;
  wire [3:0] ram_out;
  reg write;
  memory ram(
    .clk(clk),
    .rst(rst),
    .mode(write),
    .address(ram_address),
    .data_in(v0),
    .data_out(ram_out)
  );
  
  reg [3:0] program_counter;
  always @ (posedge clk) begin
    if (rst) begin
      in_dff <= 0;
      out_dff <= 0;
      program_counter <= 0;
      ram_address <= 0;
      write <= 0;

    end
    else begin
      in_dff <= { in_dff[3:0], inbits };

      if (move_next) begin
        program_counter <= program_counter + 1;
      end

    end

  end

  output_multiplexer outputter(
    .a(out_dff),
    .b({4'h0, inbits}),
    .c({4'h0, in_dff[7:4]}),
    .d({v1, v0}),
    .e(8'hff),
    .f(8'hff),
    .g(8'hff),
    .h(8'h00),
    .output_mode(mode),
    .q(io_out)
  );

endmodule

