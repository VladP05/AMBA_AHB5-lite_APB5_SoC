module ahb_to_apb_bridge(

    input   logic               clk,
    input   logic               rst_n,

    //signals for the ahb_side:

    input   logic       [31:0]      haddr,
    input   logic       [3:0]       hprot,
    input   logic                   hsel,
    input   logic       [2:0]       hsize,
    input   logic                   hnonsec,
    input   logic       [1:0]       htrans,
    input   logic       [31:0]      hwdata,
    input   logic                   hwrite,
    input   logic                   hready_in,

    output  logic                   hready_out,
    output  logic       [31:0]      hrdata,
    output  logic                   hresp,

    //signals for the apb_side:

    output  logic       [31:0]      paddr,
    output  logic       [2:0]       pprot,
    output  logic       [1:0]       psel,
    output  logic                   penable,
    output  logic                   pwrite,
    output  logic       [31:0]      pwdata,
    output  logic       [3:0]       pstrb,

    input   logic                   pready,
    input   logic       [31:0]      prdata,
    input   logic                   pslverr
);

    localparam  IDLE                    = 2'b00;
    localparam  SETUP                   = 2'b01;
    localparam  ACCESS                  = 2'b10;
    localparam  ERROR                   = 2'b11;

    localparam  HTRANS_IDLE             = 2'b00;
    localparam  HTRANS_BUSY             = 2'b01;
    localparam  HTRANS_NONSEQ           = 2'b10;
    localparam  HTRANS_SEQ              = 2'b11;

    localparam  BYTE                    = 3'b000;
    localparam  HALF_WORD               = 3'b001;
    localparam  WORD                    = 3'b010;

    logic       [31:0]      haddr_reg;
    logic                   hwrite_reg;
    logic       [1:0]       psel_reg;
    logic       [2:0]       hsize_reg;
    logic       [3:0]       hprot_reg;
    logic                   hnonsec_reg;

    logic       [1:0]       state, next_state;

    logic                   valid_cpu_to_bridge_transfer;

    assign  valid_cpu_to_bridge_transfer = hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ) && hready_in;

    always_ff @(posedge clk or negedge rst_n) begin
        
        if(!rst_n) begin

            haddr_reg <= 0;
            hwrite_reg <= 0;
            psel_reg <= 0;
            hsize_reg <= 0;
            hprot_reg <= 0;
            hnonsec_reg <= 0;

        end else if(valid_cpu_to_bridge_transfer) begin

            haddr_reg <= haddr;
            hwrite_reg <= hwrite;
            psel_reg <= (haddr[7] == 1'b0) ? 2'b01 : 2'b10;   //slave 1 is from 0x00000000 to 0x0000007F, slave 2 is from 0x00000080 to 0x000000FF
            hsize_reg <= hsize;
            hprot_reg <= hprot;
            hnonsec_reg <= hnonsec;

        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        
        if(!rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end

    end

    always_comb begin
        
        case (state)

            IDLE : begin

                if(valid_cpu_to_bridge_transfer) begin
                    next_state = SETUP;
                end else begin
                    next_state = IDLE;
                end

            end

            SETUP : begin

                next_state = ACCESS;

            end

            ACCESS : begin

                if(pready && pslverr) begin
                    next_state = ERROR;
                end else if(!pready) begin
                    next_state = ACCESS;
                end else if(valid_cpu_to_bridge_transfer) begin
                    next_state = SETUP;
                end else begin
                    next_state = IDLE;
                end

            end

            ERROR : begin

                next_state = IDLE;

            end

            default : next_state = IDLE;

        endcase

    end

    always_comb begin
        
        penable         = 0;
        psel            = 0;
        hready_out      = 1;
        hresp           = 0;

        case (state)
            
            IDLE : begin

                penable         = 0;
                psel            = 0;
                hready_out      = 1;
                hresp           = 0;     

            end

            SETUP : begin

                psel            = psel_reg;
                penable         = 0;
                hready_out      = 0;
                hresp           = 0;

            end

            ACCESS : begin

                psel        = psel_reg;
                penable     = 1;
            
                if(!pready) begin

                    hready_out  = 0;
                    hresp       = 0;

                end else if(pslverr) begin

                    hready_out  = 0;
                    hresp       = 1;

                end else begin

                    hready_out  = 1;
                    hresp       = 0;

                end

            end

            ERROR : begin

                hready_out      = 1;
                hresp           = 1;

            end

            default : begin

                penable         = 0;
                psel            = 0;
                hready_out      = 1;
                hresp           = 0;

            end

        endcase

    end

    assign  hrdata      = prdata;
    assign  paddr       = haddr_reg;
    assign  pwdata      = hwdata;
    assign  pwrite      = hwrite_reg;
    assign  pprot[0]    = hprot_reg[1];
    assign  pprot[1]    = hnonsec_reg;
    assign  pprot[2]    = ~hprot_reg[0];

    always_comb begin
        
        if(hwrite_reg) begin
            case(hsize_reg)

                BYTE : begin
                            
                    case (haddr_reg[1:0]) 
                                
                        2'b00 : pstrb = 4'b0001;
                        2'b01 : pstrb = 4'b0010;
                        2'b10 : pstrb = 4'b0100;
                        2'b11 : pstrb = 4'b1000;
                        default : pstrb = 4'b0000;

                    endcase

                end

                HALF_WORD : begin

                    case (haddr_reg[1:0])
                                
                        2'b00 : pstrb = 4'b0011;
                        2'b10 : pstrb = 4'b1100;
                        default : pstrb = 4'b0000;

                    endcase

                end

                WORD : begin

                    pstrb = 4'b1111;

                end

                default : pstrb = 4'b0000;

            endcase
        end else begin
            pstrb   = 4'b0000;
        end

    end

endmodule