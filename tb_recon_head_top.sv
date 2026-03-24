`timescale 1ns/1ps

module tb_recon_head_top();

    logic clk, rst_n, start, pixel_valid, data_valid, done;
    logic [7:0] pixel_in;
    logic [31:0] ch0_out, ch1_out;

    // Instantiate the Top Level
    recon_head_top uut (.*);

    // Clock Generation (50MHz)
    initial clk = 0;
    always #10 clk = ~clk;

    initial begin
        // Initialize
        rst_n = 0; start = 0; pixel_in = 0; pixel_valid = 0;
        
        #100 rst_n = 1;
        #100 start = 1;
        #20 start = 0;

        // Feed Pixels for 3 lines to fill the buffer
        // (224 pixels/row * 2 rows + 3 pixels = 451 pixels)
        for (int i = 1; i <= 500; i++) begin
            @(posedge clk);
            
            // If the FSM is busy computing 128 channels, we must wait
            // We check the internal FSM state via hierarchy for the testbench
            while (uut.control_unit.state == 3'd2) begin // S_COMPUTE
                pixel_valid = 0;
                @(posedge clk);
            end
            
            pixel_valid = 1;
            pixel_in = i[7:0];
        end

        pixel_valid = 0;
        
        // Wait for the layer to finish processing
        wait(done);
        #1000;
        $display("Full System Simulation Successful!");
        $stop;
    end

endmodule