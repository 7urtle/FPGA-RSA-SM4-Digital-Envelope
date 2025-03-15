

module rdm_gen ( //random number generator for sm4 mkey
    input          clk,
    input          rst_n,
    output [127:0] rdm_num
);
    reg [127:0] fcnt; //forward  counter
    reg [127:0] icnt; //inverted counter
    localparam drp = 128'b11111100000111010100010100111101110100100000011001001110000111011110010001001010110111001101101010011101111010101001101000111111;
    //disrupting factor

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            fcnt <= 128'b01111000110001011011101111011101000111010001110110001100001001011111110110101100001000000111110111000001100100111111111101101101;
            icnt <= 128'b11100100100011001010110100011001011011010101000111111011001010111011000110010100001101101010010110001110101111011110101100010100;
        end
        else begin
        fcnt <= {
            fcnt[63:56], fcnt[3:0],   fcnt[95:88],  fcnt[127:120],
            fcnt[31:24], fcnt[71:64], fcnt[79:72],  fcnt[15:8], 
            fcnt[55:48], fcnt[39:32], fcnt[111:104],fcnt[23:16], 
            fcnt[7:4]  , fcnt[103:96],fcnt[87:80],  fcnt[47:40], 
            fcnt[119:112]} + 128'd1;
        icnt <= {
            icnt[63:56], icnt[3:0],   icnt[95:88],  icnt[127:120],
            icnt[31:24], icnt[71:64], icnt[79:72],  icnt[15:8], 
            icnt[55:48], icnt[39:32], icnt[111:104],icnt[23:16], 
            icnt[7:4]  , icnt[103:96],icnt[87:80],  icnt[47:40], 
            icnt[119:112]} - 128'd1;
        end
      end

    assign rdm_num = fcnt ^ icnt ^ drp;

endmodule //rdm_gen