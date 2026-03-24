module weight_ram (
    input  logic         clk,
    input  logic [7:0]   addr, // Each address now points to a "Super-Row" of 108 weights
    output logic [863:0] super_weight_out // 12 channels * 9 weights * 8 bits
);
    logic [863:0] mem [0:255];
    initial $readmemh("max_recon_weights.hex", mem);

    always_ff @(posedge clk) begin
        super_weight_out <= mem[addr];
    end
endmodule