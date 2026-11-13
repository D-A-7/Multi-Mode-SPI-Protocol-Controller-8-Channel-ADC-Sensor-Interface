`timescale 1ns / 1ps

module data_logger (
    input wire clk,
    input wire reset,
    input wire [9:0] adc_data,
    input wire data_valid,
    input wire [2:0] channel,
    output reg [9:0] ch0_stored,
    output reg [9:0] ch1_stored,
    output reg [9:0] ch2_stored,
    output reg [9:0] ch3_stored,
    output reg [9:0] ch4_stored,
    output reg [9:0] ch5_stored,
    output reg [9:0] ch6_stored,
    output reg [9:0] ch7_stored,
    output reg [15:0] sample_count
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ch0_stored <= 10'd0;
            ch1_stored <= 10'd0;
            ch2_stored <= 10'd0;
            ch3_stored <= 10'd0;
            ch4_stored <= 10'd0;
            ch5_stored <= 10'd0;
            ch6_stored <= 10'd0;
            ch7_stored <= 10'd0;
            sample_count <= 16'd0;
        end else if (data_valid) begin
            sample_count <= sample_count + 1;
            
            case (channel)
                3'd0: ch0_stored <= adc_data;
                3'd1: ch1_stored <= adc_data;
                3'd2: ch2_stored <= adc_data;
                3'd3: ch3_stored <= adc_data;
                3'd4: ch4_stored <= adc_data;
                3'd5: ch5_stored <= adc_data;
                3'd6: ch6_stored <= adc_data;
                3'd7: ch7_stored <= adc_data;
            endcase
        end
    end
endmodule