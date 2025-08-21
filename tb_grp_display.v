`timescale 1ns/1ps
module tb_grp_display;
  // ddab2: 0..59
  reg  [5:0] v2;
  wire [3:0] t2,o2;
  ddab2 #(.WIDTH(6)) u2 (.bin(v2), .tens(t2), .ones(o2));

  // ddab4: 0..9999
  reg  [13:0] v4;
  wire [3:0] th,hu,te,on;
  ddab4 #(.WIDTH(14)) u4 (.bin(v4), .thousands(th), .hundreds(hu), .tens(te), .ones(on));

  // seven-seg (active-low)
  reg  [3:0] digit;
  wire [6:0] seg;
  sevenseg_hex_ca u7 (.digit(digit), .blank(1'b0), .seg(seg));

  // “Oracle” trong TB (OK dùng / % trong testbench)
  task check2; integer V, T, O;
    begin
      for (V=0; V<=59; V=V+1) begin
        v2 = V[5:0]; #1;
        T = (V/10)%10; O = V%10;
        if (t2!==T[3:0] || o2!==O[3:0]) begin
          $display("ERROR: ddab2 v=%0d got %0d%0d expect %0d%0d", V,t2,o2,T,O);
          $finish(2);
        end
      end
    end
  endtask

  task check4_sparse; integer V, Tt, Hh, Te, Oo;
    begin
      // quét thưa
      for (V=0; V<=9999; V=V+173) begin
        v4 = V[13:0]; #1;
        Tt=(V/1000)%10; Hh=(V/100)%10; Te=(V/10)%10; Oo=V%10;
        if (th!==Tt[3:0] || hu!==Hh[3:0] || te!==Te[3:0] || on!==Oo[3:0]) begin
          $display("ERROR: ddab4 v=%0d", V);
          $finish(2);
        end
      end
      // một số mốc
      V=0;     v4=V; #1; if (th!==0||hu!==0||te!==0||on!==0) $finish(2);
      V=9999;  v4=V; #1; if (th!==9||hu!==9||te!==9||on!==9) $finish(2);
      V=2024;  v4=V; #1; if (th!==2||hu!==0||te!==2||on!==4) $finish(2);
    end
  endtask

  task check_sevenseg_basic;
    begin
      digit=4'd0; #1; if (seg!==7'b1000000) begin $display("7seg 0 sai"); $finish(2); end
      digit=4'd1; #1; if (seg!==7'b1111001) begin $display("7seg 1 sai"); $finish(2); end
      digit=4'd8; #1; if (seg!==7'b0000000) begin $display("7seg 8 sai"); $finish(2); end
    end
  endtask

  initial begin
    $display("[TB] grp_display start");
    check2();
    check4_sparse();
    check_sevenseg_basic();
    $display("[OK] grp_display");
    $finish;
  end
endmodule
