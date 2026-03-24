// ============================================================
// Module: recon_head_fsm
// Purpose: Control logic for 224x224, 128-channel 3x3 Conv
// ============================================================

module recon_head_fsm #(
    parameter int IMG_SIZE = 224,
    parameter int CHANNELS = 128,
    parameter int KERNEL   = 3
)(
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    
    // Control to Line Buffer
    output logic shift_en,
    
    // Control to PE
    output logic pe_en,
    output logic clear_acc,
    
    // Control to Weight RAM
    output logic [11:0] weight_addr,
    
    // Status
    output logic layer_done
);

    typedef enum logic [2:0] {
        S_IDLE, 
        S_FILL,      // Wait for 2 lines + 3 pixels
        S_COMPUTE,   // Sum 128 channels for current 3x3 window
        S_SHIFT,     // Move sliding window by 1 pixel
        S_DONE
    } state_t;

    state_t state;
    
    // Counters
    logic [15:0] fill_cnt;   // Need to count to ~451
    logic [7:0]  ch_cnt;     // 0 to 127
    logic [7:0]  col_cnt;    // 0 to 223
    logic [7:0]  row_cnt;    // 0 to 223

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            fill_cnt <= 0;
            ch_cnt <= 0;
            col_cnt <= 0;
            row_cnt <= 0;
            layer_done <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    layer_done <= 0;
                    if (start) state <= S_FILL;
                end

                S_FILL: begin
                    shift_en <= 1;
                    if (fill_cnt == (IMG_SIZE * 2 + KERNEL - 1)) begin
                        state <= S_COMPUTE;
                        fill_cnt <= 0;
                    end else fill_cnt <= fill_cnt + 1;
                end

                S_COMPUTE: begin
                    shift_en <= 0;
                    pe_en <= 1;
                    clear_acc <= (ch_cnt == 0); // Clear at start of channel loop
                    
                    // Weight Address Logic: Simplified for 128 channels
                    weight_addr <= ch_cnt; 

                    if (ch_cnt == CHANNELS - 1) begin
                        ch_cnt <= 0;
                        state <= S_SHIFT;
                    end else ch_cnt <= ch_cnt + 1;
                end

                S_SHIFT: begin
                    shift_en <= 1; // Move window one step right
                    pe_en <= 0;
                    
                    if (col_cnt == IMG_SIZE - 1) begin
                        col_cnt <= 0;
                        if (row_cnt == IMG_SIZE - 1) begin
                            state <= S_DONE;
                        end else row_cnt <= row_cnt + 1;
                    end else begin
                        col_cnt <= col_cnt + 1;
                        state <= S_COMPUTE;
                    end
                end

                S_DONE: begin
                    layer_done <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end

endmodule