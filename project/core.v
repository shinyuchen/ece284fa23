module core (clk, inst, ofifo_valid, D_xmem, sfp_out, reset); 

    parameter bw = 3'd4, psum_bw = 16, col = 4'd8, row = 4'd8;

    input clk, reset;
    input [33:0] inst;
    input [bw*row-1:0] D_xmem;
    output ofifo_valid;
    output [psum_bw*col-1:0] sfp_out;

    wire [row*bw-1:0] l0_in; 
    wire l0_rd, l0_wr, l0_o_ready, l0_o_full;
    wire ofifo_o_ready, ofifo_o_full, ofifo_o_valid, ofifo_rd;
    wire [psum_bw*col-1:0] ofifo_out;
    wire [psum_bw*col-1:0] sfp_in;
    wire sfp_i_valid;
    reg [33:0] inst_q_q;
    always @(posedge clk) begin
        inst_q_q <= (reset) ? 0 : inst;
    end
    assign l0_rd = (inst_q[3] || inst_q[4]);
    assign l0_wr = (inst_q[2] || inst_q[5]);
    assign ofifo_rd = inst_q[6];
    assign sfp_i_valid = inst_q[33];

    assign ofifo_valid = ofifo_o_valid;

    corelet Corelet
    (.clk(clk), .reset(reset), 
     .l0_in(l0_in), .l0_rd(l0_rd), .l0_wr(l0_wr), .l0_o_ready(l0_o_ready), .l0_o_full(l0_o_full), 
     .sfp_in(sfp_in), .sfp_i_valid(sfp_i_valid), .sfp_out(sfp_out), 
     .ofifo_o_valid(ofifo_o_valid), .ofifo_o_ready(ofifo_o_ready), 
     .ofifo_o_full(ofifo_o_full), .ofifo_out(ofifo_out), .ofifo_rd(ofifo_rd), 
     .inst_q(inst_q)
    );

    sram_32b_w2048 data_SRAM (.CLK(clk), .D(D_xmem), .Q(l0_in), .CEN(inst_q[19]), .WEN(inst_q[18]), .A(inst_q[17:7])); 

    sram_128b_w2048 psum_SRAM (.CLK(clk), .D(ofifo_out), 
                               .Q(sfp_in), 
                               .CEN(inst_q[32]), .WEN(inst_q[31]), .A(inst_q[30:20]));



endmodule