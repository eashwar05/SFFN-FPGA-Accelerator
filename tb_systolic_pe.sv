`timescale 1ns/1ps

module tb_systolic_pe();

    // Parameters
    localparam int DATA_WIDTH = 8;
    localparam int ACC_WIDTH  = 32;
    localparam int CLK_PERIOD = 20;

    // Signals
    logic clk, rst_n, en, clear_acc;
    logic signed [DATA_WIDTH-1:0] pixel_in, weight_in;
    logic signed [ACC_WIDTH-1:0]  acc_out;

    // Instantiate UUT
    systolic_pe #(DATA_WIDTH, ACC_WIDTH) uut (.*);

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        // Initialize
        rst_n = 0; en = 0; clear_acc = 0;
        pixel_in = 0; weight_in = 0;

        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // --- Test 1: Simple Multiplication ---
        // 10 * 5 = 50
        @(posedge clk);
        en = 1; pixel_in = 8'sd10; weight_in = 8'sd5;
        
        // --- Test 2: Signed Multiplication ---
        // Previous 50 + (4 * -3) = 50 - 12 = 38
        @(posedge clk);
        pixel_in = 8'sd4; weight_in = -8'sd3;

        // --- Test 3: Large Accumulation ---
        // Previous 38 + (127 * 2) = 38 + 254 = 292
        @(posedge clk);
        pixel_in = 8'sd127; weight_in = 8'sd2;

        @(posedge clk);
        en = 0; // Stop math

        #(CLK_PERIOD * 5);
        
        // --- Test 4: Clear Accumulator ---
        @(posedge clk);
        clear_acc = 1;
        @(posedge clk);
        clear_acc = 0;

        #(CLK_PERIOD * 10);
        $display("PE Simulation Finished. Check Waves for Math Accuracy!");
        $stop;
    end

endmodule