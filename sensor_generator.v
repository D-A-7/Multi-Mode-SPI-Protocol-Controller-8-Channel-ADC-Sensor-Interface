`timescale 1ns / 1ps

module sensor_generator (
    input wire clk,
    input wire reset,
    output reg [9:0] sensor0,  // Temperature (20-40°C mapped to 0-1023)
    output reg [9:0] sensor1,  // Humidity (0-100% mapped to 0-1023)
    output reg [9:0] sensor2,  // Light level
    output reg [9:0] sensor3,  // Pressure
    output reg [9:0] sensor4,  // Voltage monitor 1
    output reg [9:0] sensor5,  // Voltage monitor 2
    output reg [9:0] sensor6,  // Current sensor
    output reg [9:0] sensor7   // Spare sensor
);

    reg [25:0] slow_counter;
    reg [9:0] triangle_wave;
    reg direction;
    
    // Generate realistic sensor patterns
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            slow_counter <= 26'd0;
            triangle_wave <= 10'd512;
            direction <= 1'b1;
            sensor0 <= 10'd512;  // 30°C
            sensor1 <= 10'd400;  // 40% humidity
            sensor2 <= 10'd800;  // Bright light
            sensor3 <= 10'd500;  // Normal pressure
            sensor4 <= 10'd615;  // 3.0V (5V scale)
            sensor5 <= 10'd717;  // 3.5V (5V scale)
            sensor6 <= 10'd100;  // Low current
            sensor7 <= 10'd0;
        end else begin
            slow_counter <= slow_counter + 1;
            
            // Update sensors every ~0.67 seconds
            if (slow_counter == 26'd67108863) begin
                slow_counter <= 26'd0;
                
                // Temperature: slow variation between 20-40°C
                if (sensor0 < 10'd600)
                    sensor0 <= sensor0 + 10'd5;
                else
                    sensor0 <= 10'd400;
                
                // Humidity: random-like variation
                sensor1 <= sensor1 + 10'd13;
                if (sensor1 > 10'd900) sensor1 <= 10'd100;
                
                // Light: triangle wave pattern
                if (direction) begin
                    if (triangle_wave < 10'd1000) begin
                        triangle_wave <= triangle_wave + 10'd20;
                    end else begin
                        direction <= 1'b0;
                    end
                end else begin
                    if (triangle_wave > 10'd20) begin
                        triangle_wave <= triangle_wave - 10'd20;
                    end else begin
                        direction <= 1'b1;
                    end
                end
                sensor2 <= triangle_wave;
                
                // Pressure: small variations
                sensor3 <= 10'd490 + (slow_counter[9:0] % 10'd20);
                
                // Voltages: stable with small noise
                sensor4 <= 10'd615 + (slow_counter[3:0]);
                sensor5 <= 10'd717 - (slow_counter[3:0]);
                
                // Current: step changes
                if (slow_counter[20])
                    sensor6 <= 10'd200;
                else
                    sensor6 <= 10'd100;
                
                // Spare: counter
                sensor7 <= sensor7 + 1;
            end
        end
    end
endmodule