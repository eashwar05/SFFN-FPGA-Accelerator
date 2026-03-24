// ============================================================
// Module: recon_head_top (MAX SCALED 12-CHANNEL VERSION)
// Hardware: Uses 108 DSP Blocks (12 Channels * 9 PEs)
// Optimization: Pipelined for 100MHz+ Timing Closure
// ============================================================

module recon_head_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [7:0]  pixel_in,
    input  logic        pixel_valid,
    
    // Output array for 12 channels of 32-bit results
    output logic [31:0] channels_out [0:11],
    output logic        data_valid,
    output logic        done
);

    // --- Control and Interconnect Wires ---
    logic shift_en, pe_en_raw, clear_acc_raw;
    logic [7:0]   weight_addr;
    logic [7:0]   w00, w01, w02, w10, w11, w12, w20, w21, w22;
    logic [863:0] wide_weights_raw; // 12-channel * 9-PE * 8-bit bus

    // --- High Fan-out Management ---
    // Quartus duplicates these to handle the 108-PE load without slowing the clock.
    (* max_fanout = 15 *) logic pe_en_reg;
    (* max_fanout = 15 *) logic clear_acc_reg;
    (* max_fanout = 60 *) logic [863:0] weights_reg;

    always_ff @(posedge clk) begin
        pe_en_reg     <= pe_en_raw;
        clear_acc_reg <= clear_acc_raw;
        weights_reg   <= wide_weights_raw;
    end

    // Window Bus (Shared pixels for all kernels)
    logic [7:0] win_bus [0:8];
    assign win_bus = '{w00, w01, w02, w10, w11, w12, w20, w21, w22};

    // Intermediate PE Sums [Channel Index][PE Index]
    logic signed [31:0] pe_sums [0:11][0:8];

    // --- 1. Controller (FSM) ---
    recon_head_fsm #(.IMG_SIZE(224), .CHANNELS(128)) control_unit (
        .clk(clk), .rst_n(rst_n), .start(start),
        .shift_en(shift_en), .pe_en(pe_en_raw), .clear_acc(clear_acc_raw),
        .weight_addr(weight_addr), .layer_done(done)
    );

    // --- 2. Data Buffer (Line Buffer) ---
    line_buffer_224 data_unit (
        .clk(clk), .rst_n(rst_n), .shift_en(shift_en && pixel_valid),
        .pixel_in(pixel_in),
        .win_00(w00), .win_01(w01), .win_02(w02),
        .win_10(w10), .win_11(w11), .win_12(w12),
        .win_20(w20), .win_21(w21), .win_22(w22)
    );

    // --- 3. Weight Memory (Wide Output) ---
    // FIXED: Port name 'super_weight_out' now matches weight_ram.sv
    weight_ram param_unit (
        .clk(clk), 
        .addr(weight_addr), 
        .super_weight_out(wide_weights_raw) 
    );

    // --- 4. Parallel PE Engine (108 DSPs) ---
    genvar ch, i;
    generate
        for (ch = 0; ch < 12; ch++) begin : gen_channels
            for (i = 0; i < 9; i++) begin : gen_pes
                systolic_pe pe_inst (
                    .clk(clk), .rst_n(rst_n), 
                    .en(pe_en_reg), .clear_acc(clear_acc_reg),
                    .pixel_in(win_bus[i]), 
                    .weight_in(weights_reg[(ch*72) + (i*8) +: 8]), 
                    .acc_out(pe_sums[ch][i])
                );
            end

            // --- 5. Pipelined Adder Tree (2-Stage) ---
            // Breaks the math into 100MHz-friendly chunks
            logic signed [31:0] stg1 [0:2];
            always_ff @(posedge clk) begin
                stg1[0] <= pe_sums[ch][0] + pe_sums[ch][1] + pe_sums[ch][2];
                stg1[1] <= pe_sums[ch][3] + pe_sums[ch][4] + pe_sums[ch][5];
                stg1[2] <= pe_sums[ch][6] + pe_sums[ch][7] + pe_sums[ch][8];
            end

            always_ff @(posedge clk) begin
                channels_out[ch] <= stg1[0] + stg1[1] + stg1[2];
            end
        end
    endgenerate

    // --- 6. Valid Signal Delay (Matches Adder Tree Latency) ---
    logic [1:0] valid_delay;
    always_ff @(posedge clk) begin
        valid_delay <= {valid_delay[0], pe_en_reg};
    end
    assign data_valid = valid_delay[1];

endmodule