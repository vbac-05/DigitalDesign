module counter_mod24(
    input  wire       clk, 
    input  wire       rst_n,
    input  wire       inc_auto,
    input  wire       inc_manual, 
    input  wire       dec_manual,
    output reg  [4:0] value,
    output reg        carry_out
);
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin 
            value<=5'd0; 
            carry_out<=1'b0; end
        else begin
            carry_out <= 1'b0;
            if (inc_auto) begin
                if (value==5'd23) begin 
                    value<=5'd0; 
                    carry_out<=1'b1; end
                else value<=value+1'b1;
            end
            if (inc_manual) value <= (value==5'd23)?5'd0: value+1'b1;
            if (dec_manual) value <= (value==5'd0) ?5'd23: value-1'b1;
        end
    end
endmodule
