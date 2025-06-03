
/*User - control

  input [31:0]  BRAM_addr ,
  input         BRAM_clk  ,
  input [31:0]  BRAM_din  , 
  output[31:0]  BRAM_dout ,
  input         BRAM_en   ,  
  input         BRAM_rst  ,
  input [3:0]   BRAM_we   ,

*/

/*
Cipher Format:  [0:129] RSAed MKey,解密后舍去最高位
                [130:159]闲置
                [160:x] Cipher 密文从地址20开始读写
*/

  module envelope_top( //envelope top
  input clk,
  input [3:0]GPIO_in,
  output[3:0]GPIO_out,
  input [3:0]GPIO_T,
  // inout [2:0]GPIO_0_0_tri_io,

  output [31:0]  BRAM_addr ,
  output         BRAM_clk  ,
  output [31:0]  BRAM_din  ,
  input[31:0]    BRAM_dout ,
  output         BRAM_en   ,
  output         BRAM_rst  ,
  output [3:0]   BRAM_we   
  
    );
//  -  -  -  -  -  -  -  -  - GPIO Signal -  -  -  -  -  -  -  -  -  -  -  -  -
  wire evlp_done;
  wire crypt_start;
  wire den_sel; // 0:en 1:de
  wire rst_n;
  
  assign crypt_start = GPIO_in[0];
  assign den_sel = GPIO_in[1]; // 0:en 1:de
  assign GPIO_out = {1'b0,r_done,2'b0};
  assign evlp_done = (en_done | de_done)?1'b1:1'b0;
  assign rst_n = !GPIO_in[3];
//  -  -  -  -  -  -  -  -  - BRAM Signal -  -  -  -  -  -  -  -  -  -  -  -  -
  wire  [31:0] BRAM_addr;
  wire         BRAM_clk ;
  wire  [31:0] BRAM_din ;
  wire  [31:0] BRAM_dout;
  wire         BRAM_en  ;
  wire         BRAM_rst ;
  wire  [3:0]  BRAM_we  ;
  assign BRAM_addr = (state==ENCRYPTING) ? en_bram_addr : de_bram_addr;
  assign BRAM_clk  = clk    ;
  assign BRAM_din  = (state==ENCRYPTING) ? en_bram_wdin : de_bram_wdin;
  assign BRAM_en   = 1'b1;
  assign BRAM_rst  = !rst_n ;
  assign BRAM_we   =  (state==ENCRYPTING) ? {en_bram_wen,en_bram_wen,en_bram_wen,en_bram_wen} : {de_bram_wen,de_bram_wen,de_bram_wen,de_bram_wen};//字节控制，只进行全写
//  -  -  -  -  -  -  -  -  - Module Connection Signal -  -  -  -  -  -  -  -  -  -  -  -  -
  //rdm
  wire [127:0] rdm_num;
  reg  [127:0] r_gen_mkey;
  //rsa
  // wire [64:0]  rsa_msg_h,rsa_msg_l;
  // wire [64:0]  p_rsa_h,p_rsa_l;
  wire  [64:0] rsa_msg_in;
  wire [64:0]  rsa_msg_out;
  // wire         rsa_rsph,rsa_rspl;
  wire [1:0]   cmd;                   //01:encrypt 10:decrypt   00|11 = invalid
  wire [64:0]  en_rsa_msg_in;
  //sm4
  wire [127:0] mkey;
  wire [127:0] sm4_in;
  wire         in_sync ;
  wire [127:0] sm4_out ;
  wire         out_sync;
  wire         key_exp_start;
  wire         key_exp_done ;

  assign cmd      = (state==ENCRYPTING) ? en_cmd : de_cmd;
  assign key_exp_start = (state==ENCRYPTING)?en_key_exp_start:de_key_exp_start;
  assign mkey     = (state==ENCRYPTING)?r_gen_mkey:de_mkey;
  assign in_sync  = (state==ENCRYPTING)?en_in_sync:de_in_sync;
  assign sm4_in   = en_sm4_in;//(state==ENCRYPTING)?en_sm4_in:r_de_sm4_in;

  assign rsa_msg_in = (state==ENCRYPTING)?en_rsa_msg_in:de_rsa_msg_in;
  assign en_rsa_msg_in = rsa_cnt == 2'b1 ? {1'b0,r_gen_mkey[63:0]} : {1'b0,r_gen_mkey[127:64]}; //低位加密写在CMKEY高位

//======================================================================================== MAIN STATE CONTROL
  reg [1:0] state;
  wire      en_done;
  wire      de_done;
  localparam IDLE       = 2'b00;
  localparam ENCRYPTING = 2'b01;
  localparam DECRYPTING = 2'b10;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) state <= IDLE;
    else begin
      case (state)
        IDLE: begin
          if(crypt_start)begin
            if(den_sel == 1'b0)state <= ENCRYPTING;
            else if (den_sel)  state <= DECRYPTING;
          end
          else state <= IDLE;
        end

        ENCRYPTING:begin
          if(en_done) state <= IDLE;
          else state <= ENCRYPTING;
        end

        DECRYPTING:begin
          if(de_done) state <= IDLE;
          else state <= DECRYPTING;
        end
      endcase
    end
  end

  assign en_done = (state == ENCRYPTING) &&(insync_cnt == outsync_cnt)&&(insync_cnt!=32'd0);
  assign de_done = (state == DECRYPTING) &&(insync_cnt == outsync_cnt)&&(insync_cnt!=32'd0);
//======================================================================================== ENCRYPT CONTROL 
  //EN_REG
  reg [1:0]   en_cmd;
  wire        en_in_sync ;
  reg         en_key_exp_start;
  reg [31:0]  insync_cnt;
  reg [31:0]  outsync_cnt;
  wire        en_bram_wen;

  //EN_RAM
  reg  [2:0]  cmkey_bram_state;
  reg  [31:0] en_bram_waddr;
  reg  [31:0] en_bram_taddr;
  reg  [31:0] en_bram_din ;
  reg         en_bram_we  ;

  wire [31:0] en_bram_addr;
  reg  [31:0] en_bram_wdin;
  wire        en_bram_wwe  ;


  reg [1:0] en_state;
  localparam EN_IDLE    = 2'd0;   //                         Wait for (state == ENCRYPTING)
  localparam EN_RSAKXP  = 2'd1;   //cmd=01, key_exp_start=1  Wait for rsa_rsp & key_exp_done
  localparam EN_WRCMKEY = 2'd2;   //Read Bram,               Wait for (out_sync_cnt == in_sync_cnt)
  localparam EN_SM4     = 2'd3;   //Write Bram,              Wait for $write done

  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      en_state        <= EN_IDLE;
      en_cmd          <= 2'b00;
      en_key_exp_start<= 1'b0;
      
      cmkey_bram_state<= 3'b0;
      en_bram_taddr   <= 32'b0;
      en_bram_din     <= 32'b0;
      en_bram_we      <= 1'b0;
      en_bram_waddr   <= 32'b0;
      r_gen_mkey      <= 128'b0;
    end
    else begin
      case (en_state)
        EN_IDLE:begin
          if(state == ENCRYPTING) en_state <= EN_RSAKXP;
          else begin
            en_state        <= EN_IDLE;
            en_cmd          <= 2'b00;
            en_key_exp_start<= 1'b0;

            cmkey_bram_state<= 3'b0;
            en_bram_taddr   <= 32'b0;
            en_bram_din     <= 32'b0;
            en_bram_we      <= 1'b0;
            en_bram_waddr   <= 32'd20;
            r_gen_mkey      <= rdm_num; //debug$$$
            
          end
        end

        EN_RSAKXP:begin //等待轮密钥与RSA加密完成
          if(rsa_done && kxp_done) begin
            en_state        <= EN_WRCMKEY;
            en_cmd          <= 2'b00;
            en_key_exp_start<= 1'b0;
          end
          else begin
          en_cmd          <= (rsa_cnt == 2'd2 || rsa_rsp)?1'b0:1'b1;
          en_key_exp_start<= (kxp_done || key_exp_done)?1'b0:1'b1;
          end
        end

        EN_WRCMKEY:begin
          case (cmkey_bram_state) // 0-4 cmkey write in bram
            0:begin
              en_bram_taddr    <= 32'd0;
              en_bram_din     <= {cmkey[129:98]};
              en_bram_we      <= 1'b1;
              cmkey_bram_state<= 3'd1;
            end
            1:begin
              en_bram_taddr    <= 32'd4;
              en_bram_din     <= {cmkey[97:66]};
              en_bram_we      <= 1'b1;
              cmkey_bram_state<= 3'd2;
            end
            2:begin
              en_bram_taddr    <= 32'd8;
              en_bram_din     <= {cmkey[65:34]};
              en_bram_we      <= 1'b1;
              cmkey_bram_state<= 3'd3;
            end
            3:begin
              en_bram_taddr    <= 32'd12;
              en_bram_din     <= {cmkey[33:2]};
              en_bram_we      <= 1'b1;
              cmkey_bram_state<= 3'd4;
            end
            4:begin
              en_bram_taddr    <= 32'd16;
              en_bram_din     <= {cmkey[1:0],30'hDBD1337};
              en_bram_we      <= 1'b1;
              cmkey_bram_state<= 3'd5;
            end
            5:begin
              cmkey_bram_state<= 3'd0;
              en_state        <= EN_SM4;
              en_bram_taddr    <= 32'd20; //reset to addr 20
              en_bram_din     <= 32'b0;
              en_bram_we      <= 4'b0;
            end
          endcase
        end
          //BRAM 读取
            EN_SM4:begin //典型周期8，0-4读 5-8写 读写起始地址20，每20为一个128bit / 16Byte
              if(insync_cnt == outsync_cnt && insync_cnt != 32'd0) begin
                en_state <= EN_IDLE;
                end
              else begin
                if(en_sm4_loopcnt < 3'd4)begin //读周期
                  if(!en_read_done)begin //检测到\0停止读取
                    en_bram_taddr <= en_bram_taddr + 4;
                    en_bram_we   <= 1'b0;
                  end
                  else begin
                    en_bram_taddr <= 32'b0;
                    en_bram_we   <= 1'b0;
                  end
                end
                else begin //写周期
                  if(en_bram_wwe)
                    en_bram_waddr <= en_bram_waddr + 4;
                  //d_sm4_out;
                  //d_sm4_outsync;
                end
              end
            end
      endcase
    end
  end

  assign en_bram_wwe = (en_sm4_loopcnt>3'd3)?out_sync||d_sm4_outsync[0]||d_sm4_outsync[1]||d_sm4_outsync[2]:1'b0;
  assign en_bram_addr = (en_bram_wwe)?en_bram_waddr:en_bram_taddr;
  assign en_bram_wen = en_bram_wwe | en_bram_we;
  always @(*) begin
        if     (en_sm4_loopcnt == 3'd4) en_bram_wdin = sm4_out[127:96];
        else if(en_sm4_loopcnt == 3'd5) en_bram_wdin = BYTE2_d1;
        else if(en_sm4_loopcnt == 3'd6) en_bram_wdin = BYTE3_d2;
        else if(en_sm4_loopcnt == 3'd7) en_bram_wdin = BYTE4_d3;
        else  en_bram_wdin = en_bram_din;
  end

  reg [2:0] en_sm4_loopcnt;
  always @(posedge clk or negedge rst_n) begin//加密8周期计数
    if (!rst_n) begin
        en_sm4_loopcnt <= 3'b0;
    end
    else begin
      if(en_state == EN_SM4)begin
        en_sm4_loopcnt <= en_sm4_loopcnt + 3'b1;
      end
      else en_sm4_loopcnt <= 3'b0;
    end
  end

  assign en_in_sync = (en_sm4_loopcnt == 3'd4 && !en_read_done);

  // $$ below move to Main control
  wire   rsa_rsp;
  // assign rsa_msg_h = (state == ENCRYPTING) ? {1'b0,rdm_num[127:64]} : 64'b0; //$【DE】getinfo_mkey [129:65];
  // assign rsa_msg_l = (state == ENCRYPTING) ? {1'b0,rdm_num[ 63:0 ]} : 64'b0; //$【DE】getinfo_mkey [ 64:0 ];
//======================================================================================== DECRYPT CONTROL 

  reg  [31:0] de_bram_waddr;
  reg  [31:0] de_bram_taddr;
  reg  [31:0] de_bram_din ;
  reg         de_bram_we  ;
  wire        de_bram_wen;

  wire [31:0] de_bram_addr;
  reg  [31:0] de_bram_wdin;
  wire        de_bram_wwe  ;

  reg [1:0]   de_cmd;
  reg         de_key_exp_start;
  reg  [127:0]de_mkey;
  wire        de_in_sync;
  reg [127:0] r_de_sm4_in;
  reg [2:0]   de_state;
  reg [159:0] rd_cmkey;
  reg [64:0]  de_rsa_msg_in;
  reg [3:0]   dersastate;
  localparam DE_IDLE    = 3'd0;   //                         Wait for (state == ENCRYPTING)
  localparam DE_RSA     = 3'd1;   //cmd=01, key_exp_start=1  Wait for rsa_rsp & key_exp_done
  localparam DE_KXP     = 3'd2;
  localparam DE_SM4     = 3'd3;   //Read Bram,               Wait for (out_sync_cnt == in_sync_cnt)
  localparam DE_OUTPUT  = 3'd4;   //Write Bram,              Wait for $write done

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        de_state <= DE_IDLE;
    end
    else begin
      case(de_state)
      DE_IDLE:begin
        if(state == DECRYPTING) begin
          de_state <= DE_RSA;
        end
        else begin;
        de_bram_din <= 32'b0;
        de_bram_we  <= 32'b0;
        de_cmd      <= 2'b0;
        dersastate  <= 4'd0;
        rd_cmkey    <= 160'b0;
        de_key_exp_start <= 1'b0;
        r_de_sm4_in <= 32'b0;
        de_rsa_msg_in <= 65'b0;
        de_bram_taddr <= 32'b0;
        de_mkey <= de_mkey;
        de_bram_waddr <= 32'b0;
        end
      end
      DE_RSA:begin
        case (dersastate)
          0:begin
            de_bram_taddr<= 32'd4;
            de_bram_we  <= 32'b0;
            dersastate  <= 4'd1;
          end
          1:begin
            de_bram_taddr<= 32'd8;
            de_bram_we  <= 32'b0;
            rd_cmkey    <= {rd_cmkey[127:0],BRAM_dout};
            dersastate  <= 4'd2;
          end
          2:begin
            de_bram_taddr<= 32'd12;
            de_bram_we  <= 32'b0;
            rd_cmkey    <= {rd_cmkey[127:0],BRAM_dout};
            dersastate  <= 4'd3;
          end
          3:begin
            de_bram_taddr<= 32'd16;
            de_bram_we  <= 32'b0;
            rd_cmkey    <= {rd_cmkey[127:0],BRAM_dout};
            dersastate  <= 4'd4;
          end
          4:begin
            de_bram_taddr<= 32'd20;
            de_bram_we  <= 32'b0;
            rd_cmkey    <= {rd_cmkey[127:0],BRAM_dout};
            dersastate  <= 4'd5;
          end
          5:begin
            rd_cmkey    <= {rd_cmkey[127:0],BRAM_dout};
            de_bram_taddr<= 32'd20;
            de_bram_we  <= 32'b0;
            de_rsa_msg_in <= rd_cmkey[127:63];
            de_cmd      <= 2'b10;
            dersastate  <= 4'd6;
          end
          6:begin
            de_rsa_msg_in <= 160'b0;
            de_cmd      <= 2'b00;
            if(rsa_rsp) begin
              dersastate  <= 4'd7;
              de_mkey[127:64] <= rsa_msg_out[63:0];
            end
          end
          7:begin
            de_rsa_msg_in <= rd_cmkey[94:30];
            de_cmd      <= 2'b10;
            dersastate  <= 4'd8;
          end
          8:begin
            de_rsa_msg_in <= 160'b0;
            de_cmd      <= 2'b00;
            if(rsa_rsp) begin
              dersastate  <= 4'd0;
              de_mkey[63:0] <= rsa_msg_out[63:0];
              de_state <= DE_KXP;
            end
          end
        endcase
      end

      DE_KXP:begin
        if(key_exp_done) begin
          de_key_exp_start <= 1'b0;
          de_state <= DE_SM4;
        end
        else de_key_exp_start <= 1'b1;
      end

      DE_SM4:begin //典型周期8，0-4读 5-8写 读写起始地址20，每20为一个128bit / 16Byte
        if(insync_cnt == outsync_cnt && insync_cnt != 32'd0) begin
          de_state <= DE_IDLE;
          end
        else begin
          if(de_sm4_loopcnt < 3'd4)begin //读周期
            if(!de_read_done)begin //检测到\0停止读取
              de_bram_taddr <= de_bram_taddr + 4;
              de_bram_we   <= 1'b0;
            end
            else begin
              de_bram_taddr <= 32'b0;
              de_bram_we   <= 1'b0;
            end
          end
          else begin //写周期
            if(de_bram_wwe)
              de_bram_waddr <= de_bram_waddr + 4;
            //d_sm4_out;
            //d_sm4_outsync;
          end
        end
      end

      DE_OUTPUT:begin
        
      end
      endcase
    end
  end

  assign de_bram_wwe = (de_sm4_loopcnt>3'd3)?out_sync||d_sm4_outsync[0]||d_sm4_outsync[1]||d_sm4_outsync[2]:1'b0;
  assign de_bram_addr = (de_bram_wwe)?de_bram_waddr:de_bram_taddr;
  assign de_bram_wen = de_bram_wwe | de_bram_we;
  always @(*) begin
        if     (de_sm4_loopcnt == 3'd4) de_bram_wdin = sm4_out[127:96];
        else if(de_sm4_loopcnt == 3'd5) de_bram_wdin = BYTE2_d1;
        else if(de_sm4_loopcnt == 3'd6) de_bram_wdin = BYTE3_d2;
        else if(de_sm4_loopcnt == 3'd7) de_bram_wdin = BYTE4_d3;
        else  de_bram_wdin = 32'b0;
        end

  reg [2:0] de_sm4_loopcnt;
  always @(posedge clk or negedge rst_n) begin//加密8周期计数
    if (!rst_n) begin
        de_sm4_loopcnt <= 3'b0;
    end
    else begin
      if(de_state == DE_SM4)begin
        de_sm4_loopcnt <= de_sm4_loopcnt + 3'b1;
      end
      else de_sm4_loopcnt <= 3'b0;
      end
    end

  assign de_in_sync = (de_sm4_loopcnt == 3'd4 && !de_read_done);

//======================================================================================== DONE LATCH CONTROL 
  reg rsa_done;
  reg kxp_done;
  reg [129:0] cmkey; //cipher mkey
  reg en_read_done;
  reg de_read_done;
  reg [127:0] r_en_sm4_in;
  wire[127:0] en_sm4_in;
  reg [6:0]   d_sm4_outsync;
  reg [1:0]   rsa_cnt;
  reg         r_done;

  always @(posedge clk or negedge rst_n) begin//1.RSA Done Latch
    if (!rst_n) begin
      rsa_cnt  <= 2'b0;
    end
    else begin
      if(state == IDLE)  rsa_cnt <= 2'b0;
      else begin
        if(rsa_rsp) rsa_cnt  <= rsa_cnt + 1;
      end              
    end
  end
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rsa_done <= 1'b0;
    end
    else begin 
      if(state == IDLE)  rsa_done <= 1'b0;
      else if(rsa_cnt == 2'd2) rsa_done <= 1'b1;
    end
  end
  always @(posedge clk or negedge rst_n) begin//2.KXP Done Latch
    if (!rst_n) begin
      kxp_done <= 1'b0;
    end
    else begin
      if(state == IDLE)  kxp_done <= 1'b0;
      else               kxp_done <= key_exp_done || kxp_done;
    end
  end
  always @(posedge clk or negedge rst_n) begin//3.cmkey latch
    if (!rst_n) begin
        cmkey <= 130'b0;
    end
    else begin
      if(rsa_rsp)begin
        cmkey <= {cmkey[64:0],rsa_msg_out};
      end
      else cmkey <= cmkey;
    end
  end
  always @(posedge clk or negedge rst_n) begin//4.en_read_done latch 检测到ram输出有八位0 即"\0"停止位 就停止读取
    if (!rst_n) begin
      en_read_done <= 0;
    end
    else begin
      if(en_state == IDLE) en_read_done <= 0;
      else if(en_state == EN_SM4 && BRAM_dout[7:0] == 8'b0 && en_sm4_loopcnt == 8'd5) en_read_done <= 1;
    end
  end
  always @(posedge clk or negedge rst_n) begin//4.en_read_done latch 检测到ram输出有八位0 即"\0"停止位 就停止读取
    if (!rst_n) begin
      de_read_done <= 0;
    end
    else begin
      if(de_state == IDLE) de_read_done <= 0;
      else if(de_state == DE_SM4 && BRAM_dout[7:0] == 8'b0 && de_sm4_loopcnt == 8'd5) de_read_done <= 1;
    end
  end
  always @(posedge clk or negedge rst_n) begin //SM4输入控制
    if (!rst_n) begin
      r_en_sm4_in <= 128'b0;
    end
    else begin
      r_en_sm4_in <= {r_en_sm4_in[95:0],BRAM_dout};
    end
  end
  assign en_sm4_in = {r_en_sm4_in[95:0],BRAM_dout};//^can improve both de and en use this as sm4_in
    //in_sync out_sync 计数判断SM4加密是否完成
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      insync_cnt <= 32'b0;
    end
    else begin
      if(state == IDLE) insync_cnt <= 32'b0;
      else if(in_sync) insync_cnt <= insync_cnt + 1;
    end
  end
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      outsync_cnt <= 32'b0;
    end
    else begin
      if(state == IDLE)  outsync_cnt <= 32'b0;
      else if(d_sm4_outsync[6]) outsync_cnt <= outsync_cnt + 1;
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        r_done <= 0;
    end
    else begin
      if(crypt_start) r_done <= 0;
      else if(evlp_done)r_done <= 1'b1;
      else r_done <= r_done;
    end
  end

  //  sm4_out与Sync延后7周期以对应写周期
  reg [31:0] BYTE1_d1;
  reg [31:0] BYTE2_d1,BYTE2_d2;
  reg [31:0] BYTE3_d1,BYTE3_d2,BYTE3_d3;
  reg [31:0] BYTE4_d1,BYTE4_d2,BYTE4_d3,BYTE4_d4;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        d_sm4_outsync <= 7'b0;
    end
    else begin
      d_sm4_outsync <= {d_sm4_outsync[5:0],out_sync};
    end
  end

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      BYTE1_d1 <= 32'b0;BYTE2_d1 <= 32'b0;BYTE2_d2 <= 32'b0;
      BYTE3_d1 <= 32'b0;BYTE3_d2 <= 32'b0;BYTE3_d3 <= 32'b0;
      BYTE4_d1 <= 32'b0;BYTE4_d2 <= 32'b0;BYTE4_d3 <= 32'b0;
      BYTE4_d4 <= 32'b0;
    end
    else begin  //wait for improve ^^
      BYTE1_d1<= sm4_out[127:96];
      {BYTE2_d2,BYTE2_d1}<= {BYTE2_d1,sm4_out[95:64]};
      {BYTE3_d3,BYTE3_d2,BYTE3_d1}<= {BYTE3_d2,BYTE3_d1,sm4_out[63:32]};
      {BYTE4_d4,BYTE4_d3,BYTE4_d2,BYTE4_d1}<= {BYTE4_d3,BYTE4_d2,BYTE4_d1,sm4_out[31:0]};
    end
  end

  reg [127:0] r_mkey;
  always @(posedge clk or negedge rst_n) begin //only used for debug $$
    if (!rst_n) begin
        r_mkey <= 128'b0;
    end
    else begin
      if(en_state == EN_RSAKXP) r_mkey <= r_gen_mkey;
      else r_mkey <= r_mkey;
    end
  end






  rdm_gen  rdm_gen_inst (
    .clk    (clk    ),
    .rst_n  (rst_n  ),
    .rdm_num(rdm_num)//128
  );

  mod_exp mod_exp (
    .clk   (clk   ),
    .rst_n (rst_n ),
    .msg   (rsa_msg_in),//65- max 64bit edc
    .cmd   (cmd   ),//01:encrypt 10:decrypt   00|11 = invalid
    .p_msg (rsa_msg_out),//65
    .p_sync(rsa_rsp)
  );
  // mod_exp mod_exp_L (
  //   .clk   (clk   ),
  //   .rst_n (rst_n ),
  //   .msg   (rsa_msg_l),//65
  //   .cmd   (cmd   ),//01:encrypt 10:decrypt   00|11 = invalid
  //   .p_msg (p_rsa_l ),
  //   .p_sync(rsa_rspl)
  // );

  sm4_top_parallel  sm4_top_parallel_inst (
    .clk          (clk          ),
    .rst_n        (rst_n        ),

    .enc_dec_sel  (den_sel      ),
    .mkey         (mkey         ),

    .sm4_in       (sm4_in       ),
    .in_sync      (in_sync      ),
    .sm4_out      (sm4_out      ),
    .out_sync     (out_sync     ),

    .key_exp_start(key_exp_start),
    .key_exp_done (key_exp_done )
  );


endmodule
