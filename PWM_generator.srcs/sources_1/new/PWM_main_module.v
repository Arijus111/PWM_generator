`timescale 1ns / 1ps

module PWM_main_module(
    input clk,                          //100MHz clk;
    input rst,                          //Reset;
    input debounced_frequency_pulse,    //Frequency step request: 1-cycle pulse, one per button press;
    input debounced_duty_pulse,         //Duty-cycle step request: 1-cycle pulse, one per button press;
    output PWM_signal                   //PWM output signal;
    );
    
//FREQUENCY PARAMETERS TABLE;
localparam system_clk       = 100000000;            //General systems 100MHz clock;
localparam frequency_1MHz   = system_clk / 100;     //1MHz;
localparam frequency_500kHz = system_clk / 200;     //500kHz;
localparam frequency_333kHz = system_clk / 300;     //333.33kHz;
localparam frequency_250kHz = system_clk / 400;     //250MHz;
localparam frequency_200kHz = system_clk / 500;     //200MHz;
localparam frequency_166kHz = system_clk / 600;     //166.67MHz
localparam frequency_142kHz = system_clk / 700;     //142.86MHz 
localparam frequency_125kHz = system_clk / 800;     //125MHz;
localparam frequency_111kHz = system_clk / 900;     //111.11MHz;
localparam frequency_100kHz = system_clk / 1000;    //100kHz;

//DUTY-CYCLE PARAMETERS TABLE;
localparam duty_0   = 0;            //Signal always LOW;
localparam duty_10  = 10 / 100;     //10% duty-cycle;
localparam duty_20  = 20 / 100;     //20% duty-cycle;
localparam duty_30  = 30 / 100;     //30% duty-cycle; 
localparam duty_40  = 40 / 100;     //40% duty-cycle; 
localparam duty_50  = 50 / 100;     //50% duty-cycle; 
localparam duty_60  = 60 / 100;     //60% duty-cycle; 
localparam duty_70  = 70 / 100;     //70% duty-cycle; 
localparam duty_80  = 80 / 100;     //80% duty-cycle; 
localparam duty_90  = 90 / 100;     //90% duty-cycle;
localparam duty_100 = 100 / 100;    //Signal always HIGH;
    
endmodule
