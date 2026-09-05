`timescale 1ns / 1ps
//TOP MODULE - CONNECTS button_debounce AND PWM_main_module;

module Datapath(
    input clk,
    input rst,
    input asynch_frequency,
    input asynch_duty,
    output PWM_signal 
    );

wire debounced_frequency_pulse; //Connection between button_debounce and PWM_main_module;
wire debounced_duty_pulse;      //Connection between button_debounce and PWM_main_module;
     
button_debounce button_debounce0 (
    .clk(clk),
    .rst(rst),                       
    .asynch_frequency(asynch_frequency),                 
    .asynch_duty(asynch_duty),                     
    .debounced_frequency_pulse(debounced_frequency_pulse),   
    .debounced_duty_pulse(debounced_duty_pulse)         
    );
    
PWM_main_module PWM_main_module0 (
    .clk(clk),                          
    .rst(rst),                         
    .debounced_frequency_pulse(debounced_frequency_pulse),    
    .debounced_duty_pulse(debounced_duty_pulse),         
    .PWM_signal(PWM_signal)          
    );
    
endmodule
