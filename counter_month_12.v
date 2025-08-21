//đếm 1..12; inc_auto sinh carry_out khi 12->1

module counter_month_12(
    input  wire      clk, 
    input  wire      rst_n,
    input  wire      inc_auto,
    input  wire      inc_manual, 
    input  wire      dec_manual,
    output reg [3:0] value,       // 1-12
    output reg       carry_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            value<=4'd1; 
            carry_out<=1'b0; 
        end
        else begin
            carry_out<=1'b0;
            if (inc_auto) begin
                if (value==4'd12) begin 
                    value<=4'd1; 
                    carry_out<=1'b1; 
                end
                else value <= value+1'b1;
            end
            if (inc_manual) value <= (value==4'd12)? 4'd1:  value + 1'b1;
            if (dec_manual) value <= (value==4'd1) ? 4'd12: value - 1'b1;
        end
    end
endmodule
