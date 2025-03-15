//  p = 9164222191 q = 2350031989 (10bit) 
//  n = p*q = 21536215303153667899 (65bit)  
//  φ(n) = (p-1)*(q-1) = 21536215291639413720
//  e = 17 (5bit)  
//  d = 11401525742632630793 (64bit)
//  inv_r = r' = 823744775142602116
//  inv_n = 35482338710508909043
//  n' = 1411149436910194189  
//  r1 = 15357272844265435333  
//  r2 = 15661607970342841481 

//  Pseudocode https://imgur.com/a/h5FjgZ6

module mod_exp  //montgomery
#(
    parameter  n = 65'd21536215303153667899,
    parameter  e = 64'd17,
    parameter  d = 64'd11401525742632630793,
    parameter  r = 66'h20000000000000000, //2^66 d36893488147419103232
    parameter  q = 62'd1411149436910194189, //n'
    parameter  r2 = 129'd15661607970342841481 //64'd
)(
    input           clk,
    input           rst_n,
    input  [64:0]   msg,  
    input  [1:0]    cmd,      //01:encrypt 10:decrypt   00|11 = invalid
    output [64:0]   p_msg,     //processed msg
    output          p_sync
);

    localparam IDLE    = 2'd0;
    localparam WORKING = 2'd1;
    localparam OUTPUT  = 2'd2;
    wire encrypt_trigger;
    wire decrypt_trigger;
    reg [64:0] result;
    reg [64:0] base;
    reg [63:0] exp;
    reg [1:0]  state;
    reg        sync;

    // wire [128:0] t_res_r2;
    //  reg  [64:0]  resR;

    // wire [128:0] t_bas_r2;
    // wire [64:0]  basR;

    // wire [128:0] t_resr_basr;
    // wire [64:0]  res_bas_R;

    // wire [128:0] t_basr_basr;
    // wire [64:0]  bas_bas_R;
    
    // wire [64:0]  bas_bas;
    // wire [64:0]  res_bas;
    reg [2:0]rsa_state;
    reg [129:0] redc_in;//, redc2_in;
    wire [64:0] redc_out;//, redc2_out;
    reg insync;

    reg [64:0] resR,basR,resbasR,basbasR,resbas;
    
    assign encrypt_trigger = (cmd==2'b01)?1:0;
    assign decrypt_trigger = (cmd==2'b10)?1:0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
         state <= IDLE;
         result<= 65'b01;   
         base<= 65'b0;
         exp <= 64'b0;
         sync<= 0;
         rsa_state <= 2'b0;
         insync <= 1'b0;
        end
        else begin
            case (state)
                IDLE:begin
                    if (encrypt_trigger) begin
                        base <= msg;
                        exp <= e;
                        state <= WORKING;
                    end
                    else if(decrypt_trigger) begin
                        base <= msg;
                        exp <= d;
                        state <= WORKING;
                    end
                    else begin
                        base <= 65'b0;
                        exp <= 64'b0;
                        state <= IDLE;
                        rsa_state <= 2'b0;
                    end
                    result<= 65'b01;
                    sync <= 0;
                end

                WORKING:begin
                  case(rsa_state)
                    3'd0:begin // res*r2 = resR mod n
                      if(redc_ready) begin
                        rsa_state <= 1;
                        insync <= 1'b0;
                        resR      <= redc_out;
                      end
                      else begin
                        redc_in  <= result*r2;
                        insync <= 1'b1;
                      end
                    end
                    3'd1:begin //bas*r2 = basR mod n
                      if(redc_ready) begin
                        rsa_state <= 2;
                        insync <= 1'b0;
                        basR      <= redc_out;
                      end
                      else begin
                        redc_in   <= base*r2;
                        insync <= 1'b1;
                      end
                    end
                    3'd2:begin //resR*basR = resbasR
                      if(redc_ready) begin
                        rsa_state <= 3;
                        insync <= 1'b0;
                        resbasR   <= redc_out;
                      end
                      else begin
                        redc_in   <= redc_out*resR;
                        insync <= 1'b1;
                      end
                    end
                    3'd3:begin //basR*basR = basbasR
                      if(redc_ready) begin
                        rsa_state <= 4;
                        insync <= 1'b0;
                        basbasR   <= redc_out; 
                      end
                      else begin
                        redc_in   <= basR*basR;
                        insync <= 1'b1;
                      end
                    end
                    3'd4:begin //resbasR = res*bas
                      if(redc_ready) begin
                        rsa_state <= 5;
                        insync <= 1'b0;
                        resbas    <= redc_out; 
                      end
                      else begin
                        redc_in   <= {65'b0,resbasR}; 
                        insync <= 1'b1;
                      end
                    end
                    3'd5:begin //basbasR = bas*bas
                      if(redc_ready) begin
                        rsa_state <= 6;
                        insync <= 1'b0;
                        base    <= redc_out; 
                      end
                      else begin
                        redc_in   <= {65'b0,basbasR};
                        insync <= 1'b1;
                      end
                    end
                    3'd6:begin                              //redc1_out = res*bas
                      if(exp > 0)begin                    //redc2_out = bas*bas
                        if(exp[0] == 1)begin
                            result <= resbas; 
                        end
                        exp <= exp >> 1;
                        rsa_state <= 3'd0;
                    end
                    else begin
                        state <= OUTPUT;
                        sync <= 1;
                    end
                    end
                  endcase
                end
                OUTPUT:begin
                    sync <= 0;
                    state <= IDLE;
                end
            endcase
        end
      end
    
    assign p_msg = result;
    assign p_sync= sync;
//  -  -  -  -  -  -  -  -  - mod control -  -  -  -  -  -  -  -  -  -  -  -  -
//https://imgur.com/a/8rdHwS3



    redc_x redc_gpt_inst (
    .clk(clk),
    .t(redc_in),
    .x(redc_out)
  );
  reg [2:0] redc_cnt;
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        redc_cnt <= 3'b0;
    end
    else begin
      if(redc_cnt == 3'd5) redc_cnt <= 0;
      else if(insync)redc_cnt <= redc_cnt + 1;
    end
  end
  wire redc_ready;
  assign redc_ready = (redc_cnt == 3'd5);

  // redc_x redc_2 (                                                        //change-2
  //   .t(redc2_in),
  //   .x(redc2_out)
  // );
                                                                            //change-1
  // redc_x redc_result_r2 ( //res*r2 = resR mod n       //tier1
  //   .t(t_res_r2),
  //   .x(resR)
  // );

  // redc_x redc_base_r2 ( //bas*r2 = basR mod n         //tier1
  //   .t(t_bas_r2),
  //   .x(basR)
  // );
  
  // redc_x redc_resr_basr (//resR*basR = resbasR mod n  //tier2
  //   .t(t_resr_basr),
  //   .x(res_bas_R)
  // );

  // redc_x redc_basr_basr (//basR*basR = basbasR mod n   //tier2
  //   .t(t_basr_basr),
  //   .x(bas_bas_R)
  // );

  // redc_x redc_basbasr (//basR*basR = basbasR mod n     //tier3
  //   .t({64'b0,bas_bas_R}),
  //   .x(bas_bas)
  // );

  // redc_x redc_resbasr (//basR*basR = basbasR mod n     //tier3
  //   .t({64'b0,res_bas_R}),
  //   .x(res_bas)
  // );

endmodule //mod_exp