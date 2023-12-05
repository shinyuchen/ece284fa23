module sfp_col(clk, reset, in, out, i_valid);

parameter psum_bw = 16, row = 8, col = 8;

input clk, reset;
input [psum_bw*col-1:0] in;
output [psum_bw*col-1:0] out;
input i_valid;

genvar i;
for(i=0; i<col; i=i+1) begin : SFP
    sfp sfp_instance(.clk(clk), .reset(reset), .i_valid(i_valid), 
                     .in(in[psum_bw*(i+1)-1:psum_bw*i]), .out(out[psum_bw*(i+1)-1:psum_bw*i]));
end

endmodule