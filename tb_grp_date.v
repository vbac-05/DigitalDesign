`timescale 1ns/1ps
module tb_grp_date_2years;

  // ===== Clock & Reset =====
  reg clk;  initial clk = 1'b0;
  always #10 clk = ~clk;         // 50 MHz

  reg rst_n;

  // CE “cuối ngày”: xung 1 clk
  reg end_of_day_pulse;

  // DUT wires
  wire [13:0] year; wire leap;
  wire [3:0]  month; wire c_year;
  wire [5:0]  dim;
  wire [5:0]  day;   wire c_month;

  // Manual edit (chỉ dùng để set điểm bắt đầu – ngoài giai đoạn chạy EOD thì luôn 0)
  reg inc_y, dec_y, inc_m, dec_m, inc_d, dec_d;

  // Lấy mẫu carry 1 chu kỳ để kiểm tra
  reg c_month_q, c_year_q;
  always @(posedge clk) begin
    c_month_q <= c_month;
    c_year_q  <= c_year;
  end

  // ===== DUT =====
  counter_year_10000_leap u_year(
    .clk(clk), .rst_n(rst_n),
    .inc_auto(c_year),
    .inc_manual(inc_y), .dec_manual(dec_y),
    .value(year), .leap(leap)
  );

  counter_month_12 u_mon(
    .clk(clk), .rst_n(rst_n),
    .inc_auto(c_month),
    .inc_manual(inc_m), .dec_manual(dec_m),
    .value(month), .carry_out(c_year)
  );

  days_in_month_leap u_dim(.month(month), .leap(leap), .dim(dim));

  counter_day_var u_day(
    .clk(clk), .rst_n(rst_n),
    .inc_auto(end_of_day_pulse),
    .inc_manual(inc_d), .dec_manual(dec_d),
    .dim(dim), .value(day), .carry_out(c_month)
  );

  // ===== Pulse helpers (xung 1 clk) =====
  task eod(input integer n); integer i; begin
    for (i=0;i<n;i=i+1) begin
      @(posedge clk); end_of_day_pulse = 1'b1;
      @(posedge clk); end_of_day_pulse = 1'b0;
    end
  end endtask

  task inc_y_p; begin @(posedge clk); inc_y=1; @(posedge clk); inc_y=0; end endtask
  task inc_m_p; begin @(posedge clk); inc_m=1; @(posedge clk); inc_m=0; end endtask
  task inc_d_p; begin @(posedge clk); inc_d=1; @(posedge clk); inc_d=0; end endtask
  task dec_d_p; begin @(posedge clk); dec_d=1; @(posedge clk); dec_d=0; end endtask

  // ===== Set tương đối (chỉ dùng trước khi bắt đầu chạy) =====
  task set_year(input integer y_tgt); integer cur,k,delta; begin
    cur = year; delta = y_tgt - cur;
    if (delta>0)      for (k=0;k< delta;k=k+1) inc_y_p();
    else if (delta<0) for (k=0;k<-delta;k=k+1) /*dec_y not used*/ @(posedge clk);
  end endtask
  task set_month(input integer m_tgt); integer cur,k,delta; begin
    cur = month; delta = m_tgt - cur;
    if (delta>0)      for (k=0;k< delta;k=k+1) inc_m_p();
    else if (delta<0) for (k=0;k<-delta;k=k+1) /*dec_m not used*/ @(posedge clk);
  end endtask
  task set_day(input integer d_tgt); integer cur,k,delta; begin
    cur = day; delta = d_tgt - cur;
    if (delta>0)      for (k=0;k< delta;k=k+1) inc_d_p();
    else if (delta<0) for (k=0;k<-delta;k=k+1) dec_d_p();
  end endtask

  // ===== Reference calendar (TB dùng phép chia được phép) =====
  function integer ref_is_leap; input integer y; begin
    ref_is_leap = ((y%4)==0) && ( ((y%100)!=0) || ((y%400)==0) );
  end endfunction
  function integer ref_dim; input integer m,y; begin
    case (m)
      1,3,5,7,8,10,12: ref_dim = 31;
      4,6,9,11:        ref_dim = 30;
      2:               ref_dim = ref_is_leap(y) ? 29 : 28;
      default:         ref_dim = 31;
    endcase
  end endfunction

  // ===== EXPECT helpers =====
  task expect_date(input integer Ed, Em, Ey);
    begin
      if (day==Ed && month==Em && year==Ey)
        $display("PASS  DATE = %0d/%0d/%0d", Ed,Em,Ey);
      else begin
        $display("** FAIL  DATE DUT=%0d/%0d/%0d  EXP=%0d/%0d/%0d",
                 day,month,year, Ed,Em,Ey);
        $fatal(1);
      end
    end
  endtask
  task expect_c_month; begin
    if (c_month_q!==1'b1) $display("** FAIL: expected c_month pulse");
    else                  $display("PASS  c_month pulse");
  end endtask
  task expect_c_year; begin
    if (c_year_q!==1'b1)  $display("** FAIL: expected c_year pulse");
    else                  $display("PASS  c_year pulse");
  end endtask

  // ===== 2-year run (2023 & 2024) =====
  integer y, m, d, D;

  initial begin
    $timeformat(-9,2," ns",10);
    $display("==== tb_grp_date_2years start ====");

    // VCD: KHÔNG ghi phần preload 2023 để tránh thấy "year chạy liên tục"
    $dumpfile("tb_grp_date_2years.vcd");
    $dumpvars(0, tb_grp_date_2years);
    $dumpoff;

    // Init
    rst_n=0; end_of_day_pulse=0;
    inc_y=0; inc_m=0; inc_d=0; dec_d=0;
    repeat(5) @(posedge clk); rst_n=1;

    // --- Preload: 01/01/2023 ---
    set_year(2023); set_month(1); set_day(1);

    // Bắt đầu ghi waveform sau khi set xong
    $dumpon;

    // === Năm 2023 (non-leap) ===
    y = 2023;
    for (m=1; m<=12; m=m+1) begin
      D = ref_dim(m,y);
      $display("---- NEW MONTH %0d/%0d  (leap=%0d, dim=%0d) ----", 1, m, ref_is_leap(y), D);
      if (m==3) $display("NOTE: qua 28/2/2023 -> 1/3/2023 (non-leap)");
      for (d=1; d<=D; d=d+1) begin
        if (!(m==1 && d==1)) begin
          eod(1); // sang ngày tiếp theo
          if (d==1) begin
            expect_c_month;                   // wrap tháng
            if (m==1) expect_c_year;         // 31/12 -> 1/1 (không xảy ra trong năm 2023 loop)
          end
        end
        expect_date(d, m, y);                 // so khớp mỗi ngày
      end
    end

    // Sau vòng 2023, DUT đang ở 01/01/2024
    $display("==== NEW YEAR -> 1/1/2024 ====");
    expect_date(1,1,2024);

    // === Năm 2024 (leap) ===
    y = 2024;
    for (m=1; m<=12; m=m+1) begin
      D = ref_dim(m,y);
      $display("---- NEW MONTH %0d/%0d  (leap=%0d, dim=%0d) ----", 1, m, ref_is_leap(y), D);
      if (m==3) $display("NOTE: 2024 leap Feb had 29 days (28/2 -> 29/2 -> 1/3)");
      for (d=1; d<=D; d=d+1) begin
        if (!(m==1 && d==1)) begin
          eod(1);
          if (d==1) begin
            expect_c_month;
            if (m==1) expect_c_year; // từ 31/12/2023 -> 1/1/2024 (đã in ở trên)
          end
        end
        expect_date(d, m, y);
      end
    end

    // Kết thúc: 01/01/2025
    $display("==== DONE -> expect 1/1/2025 ====");
    eod(1); // bước cuối cùng sang 1/1/2025
    expect_c_month; expect_c_year;
    expect_date(1,1,2025);

    $display("==== tb_grp_date_2years PASS ====");
    $finish;
  end

endmodule
