//tạo xung clock-enable : ce=1 đúng 1 chu kỳ khi đủ T xung clk
module ce_gen #(
    parameter integer CLK_HZ = 50_000_000 , 
    parameter integer CE_HZ = 1000
)(
    input clk,
    input rst_n,
    output reg ce
);
// Số chu kỳ clk cho mỗi lần phát CE
localparam  integer  T = CLK_HZ / CE_HZ  ;

reg [$clog2(T+1)-1:0] cnt;

always @(posedge clk or negedge rst_n) begin
  if(!rst_n) begin
    cnt <= 0;
    ce <= 1'b0;
  end
  else if (cnt == T-1) begin
    cnt <= 0;
    ce <= 1'b1;
  end
  else begin
    cnt <= cnt + 1'b1;
    ce <= 1'b0;
  end
end
endmodule