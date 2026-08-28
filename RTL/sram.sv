module sram(

    input       logic                   clk,
    input       logic                   rst_n,

    input       logic       [31:0]      haddr,
    input       logic       [3:0]       hprot,
    input       logic                   hsel,
    input       logic       [2:0]       hsize,
    input       logic                   hnonsec,
    input       logic       [1:0]       htrans,
    input       logic       [31:0]      hwdata,
    input       logic                   hwrite,
    input       logic                   hready_in,

    output      logic                   hready_out,
    output      logic       [31:0]      hrdata,
    output      logic                   hresp
);

    localparam  HTRANS_IDLE             = 2'b00;
    localparam  HTRANS_BUSY             = 2'b01;
    localparam  HTRANS_NONSEQ           = 2'b10;
    localparam  HTRANS_SEQ              = 2'b11;

    localparam  BYTE                    = 3'b000;
    localparam  HALF_WORD               = 3'b001;
    localparam  WORD                    = 3'b010;

    logic   [31:0]  mem [0:255];

    logic   [10:0]  haddr_reg; //8 biti pt adresa, 2 biti pt octet
    logic   [3:0]   hprot_reg;
    logic           hsel_reg;
    logic   [2:0]   hsize_reg;
    logic           hnonsec_reg;
    logic           hwrite_reg;

    logic           msb;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            haddr_reg   <= 0;
            hprot_reg   <= 0;
            hsize_reg   <= 0;
            hnonsec_reg <= 0;
            hwrite_reg  <= 0;
            hready_out  <= 1;
            hresp       <= 0;
        end else begin
            if(hready_in && hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ) && !msb) begin
                haddr_reg   <= haddr[10:0];
                hprot_reg   <= hprot;
                hsize_reg   <= hsize;
                hnonsec_reg <= hnonsec;
                hwrite_reg  <= hwrite;
            end else begin
                haddr_reg   <= 0;
                hprot_reg   <= 0;
                hsize_reg   <= 0;
                hnonsec_reg <= 0;
                hwrite_reg  <= 0;
            end

            if(hwrite_reg && !haddr_reg[10]) begin  
                case (hsize_reg)
                    BYTE : begin
                        case (haddr_reg[1:0])
                            2'b00 : mem[haddr_reg[9:2]][7:0]    <= hwdata[7:0];
                            2'b01 : mem[haddr_reg[9:2]][15:8]   <= hwdata[15:8];
                            2'b10 : mem[haddr_reg[9:2]][23:16]  <= hwdata[23:16];
                            2'b11 : mem[haddr_reg[9:2]][31:24]  <= hwdata[31:24];
                        endcase
                    end

                    HALF_WORD : begin
                        case (haddr_reg[1:0])
                            2'b00 : mem[haddr_reg[9:2]][15:0]   <= hwdata[15:0];
                            2'b10 : mem[haddr_reg[9:2]][31:16]  <= hwdata[31:16];
                        endcase
                    end

                    WORD : begin
                        mem[haddr_reg[9:2]]                     <= hwdata;
                    end

                    default : ;
                endcase
            end
            
            if(!hready_out && hresp) begin
                hready_out  <= 1;
                hresp       <= 1;
            end else if(hready_in && msb && hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ)) begin
                hready_out  <= 0;
                hresp       <= 1;
            end else begin
                hready_out  <= 1;
                hresp       <= 0;
            end

        end
    end

    assign  hrdata      = mem[haddr_reg[9:2]];
    assign  msb         = haddr[10];

endmodule