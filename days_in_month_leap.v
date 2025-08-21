module days_in_month_leap(
    input  wire [3:0] month,  // 1..12
    input  wire       leap,   // 1 = năm nhuận
    output wire [5:0] dim     // 28..31
);
    assign dim =
        // Tháng 31 ngày
        (month==4'd1 || month==4'd3 || month==4'd5 || month==4'd7 || month==4'd8 || month==4'd10 || month==4'd12) ? 6'd31 :
        // Tháng 30 ngày
        (month==4'd4 || month==4'd6 || month==4'd9 || month==4'd11) ? 6'd30 :
        // Tháng 2: 28 hoặc 29 ngày
        (month==4'd2) ? (leap ? 6'd29 : 6'd28) :
        //nằm ngoài tháng 1-12
        6'd0; 
endmodule


