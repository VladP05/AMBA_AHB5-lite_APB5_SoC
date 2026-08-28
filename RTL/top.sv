module top(
    input       logic                   clk,
    input       logic                   rst_n,

    input       logic       [31:0]      haddr,
    input       logic       [3:0]       hprot,
    input       logic       [2:0]       hsize,
    input       logic                   hnonsec,
    input       logic       [1:0]       htrans,
    input       logic       [31:0]      hwdata,
    input       logic                   hwrite,

    output      logic                   hready_out,
    output      logic       [31:0]      hrdata,
    output      logic                   hresp,

    input       logic       [7:0]       gpio_in,

    output      logic       [7:0]       gpio_out,
    output      logic       [7:0]       gpio_oe,
    output      logic                   irq

);

    logic       [1:0]       hsel;
    logic       [1:0]       hsel_reg;
    logic                   hready_in;

    logic                   hready_out_sram;
    logic       [31:0]      hrdata_sram;
    logic                   hresp_sram;

    logic                   hready_out_bridge;
    logic       [31:0]      hrdata_bridge;
    logic                   hresp_bridge;

    logic       [31:0]      paddr;
    logic       [2:0]       pprot;
    logic       [1:0]       psel;
    logic                   penable;
    logic                   pwrite;
    logic       [31:0]      pwdata;
    logic       [3:0]       pstrb;

    logic                   pready_apb;
    logic       [31:0]      prdata_apb;
    logic                   pslverr_apb;

    logic                   pready_pf1, pready_pf2;
    logic       [31:0]      prdata_pf1, prdata_pf2;
    logic                   pslverr_pf1, pslverr_pf2;    

    sram sram_inst(
        .clk(clk),
        .rst_n(rst_n),
        .haddr(haddr),
        .hprot(hprot),
        .hsel(hsel[0]),
        .hsize(hsize),
        .hnonsec(hnonsec),
        .htrans(htrans),
        .hwdata(hwdata),
        .hwrite(hwrite),
        .hready_in(hready_in),

        .hready_out(hready_out_sram),
        .hrdata(hrdata_sram),
        .hresp(hresp_sram)
    );

    ahb_to_apb_bridge ahb_to_apb_bridge_inst(
        .clk(clk),
        .rst_n(rst_n),
        .haddr(haddr),
        .hprot(hprot),
        .hsel(hsel[1]),
        .hsize(hsize),
        .hnonsec(hnonsec),
        .htrans(htrans),
        .hwdata(hwdata),
        .hwrite(hwrite),
        .hready_in(hready_in),

        .hready_out(hready_out_bridge),
        .hrdata(hrdata_bridge),
        .hresp(hresp_bridge),

        .paddr(paddr),
        .pprot(pprot),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .pstrb(pstrb),

        .pready(pready_apb),
        .prdata(prdata_apb),
        .pslverr(pslverr_apb)
    );

    peripheral_slave1 peripheral_slave1_inst(
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pprot(pprot),
        .psel(psel[0]),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .pstrb(pstrb),

        .pready(pready_pf1),
        .prdata(prdata_pf1),
        .pslverr(pslverr_pf1)
    );

    peripheral_slave2 peripheral_slave2_inst(
        .clk(clk),
        .rst_n(rst_n),
        .paddr(paddr),
        .pprot(pprot),
        .psel(psel[1]),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .pstrb(pstrb),

        .pready(pready_pf2),
        .prdata(prdata_pf2),
        .pslverr(pslverr_pf2),
        
        .gpio_in(gpio_in),
        
        .gpio_out(gpio_out),
        .gpio_oe(gpio_oe),
        .irq(irq)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            hsel_reg <= 0;
        end else if(hready_in) begin
            hsel_reg <= hsel;
        end
    end

    always_comb begin
        case (haddr[31:16])
            16'h0000    : hsel  = 2'b01;
            16'h4000    : hsel  = 2'b10;
            default     : hsel  = 2'b00;
        endcase
    end

    always_comb begin
        case (hsel_reg)
            2'b01   : hready_in     = hready_out_sram;
            2'b10   : hready_in     = hready_out_bridge;
            default : hready_in     = 1;
        endcase
    end

    always_comb begin
        case (hsel_reg)
            2'b01   : begin
                hready_out      = hready_out_sram;
                hrdata          = hrdata_sram;
                hresp           = hresp_sram;
            end
            2'b10   : begin
                hready_out      = hready_out_bridge;
                hrdata          = hrdata_bridge;
                hresp           = hresp_bridge;
            end
            default : begin
                hready_out      = 1;
                hrdata          = 0;
                hresp           = 0;

            end
        endcase
    end

    always_comb begin
        case(psel)
            2'b01   : begin
                pready_apb  = pready_pf1;
                prdata_apb  = prdata_pf1;
                pslverr_apb = pslverr_pf1;
            end
            2'b10   : begin
                pready_apb  = pready_pf2;
                prdata_apb  = prdata_pf2;
                pslverr_apb = pslverr_pf2;
            end
            default : begin
                pready_apb  = 1;
                prdata_apb  = 0;
                pslverr_apb = 0;
            end
        endcase
    end

endmodule