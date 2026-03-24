`timescale 1ns/1ps

module tb_weight_ram();

    localparam int DATA_WIDTH = 8;
    localparam int ADDR_WIDTH = 12;
    localparam int CLK_PERIOD = 20;

    logic clk;
    logic [ADDR_WIDTH-1:0] addr;
    logic signed [DATA_WIDTH-1:0] weight_out;

    // Instantiate UUT
    weight_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INIT_FILE("recon_weights.hex") // Ensure this file exists!
    ) uut (.*);

    // Clock
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        addr = 0;
        #(CLK_PERIOD * 5);

        // Read first few weights
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);
            addr = i;
        end

        #(CLK_PERIOD * 5);
        $display("Weight RAM Simulation Finished.");
        $stop;
    end

endmodule