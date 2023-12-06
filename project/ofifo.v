// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module ofifo (clk, in, out, rd, wr, o_full, reset, o_ready, o_valid);

  parameter col  = 8;
  parameter bw = 4;
  parameter psum_bw = 16;

  input  clk;
  input  wr;
  input  rd;
  input  reset;
  input  [col*psum_bw-1:0] in;
  output [col*psum_bw-1:0] out;
  output o_full;
  output o_ready;
  output o_valid;

  wire [col-1:0] empty;
  wire [col-1:0] full;
  reg  [col-1:0] wr_en;
  reg [col*psum_bw-1:0] in_buffer;
  genvar i;

  assign o_ready = !o_full;
  assign o_full  = |full;
  assign o_valid = wr_en[col-1];

  for (i=0; i<col ; i=i+1) begin : col_num
      fifo #(.WIDTH(psum_bw), .DEPTH(16)) fifo_instance (
	 .r_clk(clk),
	 .w_clk(clk),
	 .i_read(rd),
	 .i_write(wr_en[i]),
         .o_empty(empty[i]),
         .o_full(full[i]),
	 .i_data(in_buffer[(i+1)*psum_bw-1:i*psum_bw]),
	 .o_data(out[(i+1)*psum_bw-1:i*psum_bw]),
         .rst(reset));
  end


  always @ (posedge clk) begin
    if (reset) begin
      wr_en <= 0;
      in_buffer <= 0;
    end
    else begin
      in_buffer <= in;
      if(wr) wr_en <= {wr_en[col-2:0], 1'b1};
      else   wr_en <= {wr_en[col-2:0], 1'b0};
    end
  end


 

endmodule
