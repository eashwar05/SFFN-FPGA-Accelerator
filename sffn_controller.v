module sffn_controller (
    input  logic        clk,
    input  logic        reset,
    input  logic        start,
    output logic [22:0] mem_addr,
    output logic        running, // High while streaming data
    output logic        done
);
    parameter TOTAL_WEIGHTS = 5305748;
    logic [22:0] addr_reg;
    logic is_running;

    assign mem_addr = addr_reg;
    assign running  = is_running;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            addr_reg   <= 0;
            is_running <= 0;
            done       <= 0;
        end else if (start) begin
            addr_reg   <= 0;
            is_running <= 1;
            done       <= 0;
        end else if (is_running) begin
            if (addr_reg == TOTAL_WEIGHTS - 1) begin
                is_running <= 0;
                done       <= 1;
            end else begin
                addr_reg <= addr_reg + 1;
            end
        end
    end
endmodule