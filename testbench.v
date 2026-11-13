`timescale 1ns / 1ps

module testbench;
    reg clk;
    reg btnC;
    reg btnU;
    reg [2:0] sw;
    wire [15:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire dp;
    
    // Instantiate Unit Under Test
    top_module uut (
        .clk(clk),
        .btnC(btnC),
        .btnU(btnU),
        .sw(sw),
        .led(led),
        .seg(seg),
        .an(an),
        .dp(dp)
    );
    
    // Clock generation - 100MHz
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        // Initialize
        btnC = 1;  // Reset
        btnU = 0;
        sw = 3'b000;
        
        #100;
        btnC = 0;  // Release reset
        
        // Test Channel 0
        #1000;
        $display("Testing Channel 0");
        sw = 3'b000;
        #100;
        btnU = 1;
        #2000000;  // Wait for debounce
        btnU = 0;
        #100000;   // Wait for conversion
        $display("Channel 0 ADC Value: %d", led[9:0]);
        
        // Test Channel 1
        #10000;
        $display("Testing Channel 1");
        sw = 3'b001;
        #100;
        btnU = 1;
        #2000000;
        btnU = 0;
        #100000;
        $display("Channel 1 ADC Value: %d", led[9:0]);
        
        // Test Channel 2
        #10000;
        $display("Testing Channel 2");
        sw = 3'b010;
        #100;
        btnU = 1;
        #2000000;
        btnU = 0;
        #100000;
        $display("Channel 2 ADC Value: %d", led[9:0]);
        
        // Test all channels rapidly
        #10000;
        $display("Testing all channels in sequence");
        repeat(8) begin
            sw = sw + 1;
            #100;
            btnU = 1;
            #2000000;
            btnU = 0;
            #100000;
            $display("Channel %d ADC Value: %d", sw, led[9:0]);
        end
        
        #100000;
        $display("Test completed successfully!");
        $finish;
    end
    
    // Monitor important signals
    initial begin
        $monitor("Time=%0t Channel=%d Busy=%b DataReady=%b ADC=%d", 
                 $time, sw, led[10], led[11], led[9:0]);
    end
endmodule
