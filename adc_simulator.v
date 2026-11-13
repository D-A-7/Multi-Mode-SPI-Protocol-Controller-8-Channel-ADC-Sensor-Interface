`timescale 1ns / 1ps

module adc_simulator (
    input wire spi_clk,
    input wire spi_mosi,
    output reg spi_miso,
    input wire spi_cs,
    input wire [9:0] ch0_value,  // Simulated sensor values
    input wire [9:0] ch1_value,
    input wire [9:0] ch2_value,
    input wire [9:0] ch3_value,
    input wire [9:0] ch4_value,
    input wire [9:0] ch5_value,
    input wire [9:0] ch6_value,
    input wire [9:0] ch7_value
);

    reg [4:0] bit_counter;
    reg [2:0] channel_select;
    reg [9:0] selected_value;
    reg [11:0] tx_data;
    reg config_received;
    
    always @(posedge spi_cs) begin
        bit_counter <= 5'd0;
        config_received <= 1'b0;
        spi_miso <= 1'b0;
    end
    
    always @(posedge spi_clk or posedge spi_cs) begin
        if (spi_cs) begin
            bit_counter <= 5'd0;
            spi_miso <= 1'b0;
        end else begin
            bit_counter <= bit_counter + 1;
            
            // Receive configuration bits
            if (bit_counter == 5'd3) begin
                channel_select[2] <= spi_mosi;
            end else if (bit_counter == 5'd4) begin
                channel_select[1] <= spi_mosi;
            end else if (bit_counter == 5'd5) begin
                channel_select[0] <= spi_mosi;
                config_received <= 1'b1;
                
                // Select channel value
                case ({channel_select[2], channel_select[1], spi_mosi})
                    3'd0: selected_value <= ch0_value;
                    3'd1: selected_value <= ch1_value;
                    3'd2: selected_value <= ch2_value;
                    3'd3: selected_value <= ch3_value;
                    3'd4: selected_value <= ch4_value;
                    3'd5: selected_value <= ch5_value;
                    3'd6: selected_value <= ch6_value;
                    3'd7: selected_value <= ch7_value;
                endcase
                
                tx_data <= {2'b00, selected_value};
            end
            
            // Send data bits
            if (config_received && bit_counter >= 5'd6) begin
                spi_miso <= tx_data[11];
                tx_data <= {tx_data[10:0], 1'b0};
            end
        end
    end
endmodule