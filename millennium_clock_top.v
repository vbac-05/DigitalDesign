// millennium_clock_top (DE2-115) 
// KEY (active-low):
//   KEY3 = rst_n
//   KEY2 = down (1 pulse/clk, chỉ tác dụng khi set_mode=1 và field_sel!=00)
//   KEY1 = up   (1 pulse/clk, chỉ tác dụng khi set_mode=1 và field_sel!=00)
//   KEY0 = toggle display_sel (smh <-> dmy)
// SW:
//   SW0        = run_en (tự chạy giây khi set_mode=0)
//   SW2:SW1    = field_sel (2-bit):
//                  00: không chỉnh
//                  01: chỉnh d/s  (DATE: day,   TIME: seconds)
//                  10: chỉnh m/m  (DATE: month, TIME: minutes)
//                  11: chỉnh y/h  (DATE: year,  TIME: hours)
//   SW3        = set_mode (1:  chỉnh; 0: không chỉnh)
// HEX: common-anode, active-low
module millennium_clock_top(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [17:0] SW,
    output wire [6:0]  HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7
);
    // ---------------- Clock & Reset ----------------
    wire clk   = CLOCK_50;
    wire rst_n = KEY[3]; // active-low button => 1=không nhấn

    // ---------------- Switches ----------------
    wire        run_en     = SW[0];
    wire [1:0]  field_sel  = SW[2:1]; // 00 none, 01 d/s, 10 m/m, 11 y/h
    wire        set_mode   = SW[3];

    // ---------------- Debounce CE 1 kHz ----------------
    wire deb_ce;
    ce_gen #(.CLK_HZ(50_000_000), .CE_HZ(1000)) u_debce(
        .clk(clk), .rst_n(rst_n), .ce(deb_ce)
    );

    // ---------------- Buttons (active-low) ----------------
    wire sel_p,   up_p,   down_p;
    btn_deb_onepulse_ce #(.STABLE_MS(20), .CE_HZ(1000)) u_sel  (
        .clk(clk), .rst_n(rst_n), .sample_ce(deb_ce),
        .btn_n(KEY[0]), .pressed(), .press_pulse(sel_p), .release_pulse()
    );
    btn_deb_onepulse_ce #(.STABLE_MS(20), .CE_HZ(1000)) u_up   (
        .clk(clk), .rst_n(rst_n), .sample_ce(deb_ce),
        .btn_n(KEY[1]), .pressed(),  .press_pulse(up_p),  .release_pulse()
    );
    btn_deb_onepulse_ce #(.STABLE_MS(20), .CE_HZ(1000)) u_down (
        .clk(clk), .rst_n(rst_n), .sample_ce(deb_ce),
        .btn_n(KEY[2]), .pressed(),  .press_pulse(down_p),  .release_pulse()
    );

    // ---------------- Tick + Blink ----------------
    wire tick_1hz, blink_2hz;
    tick_gen_1hz_2hz #(.CLK_HZ(50_000_000)) u_tick(
        .clk(clk), .rst_n(rst_n), .tick_1hz(tick_1hz), .blink_2hz(blink_2hz)
    );

    // ---------------- Display select: toggle bằng KEY0 ----------------
    wire display_sel; //=0: smh, =1:dmy
    display_selector #(.RESET_SEL(1'b0)) u_display_sel(
        .clk(clk), .rst_n(rst_n), .sel_p(sel_p), .display_sel(display_sel)
    );

    // ---------------- Auto-sec enable ----------------
    wire inc_sec_auto = run_en & ~set_mode & tick_1hz;

    // ---------------- Counters TIME ----------------
    wire [5:0] sec;  wire c_min;
    counter_mod60 u_sec (
        .clk(clk), .rst_n(rst_n),
        .inc_auto(inc_sec_auto),
        .inc_manual(set_mode & (field_sel==2'b01) & ~display_sel & up_p), // TIME + d/s = seconds
        .dec_manual(set_mode & (field_sel==2'b01) & ~display_sel & down_p),
        .value(sec), .carry_out(c_min)
    );

    wire [5:0] min;  wire c_hour;
    counter_mod60 u_min (
        .clk(clk), .rst_n(rst_n),
        .inc_auto(c_min),
        .inc_manual(set_mode & (field_sel==2'b10) & ~display_sel & up_p), // TIME + m/m = minutes
        .dec_manual(set_mode & (field_sel==2'b10) & ~display_sel & down_p),
        .value(min), .carry_out(c_hour)
    );

    wire [4:0] hour; wire c_day;
    counter_mod24 u_hour (
        .clk(clk), .rst_n(rst_n),
        .inc_auto(c_hour),
        .inc_manual(set_mode & (field_sel==2'b11) & ~display_sel & up_p), // TIME + y/h = hours
        .dec_manual(set_mode & (field_sel==2'b11) & ~display_sel & down_p),
        .value(hour), .carry_out(c_day)
    );

    // ---------------- Ngày / tháng / năm (+leap) ----------------
    wire [13:0] year; wire leap;  // từ counter_year_10000_leap
    counter_year_10000_leap u_year(
        .clk(clk), .rst_n(rst_n),
        .inc_auto(c_year),
        .inc_manual(set_mode & (field_sel==2'b11) &  display_sel & up_p), // DATE + y/h = year
        .dec_manual(set_mode & (field_sel==2'b11) &  display_sel & down_p),
        .value(year), .leap(leap)
    );
    
    wire [5:0]  dim;
    days_in_month_leap u_dim(.month(month), .leap(leap), .dim(dim));
    
    wire [5:0]  day;   wire c_month;
    counter_day_var u_day(
        .clk(clk), .rst_n(rst_n),
        .inc_auto(c_day),
        .inc_manual(set_mode & (field_sel==2'b01) &  display_sel & up_p), // DATE + d/s = day
        .dec_manual(set_mode & (field_sel==2'b01) &  display_sel & down_p),
        .dim(dim), .value(day), .carry_out(c_month)
    );
    
    wire [3:0]  month; wire c_year;
    counter_month_12 u_mon(
        .clk(clk), .rst_n(rst_n),
        .inc_auto(c_month),
        .inc_manual(set_mode & (field_sel==2'b10) &  display_sel & up_p), // DATE + m/m = month
        .dec_manual(set_mode & (field_sel==2'b10) &  display_sel & down_p),
        .value(month), .carry_out(c_year)
    );

    // ---------------- Double-Dabble sang BCD ----------------
    wire [3:0] s_t,s_o, m_t,m_o, h_t,h_o, d_t,d_o, mo_t,mo_o;
    ddab2 #(.WIDTH(6))  bcd_s (.bin(sec),         .tens(s_t),  .ones(s_o));
    ddab2 #(.WIDTH(6))  bcd_m (.bin(min),         .tens(m_t),  .ones(m_o));
    ddab2 #(.WIDTH(6))  bcd_h (.bin({1'b0,hour}), .tens(h_t),  .ones(h_o)); // 0..23
    ddab2 #(.WIDTH(6))  bcd_d (.bin(day),         .tens(d_t),  .ones(d_o)); // 1..31
    ddab2 #(.WIDTH(5))  bcd_M (.bin({1'b0,month}),.tens(mo_t), .ones(mo_o));// 1..12

    wire [3:0] y_th,y_hu,y_te,y_on;
    ddab4 #(.WIDTH(14)) bcd_y (.bin(year), .thousands(y_th), .hundreds(y_hu), .tens(y_te), .ones(y_on));

    // ---------------- 7-segment & blink ----------------
    wire blink_en = set_mode & (field_sel!=2'b00);       // chỉ blink khi đang chỉnh một field
    wire blink    = blink_en & blink_2hz;

    wire [6:0] hour_tens, hour_ones;
    wire [6:0] min_tens,  min_ones;
    wire [6:0] sec_tens,  sec_ones;
    wire [6:0] day_tens,  day_ones;
    wire [6:0] month_tens,month_ones;
    wire [6:0] year_thousands, year_hundreds, year_tens, year_ones;


    // Time
    sevenseg_hex_ca u_hour_t (.digit(h_t), .blank(display_sel ? 1'b1 : (blink && field_sel==2'b11)), .seg(hour_tens));
    sevenseg_hex_ca u_hour_o (.digit(h_o), .blank(display_sel ? 1'b1 : (blink && field_sel==2'b11)), .seg(hour_ones));

    sevenseg_hex_ca u_min_t  (.digit(m_t), .blank(display_sel ? 1'b1 : (blink && field_sel==2'b10)), .seg(min_tens));
    sevenseg_hex_ca u_min_o  (.digit(m_o), .blank(display_sel ? 1'b1 : (blink && field_sel==2'b10)), .seg(min_ones));

    sevenseg_hex_ca u_sec_t  (.digit(s_t), .blank(display_sel ? 1'b1 : (blink && field_sel==2'b01)), .seg(sec_tens));
    sevenseg_hex_ca u_sec_o  (.digit(s_o), .blank(display_sel ? 1'b1 : (blink && field_sel==2'b01)), .seg(sec_ones));

    // Date
    sevenseg_hex_ca u_day_t   (.digit(d_t),  .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b01)), .seg(day_tens));
    sevenseg_hex_ca u_day_o   (.digit(d_o),  .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b01)), .seg(day_ones));

    sevenseg_hex_ca u_month_t (.digit(mo_t), .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b10)), .seg(month_tens));
    sevenseg_hex_ca u_month_o (.digit(mo_o), .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b10)), .seg(month_ones));

    sevenseg_hex_ca u_year_3 (.digit(y_th), .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b11)), .seg(year_thousands));
    sevenseg_hex_ca u_year_2 (.digit(y_hu), .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b11)), .seg(year_hundreds));
    sevenseg_hex_ca u_year_1 (.digit(y_te), .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b11)), .seg(year_tens));
    sevenseg_hex_ca u_year_0 (.digit(y_on), .blank(~display_sel ? 1'b1 : (blink && field_sel==2'b11)), .seg(year_ones));


    // Ghép ra HEX
    assign {HEX7,HEX6,HEX5,HEX4,HEX3,HEX2,HEX1,HEX0} =
    (display_sel==1'b0) ? {7'h7F, 7'h7F, hour_tens, hour_ones, min_tens, min_ones, sec_tens, sec_ones}
                        : {day_tens, day_ones, month_tens, month_ones, year_thousands, year_hundreds, year_tens, year_ones};

endmodule


