`timescale 1ns/1ps
module tb_grp_time;
  reg clk=0, rst_n=0;
  always #5 clk = ~clk; // 100 MHz

  reg inc_sec_auto=0;
  wire [5:0] sec;  wire c_min;
  wire [5:0] min;  wire c_hour;
  wire [4:0] hour; wire c_day_unused;

  counter_mod60 u_sec  (.clk(clk), .rst_n(rst_n), .inc_auto(inc_sec_auto),
                        .inc_manual(1'b0), .dec_manual(1'b0),
                        .value(sec), .carry_out(c_min));
  counter_mod60 u_min  (.clk(clk), .rst_n(rst_n), .inc_auto(c_min),
                        .inc_manual(1'b0), .dec_manual(1'b0),
                        .value(min), .carry_out(c_hour));
  counter_mod24 u_hour (.clk(clk), .rst_n(rst_n), .inc_auto(c_hour),
                        .inc_manual(1'b0), .dec_manual(1'b0),
                        .value(hour), .carry_out(c_day_unused));

  task tick_sec; begin
    inc_sec_auto=1'b1; @(posedge clk);
    inc_sec_auto=1'b0; @(posedge clk);
  end endtask

  integer i;
  integer j;
  integer j2;

  initial begin
    $display("[TB] grp_time start");
    rst_n=0; repeat(4) @(posedge clk); rst_n=1;

    // Đẩy tới 23:59:58
    for (i=0;i<23;i=i+1) begin
      // tăng 1 giờ: 3600 xung giây
   
      for (j=0;j<3600;j=j+1) tick_sec();
    end
    // tăng 59 phút
    for (i=0;i<59;i=i+1) begin
      
      for (j2=0;j2<60;j2=j2+1) tick_sec();
    end
    // đến 23:59:58
    for (i=0;i<58;i=i+1) tick_sec();

    if (!(hour==23 && min==59 && sec==58)) begin
      $display("ERROR: không ở 23:59:58 (h=%0d m=%0d s=%0d)", hour,min,sec);
      $finish(2);
    end

    // Hai xung nữa → 00:00:00
    tick_sec(); // 59
    tick_sec(); // 00 + carry
    if (!(hour==0 && min==0 && sec==0)) begin
      $display("ERROR: không về 00:00:00 (h=%0d m=%0d s=%0d)", hour,min,sec);
      $finish(2);
    end

    $display("[OK] grp_time");
    $finish;
  end
endmodule
