module peripheral_slave2(
    
    input       logic                   clk,
    input       logic                   rst_n,
    
    input       logic       [31:0]      paddr,
    input       logic       [2:0]       pprot,
    input       logic                   psel,
    input       logic                   penable,
    input       logic                   pwrite,
    input       logic       [31:0]      pwdata,
    input       logic       [3:0]       pstrb,

    output      logic                   pready,
    output      logic       [31:0]      prdata,
    output      logic                   pslverr,

    input       logic       [7:0]       gpio_in,

    output      logic       [7:0]       gpio_out,
    output      logic       [7:0]       gpio_oe,
    output      logic                   irq

);

    logic       [7:0]       dataout_reg;    //rw
    logic       [7:0]       direction_reg;  //rw
    logic       [7:0]       int_en_reg;     //rw
    logic       [7:0]       int_status_reg; //w1c

    logic       [7:0]       prev_gpio_in;
    logic       [7:0]       pos_edge_detector;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            prev_gpio_in <= 0;
        end else begin
            prev_gpio_in <= gpio_in;
        end    
    end

    assign pos_edge_detector = ~prev_gpio_in & gpio_in;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dataout_reg     <= 0;
            direction_reg   <= 0;
            int_en_reg      <= 0;
            int_status_reg  <= 0;
        end else begin
            if(psel && pwrite && penable) begin
                if(pstrb[0]) begin
                    case(paddr[7:0])

                        8'h04 : dataout_reg     <= pwdata[7:0];
                        8'h08 : direction_reg   <= pwdata[7:0];
                        8'h0C : int_en_reg      <= pwdata[7:0];

                        8'h10 : begin
                            for(int i=0; i<=7; i++) begin
                                if(pwdata[i]) begin
                                    int_status_reg[i] <= 0;
                                end
                            end
                        end
                        default : ;
                    endcase
                end
            end
            for(int i=0; i<=7; i++) begin
                if(int_en_reg[i] && pos_edge_detector[i]) begin
                    int_status_reg[i] <= 1;
                end
            end
        end
    end

    always_comb begin
        
        prdata = 32'b0;

        if(psel && penable && !pwrite) begin
            case(paddr[7:0])

                8'h00   : prdata        = {24'b0, gpio_in};
                8'h04   : prdata        = {24'b0, dataout_reg};
                8'h08   : prdata        = {24'b0, direction_reg};
                8'h0C   : prdata        = {24'b0, int_en_reg};
                8'h10   : prdata        = {24'b0, int_status_reg};
                default : prdata        = 32'b0;

            endcase
        end
    end

    assign gpio_out = dataout_reg;
    assign gpio_oe  = direction_reg;
    
    always_comb begin
        if(psel && penable && pwrite) begin
            if(paddr[7:0] == 8'b0) begin
                pslverr = 1;
                pready  = 1;
            end else if(paddr[7:0] > 8'h10) begin
                pslverr = 1;
                pready  = 1;
            end else begin
                pslverr = 0;
                pready  = 1;
            end
        end else if(psel && penable && !pwrite) begin
            if(paddr[7:0] > 8'h10) begin
                pslverr = 1;
                pready  = 1;
            end else begin
                pslverr = 0;
                pready  = 1;
            end
        end else if(psel && !penable) begin
            pslverr = 0;
            pready  = 1;
        end else if(!psel) begin
            pslverr = 0;
            pready  = 0;
        end
    end

    assign irq =| int_status_reg;

endmodule