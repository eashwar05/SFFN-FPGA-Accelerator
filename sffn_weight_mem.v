module sffn_weight_mem (
    input clk,
    input [22:0] addr,       // 2^23 = 8,388,608 (Enough for 5.3M weights)
    output reg [7:0] dout
);
    // Exact size from your Python script: 5,305,748
    reg [7:0] mem [0:5305747]; 

    initial begin
        $display("STARTING WEIGHT LOAD...");
        $readmemh("weights.hex", mem);
        $display("LOAD COMPLETE: 5,305,748 weights initialized.");
    end

    always @(posedge clk) begin
        dout <= mem[addr];
    end
endmodule