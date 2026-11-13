`timescale 1ns / 1ps

module spi_controller (
    input wire clk,              // 100MHz system clock
    input wire reset,            
    input wire start,            // Start ADC conversion
    input wire [2:0] channel,    // ADC channel to read (0-7)
    output reg [9:0] adc_data,   // 10-bit ADC result
    output reg data_valid,       // Data ready flag
    output reg busy,             
    // SPI Interface
    output reg spi_clk,
    output reg spi_mosi,
    input wire spi_miso,
    output reg spi_cs
);

    // States
    localparam IDLE = 3'd0;
    localparam START_BIT = 3'd1;
    localparam SEND_CONFIG = 3'd2;
    localparam RECEIVE_DATA = 3'd3;
    localparam DONE = 3'd4;
    
    reg [2:0] state;
    reg [4:0] bit_counter;
    reg [15:0] shift_reg;
    reg [7:0] clk_div;
    reg clk_enable;
    
    // Clock divider for SPI clock (1MHz from 100MHz)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_div <= 8'd0;
            clk_enable <= 1'b0;
        end else begin
            if (clk_div == 8'd49) begin  // 100MHz/50 = 2MHz, /2 for toggle = 1MHz
                clk_div <= 8'd0;
                clk_enable <= 1'b1;
            end else begin
                clk_div <= clk_div + 1;
                clk_enable <= 1'b0;
            end
        end
    end
    
    // Main state machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            spi_cs <= 1'b1;
            spi_clk <= 1'b0;
            spi_mosi <= 1'b0;
            bit_counter <= 5'd0;
            shift_reg <= 16'd0;
            adc_data <= 10'd0;
            data_valid <= 1'b0;
            busy <= 1'b0;
        end else if (clk_enable) begin
            case (state)
                IDLE: begin
                    spi_cs <= 1'b1;
                    spi_clk <= 1'b0;
                    data_valid <= 1'b0;
                    busy <= 1'b0;
                    bit_counter <= 5'd0;
                    
                    if (start) begin
                        state <= START_BIT;
                        spi_cs <= 1'b0;
                        busy <= 1'b1;
                        // Prepare config: Start bit + SGL/DIFF + D2,D1,D0 (channel)
                        shift_reg <= {5'b00001, channel, 8'b0};
                    end
                end
                
                START_BIT: begin
                    spi_clk <= ~spi_clk;
                    if (spi_clk) begin
                        spi_mosi <= shift_reg[15];
                        shift_reg <= {shift_reg[14:0], 1'b0};
                        state <= SEND_CONFIG;
                        bit_counter <= 5'd1;
                    end
                end
                
                SEND_CONFIG: begin
                    spi_clk <= ~spi_clk;
                    if (spi_clk) begin
                        spi_mosi <= shift_reg[15];
                        shift_reg <= {shift_reg[14:0], 1'b0};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 5'd4) begin
                            state <= RECEIVE_DATA;
                            bit_counter <= 5'd0;
                        end
                    end
                end
                
                RECEIVE_DATA: begin
                    spi_clk <= ~spi_clk;
                    if (!spi_clk) begin  // Sample on falling edge
                        shift_reg <= {shift_reg[14:0], spi_miso};
                        bit_counter <= bit_counter + 1;
                        
                        if (bit_counter == 5'd11) begin  // Received 12 bits total
                            state <= DONE;
                            adc_data <= shift_reg[9:0];  // Extract 10-bit result
                        end
                    end
                end
                
                DONE: begin
                    spi_cs <= 1'b1;
                    spi_clk <= 1'b0;
                    data_valid <= 1'b1;
                    busy <= 1'b0;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule