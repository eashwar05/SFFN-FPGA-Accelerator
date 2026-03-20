module sffn_pe_grid #(parameter GRID_SIZE = 8) (
    input clk,
    input reset,
    input [7:0] pixel_in [0:GRID_SIZE-1],
    input [7:0] weight_in [0:GRID_SIZE-1],
    output [31:0] result
);
    wire [31:0] acc_chain [0:GRID_SIZE];
    assign acc_chain[0] = 32'b0; // Start of the chain

    genvar i;
    generate
        for (i = 0; i < GRID_SIZE; i = i + 1) begin : PE_ARRAY
            sffn_mac_pe pe_inst (
                .clk(clk),
                .reset(reset),
                .weight_in(weight_in[i]),
                .pixel_in(pixel_in[i]),
                .acc_in(acc_chain[i]),
                .acc_out(acc_chain[i+1])
            );
        end
    endgenerate

    assign result = acc_chain[GRID_SIZE];
endmodule