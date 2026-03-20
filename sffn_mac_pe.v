module sffn_mac_pe (
    input clk,
    input reset,
    input [7:0] weight_in,
    input [7:0] pixel_in,
    input [31:0] acc_in,
    output reg [31:0] acc_out
);
    always @(posedge clk) begin
        if (reset) begin
            acc_out <= 32'b0;
        end else begin
            acc_out <= acc_in + ($signed(weight_in) * $signed(pixel_in));
        end
    end
endmodule