`timescale 1ns/1ps
module tb_grp_io;
  // Clock 100 kHz → 10us/chu kỳ
  reg clk=0, rst_n=0;
  always #5000 clk = ~clk;

  // CE 1 kHz để sample nút
  wire ce_1khz;
  ce_gen #(.CLK_HZ(100_000), .CE_HZ(1_000)) u_ce (
    .clk(clk), .rst_n(rst_n), .ce(ce_1khz)
  );

  // Nút (active-low)
  reg btn_n = 1'b1;
  wire pressed, press_pulse, release_pulse;
  btn_deb_onepulse_ce #(.STABLE_MS(5), .CE_HZ(1000)) u_deb (
    .clk(clk), .rst_n(rst_n), .sample_ce(ce_1khz),
    .btn_n(btn_n), .pressed(pressed),
    .press_pulse(press_pulse), .release_pulse(release_pulse)
  );

  integer press_cnt=0, release_cnt=0;

  initial begin
    $display("[TB] grp_io start");
    rst_n=0; repeat(5) @(posedge clk); rst_n=1;

    // Rung nhanh khi nhấn rồi giữ 0
    #2000; btn_n=1'b0; #2000; btn_n=1'b1; #2000; btn_n=1'b0;
    #(10_000_000); // chờ > thời gian debounce
    if (!pressed) begin $display("ERROR: pressed chưa lên 1"); $finish(2); end

    // Rung khi nhả rồi giữ 1
    btn_n=1'b1; #2000; btn_n=1'b0; #2000; btn_n=1'b1;
    #(10_000_000);
    if (pressed) begin $display("ERROR: pressed chưa về 0"); $finish(2); end
    if (press_cnt!=1) begin $display("ERROR: press_pulse=%0d (!=1)", press_cnt); $finish(2); end
    if (release_cnt<1) begin $display("ERROR: release_pulse thiếu"); $finish(2); end

    $display("[OK] grp_io");
    $finish;
  end

  always @(posedge clk) begin
    if (press_pulse)   press_cnt   <= press_cnt+1;
    if (release_pulse) release_cnt <= release_cnt+1;
  end
endmodule
