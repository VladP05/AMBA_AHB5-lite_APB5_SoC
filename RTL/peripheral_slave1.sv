module peripheral_slave1(

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
    output      logic                   pslverr

);

    logic       [31:0]      counter;

    logic       [31:0]      ctrl_reg;
    logic       [31:0]      status_reg;
    logic       [31:0]      load_reg;
    logic       [31:0]      value_reg;
    logic       [31:0]      prescaler_reg;

    logic                   tick;

    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            ctrl_reg        <= 0;
            status_reg      <= 0;
            load_reg        <= 0;
            value_reg       <= 0;
            prescaler_reg   <= 0;
            counter         <= 0;
        end else begin
            if(!ctrl_reg[0]) begin
                counter <= 0;
            end else begin
                counter <= counter + 1;
                if(counter == prescaler_reg) begin
                    counter <= 0;
                end
            end

            if(tick) begin
                if(value_reg != load_reg) begin
                    value_reg <= value_reg + 1;
                end else begin
                    status_reg[0] <= 1;
                    if(ctrl_reg[1]) begin
                        value_reg <= 0;
                    end else begin
                        value_reg <= 0;
                        ctrl_reg[0] <= 0;
                    end
                end
            end

            if(psel && penable && pwrite) begin

                case(paddr[7:0])

                    8'h00 : begin
                        if(pstrb[0]) begin
                            ctrl_reg[7:0]       <= pwdata[7:0];
                        end
                    end

                    8'h04 : begin
                        if(pstrb[0]) begin
                            status_reg[7:0]       <= pwdata[7:0];
                        end
                    end

                    8'h08 : begin
                        if(pstrb[0]) begin
                            load_reg[7:0]       <= pwdata[7:0];
                        end
                        if(pstrb[1]) begin
                            load_reg[15:8]      <= pwdata[15:8];
                        end
                        if(pstrb[2]) begin
                            load_reg[23:16]     <= pwdata[23:16];
                        end
                        if(pstrb[3]) begin
                            load_reg[31:24]     <= pwdata[31:24];
                        end
                    end

                    8'h10 : begin
                        if(pstrb[0]) begin
                            prescaler_reg[7:0]       <= pwdata[7:0];
                        end
                        if(pstrb[1]) begin
                            prescaler_reg[15:8]      <= pwdata[15:8];
                        end
                        if(pstrb[2]) begin
                            prescaler_reg[23:16]     <= pwdata[23:16];
                        end
                        if(pstrb[3]) begin
                            prescaler_reg[31:24]     <= pwdata[31:24];
                        end
                    end

                endcase

            end
            
        end

    end

    always_comb begin
        
        if(psel && penable && !pwrite) begin
            case(paddr[7:0])

                8'h00 : begin
                    prdata  = ctrl_reg;
                end

                8'h04 : begin
                    prdata  = status_reg;
                end

                8'h08 : begin
                    prdata  = load_reg;
                end

                8'h0C : begin
                    prdata  = value_reg;
                end

                8'h10 : begin
                    prdata  = prescaler_reg;
                end

                default : prdata    = 0;

            endcase
            
        end else begin
            prdata  = 0;
        end

    end

    always_comb begin
        
        if(psel && penable && pwrite) begin
            if(paddr[7:0] > 8'h10) begin
                pslverr = 1;
                pready  = 1;
            end else if(paddr[7:0] == 8'h0C) begin
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
        end else if(!psel) begin
            pslverr = 0;
            pready  = 1;
        end else if(psel && !penable) begin
            pslverr = 0;
            pready  = 1;
        end

    end

    assign tick = ((counter == prescaler_reg) && ctrl_reg[0]);

endmodule