module corelet(clk, reset, l0_in, l0_rd, l0_wr, l0_o_ready, l0_o_full, 
               ofifo_o_valid, ofifo_o_ready, ofifo_o_full, ofifo_out, ofifo_rd, 
               sfp_in, sfp_out, sfp_i_valid, inst
              );

parameter bw = 4, psum_bw = 16, col = 8, row = 8;

input clk, reset;
input [row*bw-1:0] l0_in;
input l0_rd, l0_wr;
output l0_o_ready, l0_o_full;

input ofifo_rd;
output [col*psum_bw-1:0] ofifo_out;
output ofifo_o_valid, ofifo_o_ready, ofifo_o_full;

input [psum_bw*col-1:0] sfp_in;
input sfp_i_valid;
output [psum_bw*col-1:0] sfp_out;

input [33:0] inst;

wire [row*bw-1:0] l0_out;
wire [col*psum_bw-1:0] pe_out_s;
wire [col-1:0] pe_valid;
wire [psum_bw*col-1:0] pe_in_n;
wire [psum_bw*col-1:0] ofifo_in;
wire [col-1:0] ofifo_wr;


assign ofifo_in = pe_out_s;
assign ofifo_wr = pe_valid;

mac_array PE (.clk      (clk), 
              .reset    (reset), 
              .out_s    (pe_out_s), 
              .in_w     (l0_out), 
              .in_n     (pe_in_n), 
              .inst_w   (inst[1:0]), 
              .valid    (pe_valid)
             );

l0 L0 (.clk     (clk), 
       .in      (l0_in), 
       .out     (l0_out), 
       .rd      (l0_rd), 
       .wr      (l0_wr), 
       .o_full  (l0_o_full), 
       .reset   (reset), 
       .o_ready (l0_o_ready)
      );

ofifo OFIFO (.clk       (clk), 
             .in        (ofifo_in), 
             .out       (ofifo_out), 
             .rd        (ofifo_rd), 
             .wr        (ofifo_wr), 
             .o_full    (ofifo_o_full), 
             .reset     (reset), 
             .o_ready   (ofifo_o_ready), 
             .o_valid   (ofifo_o_valid)
            );

sfp_col SFP (.clk    (clk),
             .reset  (reset),
             .in     (sfp_in),
             .out    (sfp_out),
             .i_valid(sfp_i_valid)
            );

endmodule