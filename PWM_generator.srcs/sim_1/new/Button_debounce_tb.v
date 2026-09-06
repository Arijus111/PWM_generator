`timescale 1ns / 1ps

module Button_debounce_tb();

reg clk = 0;
reg rst = 0;
reg asynch_frequency = 0;
reg asynch_duty = 0;

wire debounced_frequency_pulse;
wire debounced_duty_pulse;

initial clk = 1'b0;
always #5 clk = ~clk;

button_debounce uut(
    .clk(clk),                             
    .rst(rst),                         
    .asynch_frequency(asynch_frequency),                
    .asynch_duty(asynch_duty),
    .debounced_frequency_pulse(debounced_frequency_pulse),   
    .debounced_duty_pulse(debounced_duty_pulse)         
    );

initial begin
rst = 1'b0; #60;
rst = 1'b1; #60;
rst = 1'b0; #100;

asynch_frequency = 1'b1; #14; //Bouncing button press;
asynch_frequency = 1'b0; #17;
asynch_frequency = 1'b1; #23;
asynch_frequency = 1'b0; #18;
asynch_frequency = 1'b1; #800; //Button HOLD;
asynch_frequency = 1'b0; #28;
asynch_frequency = 1'b1; #26;
asynch_frequency = 1'b0; #300; //Button LOW;
$finish;
end 
   
endmodule
