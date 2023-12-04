module sfp(clk, reset, in, out, i_valid);

parameter psum_bw = 16, row = 8;

input clk, reset;
input signed [psum_bw-1:0] in;
input i_valid;
output signed [psum_bw-1:0] out;

reg signed [psum_bw-1:0] acc, acc_nxt;

always @(*) begin
    acc_nxt = (i_valid) ? acc + in : acc;
end
assign out = (acc > 0) ? acc : 0;

always @(posedge clk) begin
    if(reset) begin
        acc <= 0;
    end
    else begin
        acc <= acc_nxt;
    end
end

endmodule