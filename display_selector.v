// Toggle TIME/DATE bằng 1 xung sel_p (one-pulse). Reset về TIME (0).
module display_selector #(
    parameter  RESET_SEL = 1'b0   // 0: TIME, 1: DATE
)(
    input  wire clk,
    input  wire rst_n,
    input  wire sel_p,        // one-pulse từ KEY0
    output reg  display_sel   // 0: TIME, 1: DATE
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)       display_sel <= RESET_SEL;
        else if (sel_p)   display_sel <= ~display_sel;  // toggle
    end
endmodule
