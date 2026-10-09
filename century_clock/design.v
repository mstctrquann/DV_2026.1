module century_clock #(
    parameter CLK_FREQ = 50_000_000
)(
    input clk,
    input rst_n,
    input set_en,
    input [2:0] set_field, // 0: giây, 1: phút, 2: giờ
    input [11:0] set_value, // giá trị nạp vào
    output reg [5:0] sec,
    output reg [5:0] min,
    output reg [4:0] hour,
    output reg [4:0] day,
    output reg [3:0] month,
    output reg [6:0] year // năm trong khoảng 0-99
);

localparam CNT_WIDTH = $clog2(CLK_FREQ); // Số bit cần thiết để đếm đến CLK_FREQ
localparam CNT_MAX = CLK_FREQ - 1; // Giá trị đếm tối đa

reg [CNT_WIDTH-1:0] clk_cnt; // Thanh ghi giá trị đếm xung clk
wire tick_1s = (clk_cnt == CNT_MAX) ? 1'b1 : 1'b0; // xung tick_1s phát ra khi đếm đủ xung clk

// Bộ chia tần để tạo xung tick_1s
always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= {CNT_WIDTH{1'b0}};
        end else if (!set_en) begin
            if (tick_1s) begin
                clk_cnt <= {CNT_WIDTH{1'b0}};
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    end

// Kiểm tra năm nhuận; các năm chia hết cho 4 trong khoảng 00 - 99
wire is_leap_year = (year[1:0] == 2'b00 ? 1'b1 : 1'b0);
// 3. Hàm tổ hợp (Combinational function) tính số ngày tối đa của tháng
    function [4:0] get_days_in_month;
        input [3:0] m;
        input       leap;
        begin
            case (m)
                4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: get_days_in_month = 5'd31;
                4'd4, 4'd6, 4'd9, 4'd11:                     get_days_in_month = 5'd30;
                4'd2:                                        get_days_in_month = leap ? 5'd29 : 5'd28;
                default:                                     get_days_in_month = 5'd31;
            endcase
        end
    endfunction

    wire [4:0] max_days = get_days_in_month(month, is_leap_year);

    // Tín hiệu kích hoạt tràn (Cascade enable signals)
    wire sec_overflow   = tick_1s && (sec == 6'd59);
    wire min_overflow   = sec_overflow && (min == 6'd59);
    wire hour_overflow  = min_overflow && (hour == 5'd23);
    wire day_overflow   = hour_overflow && (day == max_days);
    wire month_overflow = day_overflow && (month == 4'd12);

    // 4. Khối đếm phân tầng và nạp giá trị (set)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec   <= 6'd0;
            min   <= 6'd0;
            hour  <= 5'd0;
            day   <= 5'd1;
            month <= 4'd1;
            year  <= 7'd0;
        end else if (set_en) begin
            // Nạp giá trị theo từng trường (set_field)
            case (set_field)
                3'd0: sec   <= set_value[5:0];
                3'd1: min   <= set_value[5:0];
                3'd2: hour  <= set_value[4:0];
                3'd3: day   <= set_value[4:0];
                3'd4: month <= set_value[3:0];
                3'd5: year  <= set_value[6:0];
                default: ;
            endcase
        end else begin
            // Đếm giây
            if (tick_1s) begin
                sec <= (sec == 6'd59) ? 6'd0 : (sec + 1'b1);
            end

            // Đếm phút
            if (sec_overflow) begin
                min <= (min == 6'd59) ? 6'd0 : (min + 1'b1);
            end

            // Đếm giờ
            if (min_overflow) begin
                hour <= (hour == 5'd23) ? 5'd0 : (hour + 1'b1);
            end

            // Đếm ngày
            if (hour_overflow) begin
                day <= (day == max_days) ? 5'd1 : (day + 1'b1);
            end

            // Đếm tháng
            if (day_overflow) begin
                month <= (month == 4'd12) ? 4'd1 : (month + 1'b1);
            end

            // Đếm năm (00 đến 99)
            if (month_overflow) begin
                year <= (year == 7'd99) ? 7'd0 : (year + 1'b1);
            end
        end
    end

endmodule