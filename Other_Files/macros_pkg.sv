package macros_pkg;

    localparam  HTRANS_IDLE             = 2'b00;
    localparam  HTRANS_BUSY             = 2'b01;
    localparam  HTRANS_NONSEQ           = 2'b10;
    localparam  HTRANS_SEQ              = 2'b11;

    localparam  BYTE                    = 3'b000;
    localparam  HALF_WORD               = 3'b001;
    localparam  WORD                    = 3'b010;
    
endpackage