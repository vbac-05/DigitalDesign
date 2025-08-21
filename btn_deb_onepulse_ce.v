//  Mục đích: Lọc rung phím (debounce) bằng sample CE (1 kHz),
//            rồi tạo xung 1-clock khi nhấn (press_pulse) và (tuỳ chọn)
//            xung khi nhả (release_pulse). Input nút active-low.
//  Quan trọng:
//   - Đồng bộ 2FF đưa nút về domain clk (tránh metastability).
//   - Đếm SAMPLES mẫu liên tiếp có cùng trạng thái mới cập nhật 'pressed'.
//   - CE giúp giữ 1 miền clock duy nhất, tránh tạo clock chậm mới.
// =============================================================
module btn_deb_onepulse_ce #(
    parameter integer STABLE_MS          = 20,   // thời gian ổn định yêu cầu
    parameter integer CE_HZ              = 1000, // tần số CE (khớp với ce_gen)
    parameter        GEN_RELEASE_PULSE   = 1     // 1: phát xung khi nhả
)(
    input  wire clk,
    input  wire rst_n,
    input  wire sample_ce,          // xung CE từ ce_gen (1 kHz)
    input  wire btn_n,              // nút raw, ACTIVE-LOW
    output reg  pressed,            // mức ổn định sau debounce (ACTIVE-HIGH)
    output wire press_pulse,        // xung 1-clk khi NHẤN (rising edge)
    output wire release_pulse       // xung 1-clk khi NHẢ (falling edge)
);
    // đồng bộ 2Ff => tránh nhiễu metastability và đồng bộ tín hiệu bấm với domain clk
    reg s0, s1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin 
            s0 <= 1'b1; 
            s1 <= 1'b1; 
        end
        else begin 
            s0 <= btn_n; 
            s1 <= s0; 
        end
    end
    wire btn_sync = ~s1; // đảo → ACTIVE-HIGH sau sync

    // --- Debounce theo số mẫu ổn định ---
    localparam integer SAMPLES = (STABLE_MS * CE_HZ + 999) / 1000; // làm tròn lên
    reg [$clog2(SAMPLES+1)-1:0] cnt;  // bộ đếm liên tiếp cùng mức
    reg last_sample;                   // mẫu gần nhất

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pressed     <= 1'b0;
            cnt         <= 0;
            last_sample <= 1'b0;
        end
        else if (sample_ce) begin
            if (btn_sync == last_sample) begin
                // cùng mức ⇒ tăng đếm, đủ SAMPLES thì cập nhật 'pressed'
                if (cnt < SAMPLES-1) cnt <= cnt + 1'b1;
                else                  pressed <= last_sample;
            end
            else begin
                // đổi mức ⇒ reset đếm, ghi lại mức mới
                last_sample <= btn_sync;
                cnt         <= 0;
            end
        end
    end

    // --- Tạo one-pulse theo cạnh của 'pressed' ---
    reg pressed_d;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) pressed_d <= 1'b0;
        else        pressed_d <= pressed;
    end

    assign press_pulse   =  pressed & ~pressed_d;                 // rising
    assign release_pulse = (GEN_RELEASE_PULSE) ? (~pressed & pressed_d) : 1'b0;
endmodule
