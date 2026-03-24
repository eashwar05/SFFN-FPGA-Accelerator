// ============================================================
// Module: line_buffer_224
// Target: Cyclone V (M10K Optimized)
// Purpose: Provides a 3x3 sliding window for 224-width images
// ============================================================

module line_buffer_224 #(
    parameter int DATA_WIDTH = 8,    // INT8 as per SFFN XML
    parameter int LINE_WIDTH = 224   // Input dimension from XML
)(
    input  logic                   clk,
    input  logic                   rst_n,
    input  logic                   shift_en, // High when a new pixel is valid
    input  logic [DATA_WIDTH-1:0]  pixel_in,
    
    // 3x3 Output Window: win[row][col]
    // row 0 is the oldest data, row 2 is the newest (current input)
    output logic [DATA_WIDTH-1:0]  win_00, win_01, win_02,
    output logic [DATA_WIDTH-1:0]  win_10, win_11, win_12,
    output logic [DATA_WIDTH-1:0]  win_20, win_21, win_22
);

    // Internal line buffers (FIFOs) implemented as shift RAM
    // Line 0 stores the oldest row, Line 1 stores the middle row
    logic [DATA_WIDTH-1:0] line_buf_0 [0:LINE_WIDTH-4];
    logic [DATA_WIDTH-1:0] line_buf_1 [0:LINE_WIDTH-4];

    // Tap registers to form the 3x3 grid
    logic [DATA_WIDTH-1:0] tap_00, tap_01, tap_02;
    logic [DATA_WIDTH-1:0] tap_10, tap_11, tap_12;
    logic [DATA_WIDTH-1:0] tap_20, tap_21, tap_22;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all taps
            {tap_00, tap_01, tap_02} <= '0;
            {tap_10, tap_11, tap_12} <= '0;
            {tap_20, tap_21, tap_22} <= '0;
        end 
        else if (shift_en) begin
            // ?? Row 2 (Newest Row) ??????????????????????????
            tap_22 <= pixel_in;
            tap_21 <= tap_22;
            tap_20 <= tap_21;

            // ?? Row 1 (Middle Row) ??????????????????????????
            // Input to Row 1 is the pixel that just "fell out" of Row 2
            tap_12 <= line_buf_1[LINE_WIDTH-4];
            tap_11 <= tap_12;
            tap_10 <= tap_11;

            // ?? Row 0 (Oldest Row) ??????????????????????????
            // Input to Row 0 is the pixel that just "fell out" of Row 1
            tap_02 <= line_buf_0[LINE_WIDTH-4];
            tap_01 <= tap_02;
            tap_00 <= tap_01;
        end
    end

    // ?? Internal Line Memory ????????????????????????????????
    // We use a simple shift-register array. Quartus will infer 
    // M10K blocks automatically because the depth is > 32.
    integer i;
    always_ff @(posedge clk) begin
        if (shift_en) begin
            // Line Buffer 1: Takes data from the end of the newest tap
            line_buf_1[0] <= tap_20;
            for (i = 1; i < LINE_WIDTH-3; i = i + 1) begin
                line_buf_1[i] <= line_buf_1[i-1];
            end

            // Line Buffer 0: Takes data from the end of the middle tap
            line_buf_0[0] <= tap_10;
            for (i = 1; i < LINE_WIDTH-3; i = i + 1) begin
                line_buf_0[i] <= line_buf_0[i-1];
            end
        end
    end

    // ?? Output Assignments ??????????????????????????????????
    assign win_00 = tap_00; assign win_01 = tap_01; assign win_02 = tap_02;
    assign win_10 = tap_10; assign win_11 = tap_11; assign win_12 = tap_12;
    assign win_20 = tap_20; assign win_21 = tap_21; assign win_22 = tap_22;

endmodule