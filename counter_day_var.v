// =============================================================
// counter_day_var: đếm ngày theo dim (28/29/30/31), wrap 1-dim
// =============================================================
module counter_day_var(
    input  wire       clk, 
    input  wire       rst_n,
    input  wire       inc_auto,
    input  wire       inc_manual, 
    input  wire       dec_manual,
    input  wire [5:0] dim,          // 28..31
    output reg  [5:0] value,        // 1..dim
    output reg        carry_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            value<=6'd1; 
            carry_out<=1'b0; 
        end
        else begin
            carry_out <= 1'b0;
            if (inc_auto) begin
                if (value==dim) begin 
                    value<=6'd1; 
                    carry_out<=1'b1; 
                end
                else value<=value+1'b1;
            end
            if (inc_manual) value <= (value==dim)?6'd1: value+1'b1;
            if (dec_manual) value <= (value==6'd1)?dim : value-1'b1;

            if (value>dim) value <= dim; 
        end
    end
endmodule
