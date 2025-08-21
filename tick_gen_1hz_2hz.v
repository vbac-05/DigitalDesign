// Sinh tick 1 Hz (xung 1 clock / giây) để tăng giây,và tín hiệu blink 2 Hz (toggle mỗi 0.5 s) để nhấp nháy
module tick_gen_1hz_2hz #(
    parameter integer CLK_HZ = 50_000_000
)(
    input  wire clk,
    input  wire rst_n,
    output reg  tick_1hz,     // xung 1 clk / giây
    output reg  blink_2hz     // sóng vuông ~ 1 Hz (toggle mỗi 0.5 s)
);
    // --- Tick 1 Hz (pulse) ---
    reg [31:0] c1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin c1 <= 0; tick_1hz <= 1'b0; end
        else if (c1 == CLK_HZ - 1) begin
            c1 <= 0;
            tick_1hz <= 1'b1;   // xung 1 clk
        end else begin
            c1 <= c1 + 1'b1;
            tick_1hz <= 1'b0;
        end
    end

    // --- Blink 2 Hz (toggle mỗi 0.5 s) ---
    reg [31:0] c2;
    localparam integer HALF_SEC = CLK_HZ/2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin c2 <= 0; blink_2hz <= 1'b0; end
        else if (c2 == HALF_SEC - 1) begin
            c2 <= 0;
            blink_2hz <= ~blink_2hz; // sóng vuông
        end else begin
            c2 <= c2 + 1'b1;
        end
    end
endmodule
