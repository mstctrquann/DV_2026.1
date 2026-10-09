module second_counter#( 
    parameter CLK_FREQ = 50_000_000
)( 
    input clk,
    input rst_n, 
    input en, 
    output reg [5:0] sec,
    output reg tick_1s
);

    localparam CNT_WIDTH = $clog2(CLK_FREQ); // Số bit cần thiết để đếm đến CLK_FREQ 
    localparam CNT_MAX = CLK_FREQ - 1; // Giá trị đếm tối đa

    reg [CNT_WIDTH-1:0] clk_cnt; // Thanh ghi giá trị đếm xung clk

    //module 1: bộ chia tần
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_cnt <= {CNT_WIDTH{1'b0}};
            tick_1s <= 1'b0;
        end else if (en) begin
            if (clk_cnt == CNT_MAX) begin
                clk_cnt <= {CNT_WIDTH{1'b0}};
                tick_1s <= 1'b1; // đếm đủ xung clk, phát ra xung 1s
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
                tick_1s <= 1'b0; // chưa đủ xung clk, không phát ra xung 1s
            end
        end else begin
            clk_cnt <= clk_cnt; // giữ nguyên giá trị đếm
            tick_1s <= 1'b0; // không phát ra xung 1s
        end
    end 
    //module 2: bộ đếm giây từ 0-59
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sec <= 6'd0;
        end else if (en && tick_1s) begin
            if (sec == 6'd59) begin
                sec <= 6'd0; // reset về 0 khi đạt 59
            end else begin
                sec <= sec + 1'b1; 
                end 
            end 
        end
    endmodule   
