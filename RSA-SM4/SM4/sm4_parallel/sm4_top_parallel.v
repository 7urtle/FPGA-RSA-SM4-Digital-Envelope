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


module sm4_top_parallel(
    input           clk,
    input           rst_n,
    input           enc_dec_sel, //0-enc,1-dec,从轮密钥生成开始持续输入到加解密结束
    input  [127:0]  mkey,


    input  [127:0]  sm4_in,
    input           in_sync,
    output [127:0]  sm4_out,
    output          out_sync,

    input           key_exp_start,
    output          key_exp_done
    );  
    wire [31:0] ikey_0,  ikey_1,  ikey_2,  ikey_3,  ikey_4,  ikey_5,  ikey_6,  ikey_7 ; 
    wire [31:0] ikey_8,  ikey_9,  ikey_10, ikey_11, ikey_12, ikey_13, ikey_14, ikey_15; 
    wire [31:0] ikey_16, ikey_17, ikey_18, ikey_19, ikey_20, ikey_21, ikey_22, ikey_23; 
    wire [31:0] ikey_24, ikey_25, ikey_26, ikey_27, ikey_28, ikey_29, ikey_30, ikey_31;

    //sync control (32clk)
    reg [31:0]sync_temp;

    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          sync_temp <= 32'b0;
      end
      else begin
        sync_temp <= {sync_temp[30:0],in_sync};
      end
    end

    assign out_sync = sync_temp[31];

    key_expansion_parallel  key_expansion_parallel_inst (
    .clk            (clk),
    .rst_n          (rst_n),
    .mkey           (mkey),
    .key_exp_start  (key_exp_start),
    .enc_dec_sel    (enc_dec_sel),
    .key_exp_done   (key_exp_done),

    .ikey_0(ikey_0),
    .ikey_1(ikey_1),
    .ikey_2(ikey_2),
    .ikey_3(ikey_3),
    .ikey_4(ikey_4),
    .ikey_5(ikey_5),
    .ikey_6(ikey_6),
    .ikey_7(ikey_7),
    .ikey_8(ikey_8),
    .ikey_9(ikey_9),
    .ikey_10(ikey_10),
    .ikey_11(ikey_11),
    .ikey_12(ikey_12),
    .ikey_13(ikey_13),
    .ikey_14(ikey_14),
    .ikey_15(ikey_15),
    .ikey_16(ikey_16),
    .ikey_17(ikey_17),
    .ikey_18(ikey_18),
    .ikey_19(ikey_19),
    .ikey_20(ikey_20),
    .ikey_21(ikey_21),
    .ikey_22(ikey_22),
    .ikey_23(ikey_23),
    .ikey_24(ikey_24),
    .ikey_25(ikey_25),
    .ikey_26(ikey_26),
    .ikey_27(ikey_27),
    .ikey_28(ikey_28),
    .ikey_29(ikey_29),
    .ikey_30(ikey_30),
    .ikey_31(ikey_31)
  );


    sm4_encdec_parallel  sm4_encdec_parallel_inst (
    .clk(clk),
    .rst_n(rst_n),
    .sm4_in(sm4_in),
    .sm4_out(sm4_out),

    .ikey_0 (ikey_0 ),
    .ikey_1 (ikey_1 ),
    .ikey_2 (ikey_2 ),
    .ikey_3 (ikey_3 ),
    .ikey_4 (ikey_4 ),
    .ikey_5 (ikey_5 ),
    .ikey_6 (ikey_6 ),
    .ikey_7 (ikey_7 ),
    .ikey_8 (ikey_8 ),
    .ikey_9 (ikey_9 ),
    .ikey_10(ikey_10),
    .ikey_11(ikey_11),
    .ikey_12(ikey_12),
    .ikey_13(ikey_13),
    .ikey_14(ikey_14),
    .ikey_15(ikey_15),
    .ikey_16(ikey_16),
    .ikey_17(ikey_17),
    .ikey_18(ikey_18),
    .ikey_19(ikey_19),
    .ikey_20(ikey_20),
    .ikey_21(ikey_21),
    .ikey_22(ikey_22),
    .ikey_23(ikey_23),
    .ikey_24(ikey_24),
    .ikey_25(ikey_25),
    .ikey_26(ikey_26),
    .ikey_27(ikey_27),
    .ikey_28(ikey_28),
    .ikey_29(ikey_29),
    .ikey_30(ikey_30),
    .ikey_31(ikey_31)
  );

endmodule
