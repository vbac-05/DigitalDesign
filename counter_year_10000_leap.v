//Đếm năm 0-9999 với wrap, xuất 'leap'
//Duy trì y_mod4 / y_mod100 / y_mod400
//Chỉ cập nhật 1 lần/chu kỳ: nếu inc & dec cùng 1 → giữ nguyên.
module counter_year_10000_leap (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        inc_auto,     // carry từ tháng (12->1)
    input  wire        inc_manual,  
    input  wire        dec_manual, 
    output reg  [13:0] value,        // 0-9999
    output wire        leap          // năm nhuận?
);
    wire inc = inc_auto | inc_manual;
    wire dec = dec_manual;

    reg [1:0] y_mod4;    // 0-3
    reg [6:0] y_mod100;  // 0-99
    reg [8:0] y_mod400;  // 0-399

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            value    <= 14'd0;
            y_mod4   <= 2'd0;
            y_mod100 <= 7'd0;
            y_mod400 <= 9'd0;
        end else begin
            // Cập nhật đúng 1 hướng; 2'b11 hoặc 2'b00 -> giữ nguyên
            case ({inc, dec})
                2'b10: begin // INC
                    value    <= (value == 14'd9999) ? 14'd0: value + 1'b1;
                    y_mod4   <= (y_mod4 == 2'd3)   ? 2'd0   : y_mod4  + 1'b1;
                    y_mod100 <= (y_mod100 == 7'd99)  ? 7'd0   : y_mod100 + 1'b1;
                    y_mod400 <= (y_mod400 == 9'd399) ? 9'd0   : y_mod400 + 1'b1;
                end
                2'b01: begin // DEC
                    value    <= (value==14'd0) ? 14'd9999: value - 1'b1;
                    y_mod4   <= (y_mod4  ==2'd0)   ? 2'd3    : y_mod4  -1'b1;
                    y_mod100 <= (y_mod100==7'd0)   ? 7'd99   : y_mod100-1'b1;
                    y_mod400 <= (y_mod400==9'd0)   ? 9'd399  : y_mod400-1'b1;
                end
                default: begin end
            endcase
        end
    end

    // leap ⇔ (mod4==0) && (mod100!=0 || mod400==0)
    assign leap = (y_mod4 == 2'd0) && ( (y_mod100 != 7'd0) || (y_mod400 == 9'd0) );
endmodule
