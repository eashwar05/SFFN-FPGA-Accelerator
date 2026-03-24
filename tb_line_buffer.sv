`timescale 1ns/1ps

module tb_line_buffer();

    // Parameters
    localparam int DATA_WIDTH = 8;
    localparam int LINE_WIDTH = 224;
    localparam int CLK_PERIOD = 20; // 50 MHz

    // Signals
    logic clk;
    logic rst_n;
    logic shift_en;
    logic [DATA_WIDTH-1:0] pixel_in;
    
    // Outputs from UUT
    logic [DATA_WIDTH-1:0] win_00, win_01, win_02;
    logic [DATA_WIDTH-1:0] win_10, win_11, win_12;
    logic [DATA_WIDTH-1:0] win_20, win_21, win_22;

    // Instantiate Unit Under Test (UUT)
    line_buffer_224 #(
        .DATA_WIDTH(DATA_WIDTH),
        .LINE_WIDTH(LINE_WIDTH)
    ) uut (
        .* // Connects all ports with matching names
    );

    // Clock Generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Test Procedure
    initial begin
        // Initialize
        rst_n = 0;
        shift_en = 0;
        pixel_in = 0;

        // Reset system
        #(CLK_PERIOD * 5);
        rst_n = 1;
        #(CLK_PERIOD * 2);

        // --- Start Feeding Pixels ---
        // We will feed 1000 pixels (enough for 4+ rows)
        // Pixel values will be simple counters (1, 2, 3...)
        for (int i = 1; i <= 1000; i++) begin
            @(posedge clk);
            shift_en = 1;
            pixel_in = i[7:0]; // Cast counter to 8-bit
        end

        // Stop shifting
        @(posedge clk);
        shift_en = 0;
        
        #(CLK_PERIOD * 10);
        $display("Simulation Finished");
        $stop;
    end

    // Monitor logic to help verify the "sliding" in the console
    // Only print when the buffer is starting to fill row 3
    always @(posedge clk) begin
        if (shift_en && pixel_in > 450) begin
            $display("Time: %0t | In: %d | Window Center (win_11): %d", $time, pixel_in, win_11);
        end
    end

endmodule