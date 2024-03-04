// macro functions for use in other files

package macros;



int BITS = 10;

function logic[31:0] QUANTIZE_I; 
input logic[31:0] i;
    begin
        return $signed(i) <<< BITS;
    end
endfunction

function logic[31:0] DEQUANTIZE; 
input logic[31:0] i;
    begin
        return $signed(i) >>> BITS;
    end
endfunction


endpackage