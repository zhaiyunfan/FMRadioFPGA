# 调频收音机

## 整体架构

核心部分是FIR，IIR滤波以及其变体

输入

### 量化与去量化

```verilog
function logic signed [31:0] QUANTIZE_I; 
input logic signed [31:0] i;
    begin
        return i <<< 10;
    end
endfunction

function logic signed [31:0] DEQUANTIZE; 
input logic signed [31:0] i;
    logic signed [31:0] offset_i;
    begin
        offset_i =  i[31] == 1 ? (i + ((1 << 10) - 1)): i;
        return offset_i >>> 10;
    end
endfunction
```

```c++
#define BITS            10
#define QUANT_VAL       (1 << BITS)
#define QUANTIZE_F(f)   (int)(((float)(f) * (float)QUANT_VAL))
#define QUANTIZE_I(i)   (int)((int)(i) * (int)QUANT_VAL)
#define DEQUANTIZE(i)   (int)((int)(i) / (int)QUANT_VAL)
```

### FIR 有限脉冲响应滤波



