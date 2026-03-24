`timescale 1ns/1ps

module tb_recon_head_fsm();
    logic clk, rst_n, start;
    logic shift_en, pe_en, clear_acc, layer_done;
    logic [11:0] weight_addr;

    recon_head_fsm uut (.*);

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    initial begin
        rst_n = 0; start = 0;
        #100 rst_n = 1;
        #100 start = 1;
        #20 start = 0;
        
        // Let it run through FILL and a few COMPUTE cycles
        wait(layer_done);
        #100 $stop;
    end
endmodule