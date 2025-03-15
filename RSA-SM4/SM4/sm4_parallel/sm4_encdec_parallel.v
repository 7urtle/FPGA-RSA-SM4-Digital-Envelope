`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/01/17 18:04:53
// Design Name: 
// Module Name: sm4_top_parallel
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sm4_encdec_parallel(
    input           clk,
    input           rst_n,
    input  [127:0]  sm4_in,
    output reg [127:0]  sm4_out,

    input  [31:0]   ikey_0 ,
    input  [31:0]   ikey_1 ,
    input  [31:0]   ikey_2 ,
    input  [31:0]   ikey_3 ,
    input  [31:0]   ikey_4 ,
    input  [31:0]   ikey_5 ,
    input  [31:0]   ikey_6 ,
    input  [31:0]   ikey_7 ,
    input  [31:0]   ikey_8 ,
    input  [31:0]   ikey_9 ,
    input  [31:0]   ikey_10,
    input  [31:0]   ikey_11,
    input  [31:0]   ikey_12,
    input  [31:0]   ikey_13,
    input  [31:0]   ikey_14,
    input  [31:0]   ikey_15,
    input  [31:0]   ikey_16,
    input  [31:0]   ikey_17,
    input  [31:0]   ikey_18,
    input  [31:0]   ikey_19,
    input  [31:0]   ikey_20,
    input  [31:0]   ikey_21,
    input  [31:0]   ikey_22,
    input  [31:0]   ikey_23,
    input  [31:0]   ikey_24,
    input  [31:0]   ikey_25,
    input  [31:0]   ikey_26,
    input  [31:0]   ikey_27,
    input  [31:0]   ikey_28,
    input  [31:0]   ikey_29,
    input  [31:0]   ikey_30,
    input  [31:0]   ikey_31
    ); 

    wire [127:0] result_0,  result_1,  result_2,  result_3,  result_4,  result_5,  result_6,  result_7;
    wire [127:0] result_8,  result_9,  result_10, result_11, result_12, result_13, result_14, result_15;
    wire [127:0] result_16, result_17, result_18, result_19, result_20, result_21, result_22, result_23;
    wire [127:0] result_24, result_25, result_26, result_27, result_28, result_29, result_30, result_31;

    reg [127:0] r_result_0,  r_result_1,  r_result_2,  r_result_3,  r_result_4,  r_result_5,  r_result_6,  r_result_7;
    reg [127:0] r_result_8,  r_result_9,  r_result_10, r_result_11, r_result_12, r_result_13, r_result_14, r_result_15;
    reg [127:0] r_result_16, r_result_17, r_result_18, r_result_19, r_result_20, r_result_21, r_result_22, r_result_23;
    reg [127:0] r_result_24, r_result_25, r_result_26, r_result_27, r_result_28, r_result_29, r_result_30;

    wire [31:0] word_0;
    wire [31:0] word_1;
    wire [31:0] word_2;
    wire [31:0] word_3;
    wire [127:0] reversed_result_31;
    

    encdec_round  encdec_round_0  (.round_in (sm4_in     ),.round_rki(ikey_0 ),.round_out(result_0 ));
    encdec_round  encdec_round_1  (.round_in (r_result_0 ),.round_rki(ikey_1 ),.round_out(result_1 ));
    encdec_round  encdec_round_2  (.round_in (r_result_1 ),.round_rki(ikey_2 ),.round_out(result_2 ));
    encdec_round  encdec_round_3  (.round_in (r_result_2 ),.round_rki(ikey_3 ),.round_out(result_3 ));
    encdec_round  encdec_round_4  (.round_in (r_result_3 ),.round_rki(ikey_4 ),.round_out(result_4 ));
    encdec_round  encdec_round_5  (.round_in (r_result_4 ),.round_rki(ikey_5 ),.round_out(result_5 ));
    encdec_round  encdec_round_6  (.round_in (r_result_5 ),.round_rki(ikey_6 ),.round_out(result_6 ));
    encdec_round  encdec_round_7  (.round_in (r_result_6 ),.round_rki(ikey_7 ),.round_out(result_7 ));
    encdec_round  encdec_round_8  (.round_in (r_result_7 ),.round_rki(ikey_8 ),.round_out(result_8 ));
    encdec_round  encdec_round_9  (.round_in (r_result_8 ),.round_rki(ikey_9 ),.round_out(result_9 ));
    encdec_round  encdec_round_10 (.round_in (r_result_9 ),.round_rki(ikey_10),.round_out(result_10));
    encdec_round  encdec_round_11 (.round_in (r_result_10),.round_rki(ikey_11),.round_out(result_11));
    encdec_round  encdec_round_12 (.round_in (r_result_11),.round_rki(ikey_12),.round_out(result_12));
    encdec_round  encdec_round_13 (.round_in (r_result_12),.round_rki(ikey_13),.round_out(result_13));
    encdec_round  encdec_round_14 (.round_in (r_result_13),.round_rki(ikey_14),.round_out(result_14));
    encdec_round  encdec_round_15 (.round_in (r_result_14),.round_rki(ikey_15),.round_out(result_15));
    encdec_round  encdec_round_16 (.round_in (r_result_15),.round_rki(ikey_16),.round_out(result_16));
    encdec_round  encdec_round_17 (.round_in (r_result_16),.round_rki(ikey_17),.round_out(result_17));
    encdec_round  encdec_round_18 (.round_in (r_result_17),.round_rki(ikey_18),.round_out(result_18));
    encdec_round  encdec_round_19 (.round_in (r_result_18),.round_rki(ikey_19),.round_out(result_19));
    encdec_round  encdec_round_20 (.round_in (r_result_19),.round_rki(ikey_20),.round_out(result_20));
    encdec_round  encdec_round_21 (.round_in (r_result_20),.round_rki(ikey_21),.round_out(result_21));
    encdec_round  encdec_round_22 (.round_in (r_result_21),.round_rki(ikey_22),.round_out(result_22));
    encdec_round  encdec_round_23 (.round_in (r_result_22),.round_rki(ikey_23),.round_out(result_23));
    encdec_round  encdec_round_24 (.round_in (r_result_23),.round_rki(ikey_24),.round_out(result_24));
    encdec_round  encdec_round_25 (.round_in (r_result_24),.round_rki(ikey_25),.round_out(result_25));
    encdec_round  encdec_round_26 (.round_in (r_result_25),.round_rki(ikey_26),.round_out(result_26));
    encdec_round  encdec_round_27 (.round_in (r_result_26),.round_rki(ikey_27),.round_out(result_27));
    encdec_round  encdec_round_28 (.round_in (r_result_27),.round_rki(ikey_28),.round_out(result_28));
    encdec_round  encdec_round_29 (.round_in (r_result_28),.round_rki(ikey_29),.round_out(result_29));
    encdec_round  encdec_round_30 (.round_in (r_result_29),.round_rki(ikey_30),.round_out(result_30));
    encdec_round  encdec_round_31 (.round_in (r_result_30),.round_rki(ikey_31),.round_out(result_31));
                                                       

    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_0  <= 127'b0; else r_result_0  <= result_0 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_1  <= 127'b0; else r_result_1  <= result_1 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_2  <= 127'b0; else r_result_2  <= result_2 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_3  <= 127'b0; else r_result_3  <= result_3 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_4  <= 127'b0; else r_result_4  <= result_4 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_5  <= 127'b0; else r_result_5  <= result_5 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_6  <= 127'b0; else r_result_6  <= result_6 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_7  <= 127'b0; else r_result_7  <= result_7 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_8  <= 127'b0; else r_result_8  <= result_8 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_9  <= 127'b0; else r_result_9  <= result_9 ; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_10 <= 127'b0; else r_result_10 <= result_10; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_11 <= 127'b0; else r_result_11 <= result_11; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_12 <= 127'b0; else r_result_12 <= result_12; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_13 <= 127'b0; else r_result_13 <= result_13; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_14 <= 127'b0; else r_result_14 <= result_14; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_15 <= 127'b0; else r_result_15 <= result_15; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_16 <= 127'b0; else r_result_16 <= result_16; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_17 <= 127'b0; else r_result_17 <= result_17; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_18 <= 127'b0; else r_result_18 <= result_18; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_19 <= 127'b0; else r_result_19 <= result_19; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_20 <= 127'b0; else r_result_20 <= result_20; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_21 <= 127'b0; else r_result_21 <= result_21; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_22 <= 127'b0; else r_result_22 <= result_22; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_23 <= 127'b0; else r_result_23 <= result_23; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_24 <= 127'b0; else r_result_24 <= result_24; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_25 <= 127'b0; else r_result_25 <= result_25; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_26 <= 127'b0; else r_result_26 <= result_26; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_27 <= 127'b0; else r_result_27 <= result_27; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_28 <= 127'b0; else r_result_28 <= result_28; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_29 <= 127'b0; else r_result_29 <= result_29; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) r_result_30 <= 127'b0; else r_result_30 <= result_30; end
    always @(posedge clk or negedge rst_n) begin if (!rst_n) sm4_out     <= 127'b0; else sm4_out     <= reversed_result_31; end

    assign {word_0, word_1, word_2, word_3} = result_31;
    assign reversed_result_31 = {word_3, word_2, word_1, word_0};
endmodule
