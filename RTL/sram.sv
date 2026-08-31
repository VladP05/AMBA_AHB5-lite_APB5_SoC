import macros_pkg::*;

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

    logic   [31:0]  mem [0:255];

    logic   [9:0]   haddr_reg; //8 biti pt adresa, 2 biti pt octet
    logic   [3:0]   hprot_reg;
    logic   [2:0]   hsize_reg;
    logic           hnonsec_reg;
    logic           hwrite_reg;

    logic           access_violation;
    logic           out_of_range_address;
    logic           error;

    assign access_violation = (haddr[9:8] == 2'b00) && !hprot[1];
    assign error            = out_of_range_address || access_violation;
    //!access_violation: incearca sa acceseze o adresa pulica sau utliziator privilegiat
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
            if(hready_in) begin
                if(hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ) && !error) begin
                    haddr_reg   <= haddr[9:0];
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
            end
        
            if(!hready_out && hresp) begin
                hready_out  <= 1;
                hresp       <= 1;
                hwrite_reg  <= 0;
            end else if(hready_in && error && hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ)) begin
                hready_out  <= 0;
                hresp       <= 1;
                hwrite_reg  <= 0;
            end else begin
                hready_out  <= 1;
                hresp       <= 0;
            end
        
        end
    end

    always_ff @(posedge clk) begin
        if(hwrite_reg) begin
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

        if(!hwrite && hready_in && hsel && (htrans == HTRANS_NONSEQ || htrans == HTRANS_SEQ) && !error) begin
            if(hwrite_reg && (haddr[9:2] == haddr_reg[9:2])) begin
                case(hsize_reg)
                    WORD        : begin
                        hrdata  <= hwdata;
                    end
                    HALF_WORD   : begin
                        case(haddr_reg[1:0])
                            2'b00 : hrdata  <= {mem[haddr[9:2]][31:16], hwdata[15:0]};
                            2'b10 : hrdata  <= {hwdata[31:16], mem[haddr[9:2]][15:0]};
                        endcase
                    end
                    BYTE        : begin
                        case(haddr_reg[1:0])
                            2'b00 : hrdata  <= {mem[haddr[9:2]][31:8],      hwdata[7:0]};
                            2'b01 : hrdata  <= {mem[haddr[9:2]][31:16],     hwdata[15:8],   mem[haddr[9:2]][7:0]};
                            2'b10 : hrdata  <= {mem[haddr[9:2]][31:24],     hwdata[23:16],  mem[haddr[9:2]][15:0]};
                            2'b11 : hrdata  <= {hwdata[31:24],              mem[haddr[9:2]][23:0]};
                        endcase
                    end
                    default     : hrdata    <= mem[haddr[9:2]];
                endcase
            end else begin
                hrdata <= mem[haddr[9:2]];
            end
        end

    end     

    assign  out_of_range_address    = (haddr[31:10] != 0);

endmodule