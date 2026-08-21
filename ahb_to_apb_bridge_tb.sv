`timescale 1ns/1ps

module ahb_to_apb_bridge_tb();

    logic                   clk;
    logic                   rst_n;

    logic       [31:0]      haddr;
    logic       [3:0]       hprot;
    logic                   hsel;
    logic       [2:0]       hsize;
    logic                   hnonsec;
    logic       [1:0]       htrans;
    logic       [31:0]      hwdata;
    logic                   hwrite;
    logic                   hready;
    logic       [31:0]      hrdata;
    logic                   hresp;

    logic       [31:0]      paddr;
    logic       [2:0]       pprot;
    logic       [1:0]       psel;
    logic                   penable;
    logic                   pwrite;
    logic       [31:0]      pwdata;
    logic       [3:0]       pstrb;
    logic                   pready;
    logic       [31:0]      prdata;
    logic                   pslverr;

    localparam  HTRANS_IDLE             = 2'b00;
    localparam  HTRANS_BUSY             = 2'b01;
    localparam  HTRANS_NONSEQ           = 2'b10;
    localparam  HTRANS_SEQ              = 2'b11;

    localparam  BYTE                    =3'b000;
    localparam  HALF_WORD               =3'b001;
    localparam  WORD                    =3'b010;


    ahb_to_apb_bridge DUT(.*);

    initial begin

        clk = 0;
        forever #5 clk = ~clk;

    end

    initial begin

        rst_n = 0;
        #10 rst_n = 1;

        haddr   = 0;
        hprot   = 0;
        hsel    = 0;
        hsize   = 0;
        hnonsec = 0;
        htrans  = HTRANS_IDLE;
        hwdata  = 0;
        hwrite  = 0;

        pready  = 1;
        pslverr = 0;

        @(posedge clk);

        haddr   = 32'h7FFFE0A3;
        hwrite  = 0;
        hsel    = 1;
        hsize   = WORD;
        hprot   = 4'b0001;
        hnonsec = 1;
        htrans  = HTRANS_NONSEQ;
        
        @(posedge clk);
        htrans  = HTRANS_IDLE;
        hsel    = 0;

        repeat(4) @(posedge clk);

        $stop();

    end

    assign prdata   = (penable && !pwrite && psel[1]) ? 32'hDEADBEEF : 0;

endmodule