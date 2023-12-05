// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
module mac_tile (clk, out_s, in_w, out_e, in_n, inst_w, inst_e, reset);

parameter bw = 4;
parameter psum_bw = 16;

output [psum_bw-1:0] out_s;
input  [bw-1:0] in_w; // inst[1]:execute, inst[0]: kernel loading
output [bw-1:0] out_e; 
input  [1:0] inst_w;
output [1:0] inst_e;
input  [psum_bw-1:0] in_n;
input  clk;
input  reset;

reg [bw-1:0] a, b, b1, b2, a_q, b_q, b1_q, b2_q;
reg [psum_bw-1:0] c, c_q;
wire [psum_bw-1:0] mac_out;
reg [1:0] load_ready, load_ready_q;
reg [1:0] inst, inst_q;
reg [psum_bw-1:0] mac_out_q;
reg  exe_counter, exe_counter_q;

assign out_e = a_q;
assign inst_e = inst_q;
// assign mac_out_q = mac_out;
assign out_s = mac_out;
mac #(.bw(bw), .psum_bw(psum_bw)) mac_instance (
        .a(a_q), 
        .b(b_q),
        .c(c_q),
	.out(mac_out)
); 
always @(*) begin
        inst[1] = inst_w[1];
        a = (inst_w) ? in_w : a_q;
        b1 = (inst_w[0] && load_ready_q[1]) ? in_w : b1_q;
        b2 = (inst_w[0] && load_ready_q[0]) ? in_w : b2_q;
        b = (exe_counter_q && inst_w[1]) ? b1 : ((inst_w[1]) ? b2 : b_q);
        load_ready = (inst_w[0] && load_ready_q) ? load_ready_q-1 : load_ready_q;
        inst[0] = (load_ready_q == 2'b00) ? inst_w[0] : inst_q[0];
        c = (exe_counter_q && inst_w[1]) ? in_n : (inst_w[1] ? mac_out : c_q);
        exe_counter = (inst_w[1]) ? exe_counter_q + 1 : exe_counter_q;
end
always @(posedge clk) begin
        if(reset) begin
                a_q <= 0;
                b_q <= 0;
                b1_q <= 0;
                b2_q <= 0;
                c_q <= 0;
                inst_q <= 0;
                load_ready_q <= 2'b10;
                exe_counter_q <= 1;
        end
        else begin
                inst_q <= inst;
                a_q <= a;
                b1_q <= b1;
                b2_q <= b2;
                b_q <= b;
                c_q <= c;
                load_ready_q <= load_ready;
                exe_counter_q <= exe_counter;
        end
end

endmodule
