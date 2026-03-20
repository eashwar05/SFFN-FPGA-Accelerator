module sffn_top (
    input  logic        clk, reset, start,
    output logic [31:0] final_result,
    output logic        done
);
    wire [22:0] current_addr;
    wire [7:0]  weight_data;
    wire        ctrl_running;
    logic [31:0] acc_reg;
    logic [1:0]  run_pipe; // Delay line to match memory + multiplier latency

    sffn_controller ctrl_inst (
        .clk(clk), .reset(reset), .start(start),
        .mem_addr(current_addr), .running(ctrl_running), .done(done)
    );

    sffn_weight_mem mem_inst (
        .clk(clk), .addr(current_addr), .dout(weight_data)
    );

    // Pipeline Control: Matches the 1-cycle memory delay
    always_ff @(posedge clk) begin
        if (reset || start) run_pipe <= 2'b00;
        else                run_pipe <= {run_pipe[0], ctrl_running};
    end

    // High-Speed Accumulator: Process 1 weight per cycle
    always_ff @(posedge clk) begin
        if (reset || start) begin
            acc_reg <= 0;
        end else if (run_pipe[0]) begin // Accumulate every cycle while pipe is full
            acc_reg <= acc_reg + ($signed(32'd100) * $signed({{24{weight_data[7]}}, weight_data}));
        end
    end

    assign final_result = acc_reg;
endmodule