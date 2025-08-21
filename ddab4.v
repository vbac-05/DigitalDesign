module ddab4 #(
    parameter integer WIDTH = 14
)(
    input  wire [WIDTH-1:0] bin,
    output reg  [3:0]       thousands,
    output reg  [3:0]       hundreds,
    output reg  [3:0]       tens,
    output reg  [3:0]       ones
);
    //[THOU(4)][HUND(4)][TENS(4)][ONES(4)][BIN(WIDTH)]
    localparam integer MSB_THOUSANDS = WIDTH + 15;
    localparam integer LSB_THOUSANDS = WIDTH + 12;
    localparam integer MSB_HUNDRED = WIDTH + 11;
    localparam integer LSB_HUNDRED = WIDTH + 8;
    localparam integer MSB_TENS = WIDTH + 7;
    localparam integer LSB_TENS = WIDTH + 4;
    localparam integer MSB_ONES = WIDTH + 3;
    localparam integer LSB_ONES = WIDTH;

    reg [WIDTH+15:0] bcd;  // thanh ghi hợp nhất
    integer i;

    always @(bin) begin
        bcd = {16'b0, bin};

        // Lặp WIDTH lần (đưa dần các bit nhị phân vào BCD)
        for (i = 0; i < WIDTH; i = i + 1) begin
            // Nếu mỗi nibble >= 5 thì cộng 3
            bcd[MSB_THOUSANDS:LSB_THOUSANDS] = (bcd[MSB_THOUSANDS:LSB_THOUSANDS] >= 4'd5) ?   bcd[MSB_THOUSANDS:LSB_THOUSANDS] + 4'd3 : bcd[MSB_THOUSANDS:LSB_THOUSANDS];
            bcd[MSB_HUNDRED:LSB_HUNDRED] = (bcd[MSB_HUNDRED:LSB_HUNDRED] >= 4'd5) ? bcd[MSB_HUNDRED:LSB_HUNDRED] + 4'd3 : bcd[MSB_HUNDRED:LSB_HUNDRED] ;
            bcd[MSB_TENS:LSB_TENS] =  (bcd[MSB_TENS:LSB_TENS] >= 4'd5) ? bcd[MSB_TENS:LSB_TENS] + 4'd3 : bcd[MSB_TENS:LSB_TENS];
            bcd[MSB_ONES:LSB_ONES] =  (bcd[MSB_ONES:LSB_ONES] >= 4'd5) ? bcd[MSB_ONES:LSB_ONES] + 4'd3 : bcd[MSB_ONES:LSB_ONES];
            // Shift trái 1 bit: bit MSB của bin được “đẩy” vào phần BCD
            bcd = bcd << 1;
        end

        // Tách kết quả
        thousands = bcd[MSB_THOUSANDS:LSB_THOUSANDS];
        hundreds = bcd[MSB_HUNDRED:LSB_HUNDRED];
        tens = bcd[MSB_TENS:LSB_TENS];
        ones = bcd[MSB_ONES:LSB_ONES];
    end
endmodule