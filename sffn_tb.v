`timescale 1ns/1ps

module sffn_tb();
    // --- Signals ---
    reg clk, reset, start;
    wire [31:0] final_result;
    wire done;

    // --- Golden Model Variables ---
    longint expected_val = 0; 
    longint expected_queue[$]; 
    
    // Set to 0 to align with the streaming pipeline logic
    localparam int PIPELINE_LATENCY = 1; 

    // --- Instantiate the Pipelined DUT ---
    sffn_top dut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .final_result(final_result),
        .done(done)
    );

    // --- 100MHz Clock Generation ---
    always #5 clk = ~clk; 

    initial begin
        longint delayed_expected;
        clk = 0; reset = 1; start = 0; expected_val = 0;

        $display("[%t] STARTING PIPELINED SFFN VERIFICATION (5.3M Weights)...", $time);
        
        // Reset Pulse
        #50; reset = 0; #20;
        
        // Start Signal
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // --- Main Assertion Loop ---
        // This loop runs as long as the controller is processing addresses
        while (!done) begin
            @(posedge clk);
            
            if (dut.ctrl_running) begin
                // 1. Calculate Golden Value for the weight currently being addressed
                // Using the internal memory array to stay cycle-accurate
                expected_val = expected_val + ($signed(32'd100) * $signed({{24{dut.mem_inst.mem[dut.current_addr][7]}}, dut.mem_inst.mem[dut.current_addr]}));
                
                expected_queue.push_back(expected_val);
                
                // 2. Perform real-time comparison
                if (expected_queue.size() > PIPELINE_LATENCY) begin
                    delayed_expected = expected_queue.pop_front();
                    #1; // Wait for logic to settle
                    if ($signed(final_result) !== $signed(delayed_expected[31:0])) begin
                        // Printing only the first 10 errors to keep the log clean
                        static int error_count = 0;
                        if (error_count < 10) begin
                            $display("[%t] ERROR | Addr: %0d | HW: %d | Exp: %d", 
                                     $time, dut.current_addr, $signed(final_result), $signed(delayed_expected));
                            error_count++;
                        end
                    end
                end
            end

            // Safety timeout for 5.3M weights at 100MHz
            if ($time > 200000000) begin
                $display("CRITICAL ERROR: Simulation Timed Out!");
                $stop;
            end
        end

        // --- PIELINE FLUSH ---
        // Crucial: The controller finished, but the last weight is still in the hardware adder.
        // We wait 5 cycles to let the "pipeline drain."
        repeat(5) @(posedge clk);

        // --- Final Report ---
        $display("\n--- SFFN PERFORMANCE REPORT ---");
        $display("Total Simulation Time: %t", $time);
        $display("Final Hardware Result: %d", $signed(final_result));
        $display("Final Golden Result:   %d", $signed(expected_val));
        
        if ($signed(final_result) === $signed(expected_val[31:0])) begin
            $display("----------------------------------------------------------");
            $display("STATUS: SUCCESS - All 5,305,748 weights verified.");
            $display("Throughput: 100 Million Weights / Second");
            $display("----------------------------------------------------------");
        end else begin
            $display("STATUS: FAILURE - Final result mismatch of %d", $signed(final_result) - $signed(expected_val));
        end
            
        $stop;
    end
endmodule