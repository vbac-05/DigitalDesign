module ddab2 #(
    parameter integer WIDTH = 8  // đủ chứa giá trị nhị phân đầu vào (≤99)
)(
    input  wire [WIDTH-1:0] bin,
    output reg  [3:0]       tens,
    output reg  [3:0]       ones
);
    //[TENS(4)][ONES(4)][BIN(WIDTH)]
    localparam integer MSB_TENS = WIDTH + 7;
    localparam integer LSB_TENS = WIDTH + 4;
    localparam integer MSB_ONES = WIDTH + 3;
    localparam integer LSB_ONES = WIDTH;

    reg [WIDTH+7:0] bcd;  // thanh ghi hợp nhất
    integer i;

    always @(bin) begin
        bcd = {8'b0, bin};

        // Lặp WIDTH lần (đưa dần các bit nhị phân vào BCD)
        for (i = 0; i < WIDTH; i = i + 1) begin
            // Nếu mỗi nibble >= 5 thì cộng 3
            bcd[MSB_TENS:LSB_TENS] =  (bcd[MSB_TENS:LSB_TENS] >= 4'd5) ? bcd[MSB_TENS:LSB_TENS] + 4'd3 : bcd[MSB_TENS:LSB_TENS];
            bcd[MSB_ONES:LSB_ONES] =  (bcd[MSB_ONES:LSB_ONES] >= 4'd5) ? bcd[MSB_ONES:LSB_ONES] + 4'd3 : bcd[MSB_ONES:LSB_ONES];
            // Shift trái 1 bit: bit MSB của bin được “đẩy” vào phần BCD
            bcd = bcd << 1;
        end

        // Tách kết quả
        tens = bcd[MSB_TENS:LSB_TENS];
        ones = bcd[MSB_ONES:LSB_ONES];
    end
endmodule


