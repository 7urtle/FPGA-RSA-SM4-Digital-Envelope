module redc_x 
#(
    parameter n  = 65'd21536215303153667899,
    parameter q  = 62'd1411149436910194189,
    parameter r  = 66'h20000000000000000,
    parameter r1 = 64'd15357272844265435333,
    parameter r2 = 64'd15661607970342841481
)( 
    input clk,                   // 添加时钟信号
    input [129:0] t,             // t in t mod n, should be a*r1
    output reg [64:0] x         // t mod n
);      

    wire [31:0] t_low  = t[31:0];
    wire [32:0] t_high = t[64:32];
    wire [31:0] q_low  = q[31:0];
    wire [31:0] q_high = q[61:32];

    wire [64:0] prod_ll = t_low * q_low;   
    wire [64:0] prod_lh = t_low * q_high;  
    wire [64:0] prod_hl = t_high * q_low;  
    wire [64:0] prod_hh = t_high * q_high;  

    reg [64:0] prod_ll_r, prod_lh_r, prod_hl_r, prod_hh_r;
    always @(posedge clk) begin
        prod_ll_r <= prod_ll;
        prod_lh_r <= prod_lh;
        prod_hl_r <= prod_hl;
        prod_hh_r <= prod_hh;
    end

    wire [127:0] prod_result = {prod_hh_r, 64'b0} + {prod_hl_r, 32'b0} + {prod_lh_r, 32'b0} + prod_ll_r;
    
    reg [64:0] m;
    always @(posedge clk) begin
        m <= prod_result[64:0];  
    end

    reg [129:0] sum_r;
    always @(posedge clk) begin
        sum_r <= t + m * n;
    end

    reg [64:0] t1_r;
    always @(posedge clk) begin
        t1_r <= sum_r >> 65;
    end

    always @(posedge clk) begin
        x <= (t1_r < n) ? t1_r : (t1_r - n);
    end
endmodule //redc
