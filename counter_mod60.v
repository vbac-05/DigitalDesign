//  Mục đích: Đếm 60 cho giây/phút. Có 3 nguồn:
//   - inc_auto: tăng tự động (có tạo carry_out khi 59->0)
//   - inc_manual / dec_manual: tăng/giảm khi chỉnh (wrap 0..59)
//  Quan trọng: carry_out chỉ phát khi inc_auto cuộn 59->0.
module counter_mod60(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       inc_auto,
    input  wire       inc_manual,
    input  wire       dec_manual,
    output reg  [5:0] value,       // 0-59
    output reg        carry_out    // =1 khi đếm đủ
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            value     <= 6'd0;
            carry_out <= 1'b0;
        end else begin
            carry_out <= 1'b0; // mặc định
            if (inc_auto) begin
                if (value == 6'd59) begin
                    value     <= 6'd0;
                    carry_out <= 1'b1;  // báo cuộn cho tầng trên
                end else begin
                    value     <= value + 1'b1;
                end
            end
            //Chỉnh tay: wrap 0-59, không phát carry
            if (inc_manual) value <= (value == 6'd59) ? 6'd0  : value + 1'b1;
            if (dec_manual) value <= (value == 6'd0 ) ? 6'd59 : value - 1'b1;
        end
    end
endmodule
