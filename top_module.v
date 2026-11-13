`timescale 1ns / 1ps

module top_module (
    input wire clk,           // 100MHz clock
    input wire btnC,          // Center button - reset
    input wire btnU,          // Up button - start conversion
    input wire [2:0] sw,      // Switches - channel select
    output wire [15:0] led,   // LEDs - display ADC value and status
    output wire [6:0] seg,    // 7-segment display
    output wire [3:0] an,     // 7-segment anode
    output wire dp            // Decimal point
);

    // Internal signals
    wire reset;
    wire start_conversion;
    reg start_reg;
    wire [9:0] adc_result;
    wire data_ready;
    wire busy;
    
    // SPI signals
    wire spi_clk_internal;
    wire spi_mosi_internal;
    wire spi_miso_internal;
    wire spi_cs_internal;
    
    // Sensor values
    wire [9:0] sensor_values [0:7];
    
    // Stored channel values
    wire [9:0] stored_values [0:7];
    wire [15:0] sample_counter;
    
    // Button debouncing
    reg btnU_prev;
    reg [19:0] debounce_counter;
    
    assign reset = btnC;
    
    // Debounce and edge detection for start button
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            btnU_prev <= 1'b0;
            start_reg <= 1'b0;
            debounce_counter <= 20'd0;
        end else begin
            if (btnU != btnU_prev) begin
                debounce_counter <= 20'd0;
                btnU_prev <= btnU;
            end else if (debounce_counter < 20'd1000000) begin
                debounce_counter <= debounce_counter + 1;
            end else begin
                start_reg <= btnU && !busy;
            end
        end
    end
    
    assign start_conversion = start_reg && !busy;
    
    // Sensor value generator
    sensor_generator sensor_gen (
        .clk(clk),
        .reset(reset),
        .sensor0(sensor_values[0]),
        .sensor1(sensor_values[1]),
        .sensor2(sensor_values[2]),
        .sensor3(sensor_values[3]),
        .sensor4(sensor_values[4]),
        .sensor5(sensor_values[5]),
        .sensor6(sensor_values[6]),
        .sensor7(sensor_values[7])
    );
    
    // SPI Controller
    spi_controller spi_ctrl (
        .clk(clk),
        .reset(reset),
        .start(start_conversion),
        .channel(sw[2:0]),
        .adc_data(adc_result),
        .data_valid(data_ready),
        .busy(busy),
        .spi_clk(spi_clk_internal),
        .spi_mosi(spi_mosi_internal),
        .spi_miso(spi_miso_internal),
        .spi_cs(spi_cs_internal)
    );
    
    // ADC Simulator (acts as SPI slave)
    adc_simulator adc_sim (
        .spi_clk(spi_clk_internal),
        .spi_mosi(spi_mosi_internal),
        .spi_miso(spi_miso_internal),
        .spi_cs(spi_cs_internal),
        .ch0_value(sensor_values[0]),
        .ch1_value(sensor_values[1]),
        .ch2_value(sensor_values[2]),
        .ch3_value(sensor_values[3]),
        .ch4_value(sensor_values[4]),
        .ch5_value(sensor_values[5]),
        .ch6_value(sensor_values[6]),
        .ch7_value(sensor_values[7])
    );
    
    // Data Logger
    data_logger logger (
        .clk(clk),
        .reset(reset),
        .adc_data(adc_result),
        .data_valid(data_ready),
        .channel(sw[2:0]),
        .ch0_stored(stored_values[0]),
        .ch1_stored(stored_values[1]),
        .ch2_stored(stored_values[2]),
        .ch3_stored(stored_values[3]),
        .ch4_stored(stored_values[4]),
        .ch5_stored(stored_values[5]),
        .ch6_stored(stored_values[6]),
        .ch7_stored(stored_values[7]),
        .sample_count(sample_counter)
    );
    
    // LED outputs
    assign led[9:0] = adc_result;        // Display ADC value on LEDs 0-9
    assign led[10] = busy;               // LED 10 shows busy status
    assign led[11] = data_ready;         // LED 11 shows data ready
    assign led[14:12] = sw[2:0];        // LEDs 12-14 show selected channel
    assign led[15] = |sample_counter;    // LED 15 indicates samples received
    
    // 7-segment display (simplified - shows channel number)
    assign seg = 7'b1111111;  // Turn off for simplicity
    assign an = 4'b1111;      // Turn off all digits
    assign dp = 1'b1;         // Turn off decimal point
    
endmodule