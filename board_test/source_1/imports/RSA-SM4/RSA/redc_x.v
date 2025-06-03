module redc_x //input a, output a mod n 
#(
    parameter n  = 65'd21536215303153667899,
    parameter q  = 62'd1411149436910194189,
    parameter r  = 66'h20000000000000000,
    parameter r1 = 64'd15357272844265435333,
    parameter r2 = 64'd15661607970342841481
)( 
    input [129:0]  t,        // t in t mod n, should be a*r1
    output [64:0] x        //t mod n
);      
    wire [64:0] m;
    wire [64:0] t1;
    wire [126:0] prod;
    wire [129:0] result;


    assign prod = t[64:0] * q;
    assign m = prod[64:0]; //t*r1 = real t
    assign t1 = (t + m*n) >> 65;
    assign x = (t1 < n)? t1 : (t1-n);

    //debug
    // wire [129:0] mn;
    // wire [129:0] mnt;
    // assign mn = m * n;  
    // assign mnt = m*n + t*r1;      

endmodule //redc

