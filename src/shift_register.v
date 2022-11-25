// not really a shift register. some beast now
`ifndef CONSTANTS
   `define CONSTANTS
   `include "constants.v"
`endif  

module shift_register #(parameter SIZE=8) (
  input d,
  input clk,
  input [2:0] mode,
  output reg [SIZE-1:0] q);

  always @ (posedge clk) begin
    case(mode)
      `STACK_MODE_IDLE : q <= q;
      `STACK_MODE_PUSH : q <= { q[SIZE-2:0], d };
      `STACK_MODE_POP  : q <= { 1'b0, q[SIZE-1:1] };
      `STACK_MODE_SWAP : q <= { q[SIZE-1:2], q[0], q[1] };
      `STACK_MODE_RESET: q <= 0;

      default: q <= q;
    endcase;
  end
endmodule
