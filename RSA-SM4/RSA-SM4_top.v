module RSA_SM4_top (
  input              clk,
  input              rst_n,
  input              crypt_pre, //1clk
  input              den_sel,   //until crypt_ready, 0en 1de
  output             crypt_ready,
  input      [129:0] de_cmkey,
  output reg [129:0] en_cmkey,

  input      [127:0] input_stream,
  output     [127:0] output_stream

);
  //Bus contorl
  localparam IDLE = 3'd0;
  localparam ENCR = 3'd1;
  localparam DECR = 3'd2;

  localparam EN_IDLE     = 3'd0;
  localparam EN_GET_MKEY = 3'd1;
  localparam EN_RSA_1    = 3'd2;
  localparam EN_RSA_2    = 3'd3;
  localparam EN_KXP      = 3'd4;

  localparam DE_IDLE     = 3'd0;
  localparam DE_RSA_1    = 3'd1;
  localparam DE_RSA_2    = 3'd2;
  localparam DE_KXP      = 3'd3;

  reg [2:0] global_state; 
  reg en_key_exp_start,de_key_exp_start;
  reg [127:0] en_mkey,de_mkey;
  reg en_crypt_ready,de_crypt_ready;
  reg [1:0] cmd;
  reg [64:0] en_rsa_in,de_rsa_in;
  reg [129:0] r_de_cmkey;
  reg [1:0] en_cmd,de_cmd;
  wire key_exp_start;
  wire key_exp_done;
  wire [127:0] mkey;
  wire insync,outsync;
  wire [127:0] rdm_num;
  wire [64:0] rsa_out;
  wire [64:0] rsa_in;
  assign key_exp_start = (global_state == ENCR)? en_key_exp_start : de_key_exp_start;
  assign mkey          = (global_state == ENCR)? en_mkey:de_mkey;
  assign crypt_ready   = key_exp_done;
  assign rsa_in        = (global_state == ENCR)? en_rsa_in : de_rsa_in;
 //
  always @(*) begin
    if(global_state == ENCR) cmd = en_cmd;
    else if(global_state == DECR) cmd = de_cmd;
    else cmd = 2'b00;
  end



 always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
    global_state <= IDLE;
   end
   else begin
    if(crypt_pre)begin
      if(den_sel == 1'b0)  global_state <= ENCR;
      else if(den_sel == 1'b1)  global_state <= DECR;
      else global_state <= IDLE;
    end
    else if(crypt_ready) global_state<=IDLE;  
   end
 end
//EN
 reg [2:0] en_state;
 reg [2:0] de_state;

 
 always @(posedge clk or negedge rst_n) begin
   if (!rst_n) begin
    en_state <= IDLE;
    en_crypt_ready<=1'b0;
    en_mkey <= 128'b0;
    en_rsa_in <= 65'b0;
    en_key_exp_start<=1'b0;
    en_cmd <= 2'b00;
    en_cmkey<=130'b0;
   end
   else begin
    case (en_state)
      EN_IDLE:begin
        if(global_state == ENCR) en_state <= EN_GET_MKEY;
        else begin
          en_state <= IDLE;
          en_crypt_ready<=1'b0;
          en_mkey <= 128'b0;
          en_cmkey<=130'b0;
          en_rsa_in <= 65'b0;
          en_key_exp_start<=1'b0;
          en_cmd <= 2'b00;
        end
      end

      EN_GET_MKEY:begin
        en_state <= EN_RSA_1;
        en_mkey  <= rdm_num;
      end

      EN_RSA_1:begin
        if(rsa_rsp)begin 
          en_state      <= EN_RSA_2;
          en_cmkey[64:0]  <= rsa_out;
          en_cmd <= 2'b00;
        end
        else begin 
          en_cmd <= 2'b01;
          en_rsa_in <= {1'b0,en_mkey[63:0]};
        end
      end

      EN_RSA_2:begin
        if(rsa_rsp)begin 
          en_state      <= EN_KXP;
          en_cmkey[129:65]  <= rsa_out;
          en_cmd <= 2'b00;
        end
        else begin 
          en_cmd <= 2'b01;
          en_rsa_in <= {1'b0,en_mkey[127:64]};
        end
      end

      EN_KXP:begin
        if(key_exp_done)begin
          en_crypt_ready <= 1;
          en_state <= EN_IDLE;
          en_key_exp_start <= 1'b0;
        end
        else begin
          en_key_exp_start <= 1'b1;
        end
      end
    endcase
   end
 end

 //DE

 always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
   de_state <= DE_IDLE;
   de_crypt_ready <= 1'b0;
   de_mkey <= 128'b0;
   de_key_exp_start <= 1'b0;
   de_rsa_in <= 65'b0;
   de_cmd <= 2'b00;
  end
  else begin
   case (de_state)
     DE_IDLE:begin
       if(global_state == DECR) de_state <= DE_RSA_1;
       else begin
        de_state <= IDLE;
        de_crypt_ready <= 1'b0;
        de_mkey <= 128'b0;
        de_key_exp_start <= 1'b0;
        de_rsa_in <= 65'b0;
        de_cmd <= 2'b00;
       end
     end

     DE_RSA_1:begin
       if(rsa_rsp)begin 
         de_state      <= DE_RSA_2;
         de_mkey[63:0]  <= rsa_out;
         de_cmd <= 2'b00;
       end
       else begin 
        de_cmd <= 2'b10;
        de_rsa_in <= r_de_cmkey[64:0];
       end
     end

     DE_RSA_2:begin
       if(rsa_rsp)begin 
         de_state      <= DE_KXP;
         de_mkey[127:64]  <= rsa_out;
         de_cmd <= 2'b00;
       end
       else begin 
        de_cmd <= 2'b10;
        de_rsa_in <= r_de_cmkey[129:65];
       end
     end

     DE_KXP:begin
       if(key_exp_done)begin
         de_crypt_ready <= 1;
         de_state <= DE_IDLE;
         de_key_exp_start <= 1'b0;
       end
       else begin
         de_key_exp_start <= 1'b1;
       end
     end
   endcase
  end
end

always @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    r_de_cmkey <= 130'b0;
  end
  else begin
    if(crypt_pre)begin
      r_de_cmkey <= de_cmkey;
    end
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
   .msg   (rsa_in),//65- max 64bit edc
   .cmd   (cmd   ),//01:encrypt 10:decrypt   00|11 = invalid
   .p_msg (rsa_out),//65
   .p_sync(rsa_rsp)
 );

 sm4_top_parallel  sm4_top_parallel_inst(
    .clk          (clk          ),
    .rst_n        (rst_n        ),

    .enc_dec_sel  (den_sel      ),
    .mkey         (mkey         ),

    .sm4_in       (input_stream ),
    .in_sync      (in_sync      ),
    .sm4_out      (output_stream),
    .out_sync     (out_sync     ),

    .key_exp_start(key_exp_start),
    .key_exp_done (key_exp_done )
  );

endmodule //RSA-SM4_top