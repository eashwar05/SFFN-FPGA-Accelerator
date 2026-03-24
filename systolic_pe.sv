module systolic_pe #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input  logic                   clk, rst_n, en, clear_acc,
    input  logic signed [7:0]      pixel_in,
    input  logic signed [7:0]      weight_in,
    output logic signed [31:0]     acc_out
);
    logic signed [15:0] product_reg; 
    logic signed [31:0] accumulator;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product_reg <= 16'sd0;
            accumulator <= 32'sd0;
        end else if (clear_acc) begin
            product_reg <= 16'sd0;
            accumulator <= 32'sd0;
        end else if (en) begin
            product_reg <= pixel_in * weight_in;
            accumulator <= accumulator + product_reg;
        end
    end
    assign acc_out = accumulator;
endmodule