// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module l0 (clk, in, out, rd, wr, o_full, reset, o_ready);

  parameter row  = 8;
  parameter bw = 4;

  input  clk;
  input  wr;
  input  rd;
  input  reset;
  input  [row*bw-1:0] in;
  output [row*bw-1:0] out;
  output o_full;
  output o_ready;

  wire [row-1:0] empty;
  wire [row-1:0] full;
  reg [row-1:0] rd_en;
  
  genvar i;

  assign o_ready = !o_full;
  assign o_full  = |full;


  for (i=0; i<row ; i=i+1) begin : row_num
      fifo #(.WIDTH(bw), .DEPTH(64)) fifo_instance (
	 .r_clk(clk),
	 .w_clk(clk),
	 .i_read(rd_en[i]),
	 .i_write(wr),
         .o_empty(empty[i]),
         .o_full(full[i]),
	 .i_data(in[(i+1)*bw-1:i*bw]),
	 .o_data(out[(i+1)*bw-1:i*bw]),
         .rst(reset));
  end


  always @ (posedge clk) begin
   if (reset) begin
      rd_en <= 8'b00000000;
   end
   else begin
      if(rd) rd_en <= {rd_en[row-2:0], 1'b1};
      else rd_en <= {rd_en[row-2:0], 1'b0};
   end
  end

endmodule
