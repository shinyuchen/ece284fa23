// Created by prof. Mingu Kang @VVIP Lab in UCSD ECE department
// Please do not spread this code without permission 
`timescale 1ns/1ps

module core_tb;

parameter bw = 4;
parameter psum_bw = 16;
parameter len_kij = 9; // kernel = 3x3
parameter len_onij = 16; // output = 4x4
parameter col = 8;  // oc = 8
parameter row = 8;  // ic = 8
parameter len_nij = 36; // input = 6x6

reg clk = 0;
reg reset = 1;

wire [46:0] inst_q; // explained in line 69 to 82

reg [1:0]  inst_w_q = 0; 
reg [bw*row-1:0] D_xmem_q = 0;
reg [bw*row-1:0] D_wmem_q = 0; // input for memory storing x (weight & activation)
reg CEN_xmem = 1, CEN_wmem = 1; // clock enable neg for L0
reg WEN_xmem = 1, WEN_wmem = 1; // write_neg for L0, otherwise read
reg [10:0] A_xmem = 0;
reg [10:0] A_wmem = 0; // address of memory for x (weight & activation)
reg CEN_xmem_q = 1, CEN_wmem_q = 1;
reg WEN_xmem_q = 1, WEN_wmem_q = 1;
reg [10:0] A_xmem_q = 0; 
reg [10:0] A_wmem_q = 0;
reg CEN_pmem = 1;
reg WEN_pmem = 1;
reg [10:0] A_pmem = 0; // address of memory for psum
reg CEN_pmem_q = 1;
reg WEN_pmem_q = 1;
reg [10:0] A_pmem_q = 0;
reg ofifo_rd_q = 0;
reg ififo_wr_q = 0;
reg ififo_rd_q = 0;
reg l0_rd_q = 0;
reg l0_wr_q = 0;
reg execute_q = 0;
reg load_q = 0;
reg acc_q = 0;
reg acc = 0;

reg [1:0]  inst_w; 
reg [bw*row-1:0] D_xmem;
reg [bw*row-1:0] D_wmem;
reg [psum_bw*col-1:0] answer;


reg ofifo_rd;
reg ififo_wr;
reg ififo_rd;
reg l0_rd;
reg l0_wr;
reg execute;
reg load;
reg [8*30:1] stringvar;
reg [8*30:1] w_file_name;
wire ofifo_valid;
wire [col*psum_bw-1:0] sfp_out;

integer x_file, x_scan_file ; // file_handler
integer w_file, w_scan_file ; // file_handler
integer acc_file, acc_scan_file ; // file_handler
integer out_file, out_scan_file ; // file_handler
integer captured_data; 
integer t, i, j, k, kij;
integer error;

assign inst_q[46]     = CEN_xmem_q; // control weight and activation read (from core SRAM to core ififo or L0) and write (from tb DRAM to core SRAM)
assign inst_q[45]     = WEN_xmem_q; // control weight and activation read (from core SRAM to core ififo or L0) and write (from tb DRAM to core SRAM)
assign inst_q[44:34]  = A_xmem_q;  
assign inst_q[33]     = acc_q;      // start to accumulate
assign inst_q[32]     = CEN_pmem_q; // control psum (L1 scratch pad mem) read (to SFU for accumulation) (no write from tb DRAM)
assign inst_q[31]     = WEN_pmem_q; // control psum (L1 scratch pad mem) read (to SFU for accumulation) (no write from tb DRAM)
assign inst_q[30:20]  = A_pmem_q;   // control psum (L1 scratch pad mem) read (to SFU for accumulation) (no write from tb DRAM)
assign inst_q[19]     = CEN_wmem_q; // control weight and activation read (from core SRAM to core ififo or L0) and write (from tb DRAM to core SRAM)
assign inst_q[18]     = WEN_wmem_q; // control weight and activation read (from core SRAM to core ififo or L0) and write (from tb DRAM to core SRAM)
assign inst_q[17:7]   = A_wmem_q;   // control weight and activation read (from core SRAM to core ififo or L0) and write (from tb DRAM to core SRAM)
assign inst_q[6]      = ofifo_rd_q; // start to read ofifo and write to psum
assign inst_q[5]      = ififo_wr_q; // control ififo read (ififo to PE) and write (from SRAM to ififo)
assign inst_q[4]      = ififo_rd_q; // control ififo read (ififo to PE) and write (from SRAM to ififo)
assign inst_q[3]      = l0_rd_q;    // control L0 read (L0 to PE)
assign inst_q[2]      = l0_wr_q;    // control L0 write (from SRAM to L0)
assign inst_q[1]      = execute_q;  // execute x*y+z
assign inst_q[0]      = load_q;     // load values to x or y or z


core  #(.bw(bw), .col(col), .row(row)) core_instance (
	.clk          (clk), 
	.inst         (inst_q),
	.ofifo_valid  (ofifo_valid),
  .D_xmem       (D_xmem_q), 
  .D_wmem       (D_wmem_q),
  .sfp_out      (sfp_out), 
	.reset        (reset)
); 


initial begin 

  inst_w   = 0; 
  D_xmem   = 0;
  CEN_xmem = 1;
  WEN_xmem = 1;
  A_xmem   = 0;
  D_wmem   = 0;
  CEN_wmem = 1;
  WEN_wmem = 1;
  A_wmem   = 0;
  ofifo_rd = 0;
  ififo_wr = 0;
  ififo_rd = 0;
  l0_rd    = 0;
  l0_wr    = 0;
  execute  = 0;
  load     = 0;

  $dumpfile("core_tb.vcd");
  $dumpvars(0,core_tb);

  x_file = $fopen("activation_tile0.txt", "r");
  // Following three lines are to remove the first three comment lines of the file
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);
  x_scan_file = $fscanf(x_file,"%s", captured_data);

  //////// Reset /////////
  #0.5 clk = 1'b0;   reset = 1;
  #0.5 clk = 1'b1; 

  for (i=0; i<10 ; i=i+1) begin
    #0.5 clk = 1'b0;
    #0.5 clk = 1'b1;  
  end

  #0.5 clk = 1'b0;   reset = 0;
  #0.5 clk = 1'b1; 

  #0.5 clk = 1'b0;   
  #0.5 clk = 1'b1;   
  /////////////////////////

  /////// Activation data writing to memory ///////
  // for (t=0; t<len_nij; t=t+1) begin  
  //   #0.5 
  //     clk = 1'b0;  
  //     x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
  //     WEN_xmem = 0; 
  //     CEN_xmem = 0; 
  //     if (t>0) A_xmem = A_xmem + 1;
  //   #0.5 clk = 1'b1;   
  // end

  // #0.5 
  //   clk = 1'b0;  
  //   WEN_xmem = 1;  
  //   CEN_xmem = 1; 
  //   A_xmem = 0;
  // #0.5 clk = 1'b1; 

  // $fclose(x_file);
  /////////////////////////////////////////////////


  for (kij=0; kij<9; kij=kij+1) begin  // kij loop

    case(kij)
     0: w_file_name = "weight_itile0_otile0_kij0.txt";
     1: w_file_name = "weight_itile0_otile0_kij1.txt";
     2: w_file_name = "weight_itile0_otile0_kij2.txt";
     3: w_file_name = "weight_itile0_otile0_kij3.txt";
     4: w_file_name = "weight_itile0_otile0_kij4.txt";
     5: w_file_name = "weight_itile0_otile0_kij5.txt";
     6: w_file_name = "weight_itile0_otile0_kij6.txt";
     7: w_file_name = "weight_itile0_otile0_kij7.txt";
     8: w_file_name = "weight_itile0_otile0_kij8.txt";
    endcase
    

    w_file = $fopen(w_file_name, "r");
    // Following three lines are to remove the first three comment lines of the file
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);
    w_scan_file = $fscanf(w_file,"%s", captured_data);

    #0.5 clk = 1'b0;   reset = 1;
    #0.5 clk = 1'b1; 

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end

    #0.5 clk = 1'b0;   reset = 0;
    #0.5 clk = 1'b1; 

    #0.5 clk = 1'b0;   
    #0.5 clk = 1'b1;   





    /////// Kernel data writing to memory ///////

    A_wmem = 11'b00000000000;

    for (t=0; t<col; t=t+1) begin  // 1 col each time
      #0.5 clk = 1'b0;  
        w_scan_file = $fscanf(w_file,"%32b", D_wmem); 
        WEN_wmem = 0;
        CEN_wmem = 0; 
        if (t>0) A_wmem = A_wmem + 1; 
        if(kij == 0) begin
          x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
          WEN_xmem = 0; 
          CEN_xmem = 0; 
          if (t>0) A_xmem = A_xmem + 1;
        end
      #0.5 clk = 1'b1;  
    end

    #0.5 
      clk = 1'b0;  
      WEN_wmem = 1;  
      CEN_wmem = 1; 
      A_wmem = 0;
      if(kij == 0) begin
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        A_xmem = A_xmem + 1;
      end
    #0.5 clk = 1'b1; 
    /////////////////////////////////////



    /////// 1. Kernel data writing to L0 -> Use L0 to horizontally input weight into PEs ///////
    A_wmem = 11'b00000000000;
    #0.5 clk = 1'b0;  
      ififo_wr = 1'b1;
      WEN_wmem = 1;
      CEN_wmem = 0; 
      if(kij == 0) begin
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        A_xmem = A_xmem + 1;
      end

    #0.5 clk = 1'b1;  
    for (t=1; t<col+1; t=t+1) begin  
      #0.5 clk = 1'b0;  
        ififo_wr = 1'b1;
        WEN_wmem = 1;
        CEN_wmem = 0; 
        if (t>0) A_wmem = A_wmem + 1; 
        if(kij == 0) begin
          x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
          WEN_xmem = 0; 
          CEN_xmem = 0; 
          A_xmem = A_xmem + 1;
        end

      #0.5 clk = 1'b1;  
    end

    #0.5 
      clk = 1'b0;  
      ififo_wr = 1'b0;
      WEN_wmem = 1;  
      CEN_wmem = 1; 
      A_wmem = 0;
      if(kij == 0) begin
        x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
        WEN_xmem = 0; 
        CEN_xmem = 0; 
        A_xmem = A_xmem + 1;
      end
    #0.5 
      clk = 1'b1; 
    /////////////////////////////////////



    /////// 2. Kernel loading to PEs -> sequentially inject weight values into PEs from L0///////
    // #0.5 
    //   clk = 1'b0;
    //   ififo_rd = 1'b1;
    //   if(kij == 0) begin
    //     x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
    //     WEN_xmem = 0; 
    //     CEN_xmem = 0; 
    //     A_xmem = A_xmem + 1;
    //   end
    
    // #0.5
    //   clk = 1'b1;
    for(t=0; t<row+2*col; t=t+1) begin // refer to W4S2 P.15
      #0.5 
        clk = 1'b0;
        ififo_rd = 1'b1;
        load = 1'b1;
        if(kij == 0 && t<16) begin
          x_scan_file = $fscanf(x_file,"%32b", D_xmem); 
          WEN_xmem = 0; 
          CEN_xmem = 0; 
          A_xmem = A_xmem + 1;
        end

      #0.5
        clk = 1'b1;
        if(kij == 0 && t==16) begin
          WEN_xmem = 1;  
          CEN_xmem = 1; 
          A_xmem = 0;
          $fclose(x_file);
        end
    end
    #0.5 
      clk = 1'b0;
      ififo_rd = 1'b0;
    #0.5
      clk = 1'b1;
    // 0.5 
    //     clk = 1'b0;
    //     ififo_rd = 1'b0;
    //   #0.5
    //     clk = 1'b1;
    // for(t=0; t<row+col+10; t=t+1) begin // refer to W4S2 P.15
    //   #0.5 
    //     clk = 1'b0;
    //   #0.5
    //     clk = 1'b1;
    // end
    // #0.5 
    //   clk = 1'b0;  
    //   load = 0; 
    // #0.5 
    //   clk = 1'b1;  
    /////////////////////////////////////
  


    ////// provide some intermission to clear up the kernel loading ///
    #0.5 
      clk = 1'b0;  
      load = 0; 
      ififo_rd = 0;
    #0.5 
      clk = 1'b1;  

    for (i=0; i<10 ; i=i+1) begin
      #0.5 clk = 1'b0;
      #0.5 clk = 1'b1;  
    end
    /////////////////////////////////////



    /////// 3. Activation data writing to L0 ///////
    for (t=0; t<len_nij+1; t=t+1) begin  
      #0.5 
        clk = 1'b0;  
        l0_wr = 1;
        WEN_xmem = 1;  
        CEN_xmem = 0; 
        if (t>0) A_xmem = A_xmem + 1;
      #0.5 clk = 1'b1;   
    end

    #0.5 
      clk = 1'b0;  
      l0_wr = 0;
      WEN_xmem = 1;  
      CEN_xmem = 1; 
      A_xmem = 0;
    #0.5 
      clk = 1'b1; 
    /////////////////////////////////////

    /////// 4. Execution ///////
    #0.5
      clk = 1'b0;
      l0_rd = 1;
    #0.5
      clk = 1'b1;
    for (t=0; t<len_nij+row+col-1; t=t+1) begin
      #0.5
        clk = 1'b0;
        l0_rd = 1;
        execute = 1;
      #0.5
        clk = 1'b1;
    end
    #0.5
      clk = 1'b0;
      l0_rd = 0;
    #0.5
      clk = 1'b1;

    #0.5 
      clk = 1'b0;  
      l0_rd = 0;
      execute = 0;
    #0.5 
      clk = 1'b1; 
    /////////////////////////////////////

    



    //////// 5. OFIFO READ ////////
    // Ideally, OFIFO should be read while execution, but we have enough ofifo
    // depth so we can fetch out after execution.
    A_pmem = len_nij*kij;
    for(t=0; t<len_nij; t=t+1) begin
      #0.5
        clk = 1'b0;
        ofifo_rd = 1'b1;
        WEN_pmem = 0;
        CEN_pmem = 0;
        if(t>0) A_pmem = A_pmem+1;
      #0.5
        clk = 1'b1;
    end

    #0.5
      clk = 1'b0;
      ofifo_rd = 1'b0;
      WEN_pmem = 1;
      CEN_pmem = 1;
      A_pmem = 0;
    #0.5
      clk = 1'b1;
    /////////////////////////////////////


  end  // end of kij loop


  ////////// 6. Accumulation /////////
  acc_file = $fopen("acc_address.txt", "r");
  out_file = $fopen("out.txt", "r");  /// out.txt file stores the address sequence to read out from psum memory for accumulation
                                      /// This can be generated manually or in
                                      /// pytorch automatically

  // Following three lines are to remove the first three comment lines of the file
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 
  out_scan_file = $fscanf(out_file,"%s", answer); 

  error = 0;



  $display("############ Verification Start during accumulation #############"); 

  for (i=0; i<len_onij+1; i=i+1) begin 

    #0.5 clk = 1'b0; 
    #0.5 clk = 1'b1; 

    if (i>0) begin
     out_scan_file = $fscanf(out_file,"%128b", answer); // reading from out file to answer
       if (sfp_out == answer)
         $display("%2d-th output featuremap Data matched! :D", i); 
       else begin
         $display("%2d-th output featuremap Data ERROR!!", i); 
         $display("sfpout: %128b", sfp_out);
         $display("answer: %128b", answer);
         error = 1;
       end
    end
   
 
    #0.5 clk = 1'b0; reset = 1;
    #0.5 clk = 1'b1;  
    #0.5 clk = 1'b0; reset = 0; 
    #0.5 clk = 1'b1;  

    for (j=0; j<len_kij+1; j=j+1) begin 

      #0.5 clk = 1'b0;   
        if (j<len_kij) begin 
          CEN_pmem = 0; 
          WEN_pmem = 1; 
          acc_scan_file = 
          $fscanf(acc_file,"%11b", A_pmem); 
        end
        else  begin 
          CEN_pmem = 1; 
          WEN_pmem = 1; 
        end

        if (j>0)  acc = 1;  
      #0.5 clk = 1'b1;   
    end

    #0.5 clk = 1'b0; acc = 0;
    #0.5 clk = 1'b1; 
  end


  if (error == 0) begin
  	$display("############ No error detected ##############"); 
  	$display("########### Project Completed !! ############"); 

  end

  $fclose(acc_file);
  //////////////////////////////////

  for (t=0; t<10; t=t+1) begin  
    #0.5 clk = 1'b0;  
    #0.5 clk = 1'b1;  
  end

  #10 $finish;

end

always @ (posedge clk) begin
   inst_w_q   <= inst_w; 
   D_xmem_q   <= D_xmem;
   CEN_xmem_q <= CEN_xmem;
   WEN_xmem_q <= WEN_xmem;
   D_wmem_q   <= D_wmem;
   CEN_wmem_q <= CEN_wmem;
   WEN_wmem_q <= WEN_wmem;
   A_pmem_q   <= A_pmem;
   CEN_pmem_q <= CEN_pmem;
   WEN_pmem_q <= WEN_pmem;
   A_xmem_q   <= A_xmem;
   A_wmem_q   <= A_wmem;
   ofifo_rd_q <= ofifo_rd;
   acc_q      <= acc;
   ififo_wr_q <= ififo_wr;
   ififo_rd_q <= ififo_rd;
   l0_rd_q    <= l0_rd;
   l0_wr_q    <= l0_wr ;
   execute_q  <= execute;
   load_q     <= load;
end


endmodule




