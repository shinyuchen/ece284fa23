module core (clk, inst, ofifo_valid, D_xmem, D_wmem, sfp_out, reset); 

    parameter bw = 3'd4, psum_bw = 16, col = 4'd8, row = 4'd8;

    input clk, reset;
    input [46:0] inst;
    input [bw*row-1:0] D_xmem;
    input [bw*row-1:0] D_wmem;
    output ofifo_valid;
    output [psum_bw*col-1:0] sfp_out;

    wire [row*bw-1:0] l0_in; 
    wire l0_rd, l0_wr, l0_o_ready, l0_o_full;
    wire ofifo_o_ready, ofifo_o_full, ofifo_o_valid, ofifo_rd;
    wire [psum_bw*col-1:0] ofifo_out;
    wire [psum_bw*col-1:0] sfp_in;
    wire sfp_i_valid;
    wire [31:0] weight_SRAM_out;
    wire [31:0] act_SRAM_out;
    assign l0_in = (inst[2]) ? act_SRAM_out : weight_SRAM_out;
    assign l0_rd = (inst[3] || inst[4]);
    assign l0_wr = (inst[2] || inst[5]);
    assign ofifo_rd = inst[6];
    assign sfp_i_valid = inst[33];

    assign ofifo_valid = ofifo_o_valid;

    corelet Corelet
    (.clk(clk), .reset(reset), 
     .l0_in(l0_in), .l0_rd(l0_rd), .l0_wr(l0_wr), .l0_o_ready(l0_o_ready), .l0_o_full(l0_o_full), 
     .sfp_in(sfp_in), .sfp_i_valid(sfp_i_valid), .sfp_out(sfp_out), 
     .ofifo_o_valid(ofifo_o_valid), .ofifo_o_ready(ofifo_o_ready), 
     .ofifo_o_full(ofifo_o_full), .ofifo_out(ofifo_out), .ofifo_rd(ofifo_rd), 
     .inst(inst)
    );

    sram_32b_w2048 weight_SRAM (.CLK(clk), .D(D_wmem), .Q(l0_in), .CEN(inst[19]), .WEN(inst[18]), .A(inst[17:7])); 
    sram_32b_w2048 act_SRAM (.CLK(clk), .D(D_xmem), .Q(l0_in), .CEN(inst[46]), .WEN(inst[45]), .A(inst[44:34])); 
    sram_128b_w2048 psum_SRAM (.CLK(clk), .D(ofifo_out), 
                               .Q(sfp_in), 
                               .CEN(inst[32]), .WEN(inst[31]), .A(inst[30:20]));



endmodule