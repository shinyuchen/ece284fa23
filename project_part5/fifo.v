module fifo #(
	parameter DEPTH = 64,
	parameter WIDTH = 32
)
(
    rst,
    r_clk,
    w_clk,
    i_read,
    i_write,
    i_data,
    o_data,
    o_full,
    o_empty
);
    // parameter bw = 4;
    // parameter depth = 64;
    parameter ptr = $clog2(DEPTH)+1; // add 1 bit for full condition 

    input rst, r_clk, w_clk;
    input i_read, i_write;
    input  [WIDTH-1:0] i_data;
    output [WIDTH-1:0] o_data;
    output o_full, o_empty;

    reg [ptr-1:0] r_ptr, r_ptr_nxt;
    reg [ptr-1:0] w_ptr, w_ptr_nxt;

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [WIDTH-1:0] mem_nxt [0:DEPTH-1];

    

    assign o_empty = (r_ptr == w_ptr) ? 1'b1 : 1'b0;
    assign o_full = (r_ptr[ptr-2:0] == w_ptr[ptr-2:0] & w_ptr[ptr-1] == 1 & r_ptr[ptr-1] == 0) ? 1'b1 : 1'b0;
    assign o_data = mem[r_ptr[ptr-2:0]];

    integer j;
    always @ (*) begin
	for (j=0; j<DEPTH; j=j+1) mem_nxt[j] = mem[j];
        if (i_write && (!o_full)) begin
            mem_nxt[w_ptr[ptr-2:0]] = i_data;
	    w_ptr_nxt = w_ptr + 1;
        end
	else begin
	    w_ptr_nxt = w_ptr;
	end
    end

    always @ (*) begin
	if (i_read & !o_empty) r_ptr_nxt = r_ptr + 1;
	else                   r_ptr_nxt = r_ptr;
    end

    always @ (posedge r_clk) begin
        if (rst) begin
            r_ptr <= 0;
        end
        else begin
            r_ptr <= r_ptr_nxt;
        end
    end


    always @ (posedge w_clk) begin
        if (rst) begin
            w_ptr <= 0;
	    for (j=0; j<DEPTH; j=j+1) mem[j] <= 0;
        end
        else begin
            w_ptr <= w_ptr_nxt;
	    for (j=0; j<DEPTH; j=j+1) mem[j] <= mem_nxt[j];
        end
    end
    
endmodule
