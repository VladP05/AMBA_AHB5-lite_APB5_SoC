`timescale 1ns/1ps

import macros_pkg::*;

module system_tb();

    logic                   clk_tb;
    logic                   rst_n_tb;

    logic       [31:0]      haddr_tb;
    logic       [3:0]       hprot_tb;
    logic       [2:0]       hsize_tb;
    logic                   hnonsec_tb;
    logic       [1:0]       htrans_tb;
    logic       [31:0]      hwdata_tb;
    logic                   hwrite_tb;

    logic                   hready_out_tb;
    logic       [31:0]      hrdata_tb;
    logic                   hresp_tb;

    logic       [7:0]       gpio_in_tb;

    logic       [7:0]       gpio_out_tb;
    logic       [7:0]       gpio_oe_tb;
    logic                   irq_tb;

    top DUT(
        .clk(clk_tb),
        .rst_n(rst_n_tb),
        .haddr(haddr_tb),
        .hprot(hprot_tb),
        .hsize(hsize_tb),
        .hnonsec(hnonsec_tb),
        .htrans(htrans_tb),
        .hwdata(hwdata_tb),
        .hwrite(hwrite_tb),
        .hready_out(hready_out_tb),
        .hrdata(hrdata_tb),
        .hresp(hresp_tb),
        .gpio_in(gpio_in_tb),
        .gpio_out(gpio_out_tb),
        .gpio_oe(gpio_oe_tb),
        .irq(irq_tb)
    );

    initial begin
        clk_tb = 0;
        forever #5 clk_tb = ~clk_tb;
    end

    initial begin

        rst_n_tb    = 0;
        #20;
        rst_n_tb    = 1;

        haddr_tb    = 0;
        hprot_tb    = 0;
        hsize_tb    = 0;
        hnonsec_tb  = 0;
        htrans_tb   = 0;
        hwdata_tb   = 0;
        hwrite_tb   = 0;

        gpio_in_tb  = 0;

        @(posedge clk_tb);
        #2;
        haddr_tb    = 32'h0000_0020;
        hprot_tb    = 4'b0010;
        hsize_tb    = 3'b010;
        hnonsec_tb  = 1'b0;
        htrans_tb   = HTRANS_NONSEQ;
        hwdata_tb   = 32'h0000_0000;
        hwrite_tb   = 1'b1;

        gpio_in_tb  = 8'h00;

        @(posedge clk_tb);
        #2;
        haddr_tb    = 32'h0000_0020;
        hprot_tb    = 4'b0010;
        hsize_tb    = 3'b010;
        hnonsec_tb  = 1'b0;
        htrans_tb   = HTRANS_NONSEQ;
        hwdata_tb   = 32'hDEAD_BEEF;
        hwrite_tb   = 1'b0;

        gpio_in_tb  = 8'h00;

        @(posedge clk_tb);
        #2;
        haddr_tb    = 32'h0000_0000;
        hprot_tb    = 4'b0000;
        hsize_tb    = 3'b010;
        hnonsec_tb  = 1'b0;
        htrans_tb   = HTRANS_IDLE;
        hwdata_tb   = 32'h0000_0000;
        hwrite_tb   = 1'b0;

        gpio_in_tb  = 8'h00;

        repeat(5) @(posedge clk_tb);

        $stop();
    end

endmodule