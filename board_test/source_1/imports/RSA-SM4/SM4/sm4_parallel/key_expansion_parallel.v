module key_expansion_parallel (
    input clk,rst_n,
    input [127:0] mkey,  //母密钥
    input key_exp_start, //与母密钥信号对齐,1周期
    input enc_dec_sel,   //0enc 1dec 持续
    output key_exp_done,
    output reg [31:0] ikey_0 ,
    output reg [31:0] ikey_1 ,
    output reg [31:0] ikey_2 ,
    output reg [31:0] ikey_3 ,
    output reg [31:0] ikey_4 ,
    output reg [31:0] ikey_5 ,
    output reg [31:0] ikey_6 ,
    output reg [31:0] ikey_7 ,
    output reg [31:0] ikey_8 ,
    output reg [31:0] ikey_9 ,
    output reg [31:0] ikey_10,
    output reg [31:0] ikey_11,
    output reg [31:0] ikey_12,
    output reg [31:0] ikey_13,
    output reg [31:0] ikey_14,
    output reg [31:0] ikey_15,
    output reg [31:0] ikey_16,
    output reg [31:0] ikey_17,
    output reg [31:0] ikey_18,
    output reg [31:0] ikey_19,
    output reg [31:0] ikey_20,
    output reg [31:0] ikey_21,
    output reg [31:0] ikey_22,
    output reg [31:0] ikey_23,
    output reg [31:0] ikey_24,
    output reg [31:0] ikey_25,
    output reg [31:0] ikey_26,
    output reg [31:0] ikey_27,
    output reg [31:0] ikey_28,
    output reg [31:0] ikey_29,
    output reg [31:0] ikey_30,
    output reg [31:0] ikey_31
  );

  localparam FK0 = 32'ha3b1bac6;
  localparam FK1 = 32'h56aa3350;
  localparam FK2 = 32'h677d9197;
  localparam FK3 = 32'hb27022dc;

  localparam IDLE    = 1'b0;
  localparam WORKING = 1'b1;
  
  //  -  -  -  -  -  -  -  -  - 密钥扩展轮函数输入控制 -  -  -  -  -  -  -  -  -  -  -  -  -

  reg state;
  reg  [4:0]    round_cnt;
  reg  [127:0]  round_in;
  wire [31:0]   cki;
  wire          key_exp_trigger;
  wire [127:0]  round_out;
  wire [4:0]    w_roundcnt; // encdec sel

  assign key_exp_done = (state == WORKING)&&(round_cnt == 5'd31);
  assign key_exp_trigger = (state == IDLE)&&(key_exp_start);


  always @(posedge clk or negedge rst_n) begin // 工作状态
    if(!rst_n)begin
        state <= IDLE;
    end
    else if (round_cnt == 5'd31) begin
        state <= IDLE;
    end
    else if (key_exp_start) begin
        state <= WORKING;
    end
    else state <= state;
  end

  always @(posedge clk or negedge rst_n) begin //轮数统计
    if (!rst_n) begin
        round_cnt <= 0;
    end
    else if (round_cnt == 5'd31) begin
        round_cnt <= 5'd0;
    end 
    else begin
        if(state == WORKING)begin
            round_cnt <= round_cnt + 1;
        end
    end
  end

  always @(posedge clk or negedge rst_n) begin //输入控制
    if(!rst_n)
        round_in <= 128'b0;
    else if (key_exp_trigger) 
        round_in <= (mkey ^ {FK0,FK1,FK2,FK3});
    else if(state == WORKING) 
        round_in <= round_out;
    else 
        round_in <= round_in;
  end

  keyexp_round  keyexp_round_inst (
    .round_in(round_in),
    .round_cki(cki),
    .round_out(round_out)
  );
  get_cki  get_cki_inst (
    .round_cnt(round_cnt),
    .cki(cki)
  );

  assign w_roundcnt = enc_dec_sel ? (5'd31-round_cnt) : round_cnt;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        ikey_0  <= 32'b0;
        ikey_1  <= 32'b0;
        ikey_2  <= 32'b0;
        ikey_3  <= 32'b0;
        ikey_4  <= 32'b0;
        ikey_5  <= 32'b0;
        ikey_6  <= 32'b0;
        ikey_7  <= 32'b0;
        ikey_8  <= 32'b0;
        ikey_9  <= 32'b0;
        ikey_10 <= 32'b0;
        ikey_11 <= 32'b0;
        ikey_12 <= 32'b0;
        ikey_13 <= 32'b0;
        ikey_14 <= 32'b0;
        ikey_15 <= 32'b0;
        ikey_16 <= 32'b0;
        ikey_17 <= 32'b0;
        ikey_18 <= 32'b0;
        ikey_19 <= 32'b0;
        ikey_20 <= 32'b0;
        ikey_21 <= 32'b0;
        ikey_22 <= 32'b0;
        ikey_23 <= 32'b0;
        ikey_24 <= 32'b0;
        ikey_25 <= 32'b0;
        ikey_26 <= 32'b0;
        ikey_27 <= 32'b0;
        ikey_28 <= 32'b0;
        ikey_29 <= 32'b0;
        ikey_30 <= 32'b0;
        ikey_31 <= 32'b0;
    end
    else begin
        ikey_0  <= (state == WORKING)&&(w_roundcnt == 5'd0 )? round_out : ikey_0 ;
        ikey_1  <= (state == WORKING)&&(w_roundcnt == 5'd1 )? round_out : ikey_1 ;
        ikey_2  <= (state == WORKING)&&(w_roundcnt == 5'd2 )? round_out : ikey_2 ;
        ikey_3  <= (state == WORKING)&&(w_roundcnt == 5'd3 )? round_out : ikey_3 ;
        ikey_4  <= (state == WORKING)&&(w_roundcnt == 5'd4 )? round_out : ikey_4 ;
        ikey_5  <= (state == WORKING)&&(w_roundcnt == 5'd5 )? round_out : ikey_5 ;
        ikey_6  <= (state == WORKING)&&(w_roundcnt == 5'd6 )? round_out : ikey_6 ;
        ikey_7  <= (state == WORKING)&&(w_roundcnt == 5'd7 )? round_out : ikey_7 ;
        ikey_8  <= (state == WORKING)&&(w_roundcnt == 5'd8 )? round_out : ikey_8 ;
        ikey_9  <= (state == WORKING)&&(w_roundcnt == 5'd9 )? round_out : ikey_9 ;
        ikey_10 <= (state == WORKING)&&(w_roundcnt == 5'd10)? round_out : ikey_10;
        ikey_11 <= (state == WORKING)&&(w_roundcnt == 5'd11)? round_out : ikey_11;
        ikey_12 <= (state == WORKING)&&(w_roundcnt == 5'd12)? round_out : ikey_12;
        ikey_13 <= (state == WORKING)&&(w_roundcnt == 5'd13)? round_out : ikey_13;
        ikey_14 <= (state == WORKING)&&(w_roundcnt == 5'd14)? round_out : ikey_14;
        ikey_15 <= (state == WORKING)&&(w_roundcnt == 5'd15)? round_out : ikey_15;
        ikey_16 <= (state == WORKING)&&(w_roundcnt == 5'd16)? round_out : ikey_16;
        ikey_17 <= (state == WORKING)&&(w_roundcnt == 5'd17)? round_out : ikey_17;
        ikey_18 <= (state == WORKING)&&(w_roundcnt == 5'd18)? round_out : ikey_18;
        ikey_19 <= (state == WORKING)&&(w_roundcnt == 5'd19)? round_out : ikey_19;
        ikey_20 <= (state == WORKING)&&(w_roundcnt == 5'd20)? round_out : ikey_20;
        ikey_21 <= (state == WORKING)&&(w_roundcnt == 5'd21)? round_out : ikey_21;
        ikey_22 <= (state == WORKING)&&(w_roundcnt == 5'd22)? round_out : ikey_22;
        ikey_23 <= (state == WORKING)&&(w_roundcnt == 5'd23)? round_out : ikey_23;
        ikey_24 <= (state == WORKING)&&(w_roundcnt == 5'd24)? round_out : ikey_24;
        ikey_25 <= (state == WORKING)&&(w_roundcnt == 5'd25)? round_out : ikey_25;
        ikey_26 <= (state == WORKING)&&(w_roundcnt == 5'd26)? round_out : ikey_26;
        ikey_27 <= (state == WORKING)&&(w_roundcnt == 5'd27)? round_out : ikey_27;
        ikey_28 <= (state == WORKING)&&(w_roundcnt == 5'd28)? round_out : ikey_28;
        ikey_29 <= (state == WORKING)&&(w_roundcnt == 5'd29)? round_out : ikey_29;
        ikey_30 <= (state == WORKING)&&(w_roundcnt == 5'd30)? round_out : ikey_30;
        ikey_31 <= (state == WORKING)&&(w_roundcnt == 5'd31)? round_out : ikey_31;
    end
  end

endmodule //key_expansion

