module output_multiplexer (
  input [7:0] a, b, c, d, e, f, g, h,
  input [2:0] output_mode,
  output reg [7:0] q
);
  always @ (*) begin
    casez(output_mode)
      3'b000: q = a;
      3'b001: q = b;
      3'b010: q = c;
      3'b011: q = d;
      3'b100: q = e;
      3'b101: q = f;
      3'b110: q = g;
      3'b111: q = h;
      default: q = 8'h00;
    endcase;
  end
endmodule
