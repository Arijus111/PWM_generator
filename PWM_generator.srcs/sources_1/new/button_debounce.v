`timescale 1ns / 1ps

//BUTTON DEBOUNCE LOGIC
//Synchronizes and debounces PWM frequency and duty cycle push buttons

//REQUIREMENTS:
//      *Asynchronous buttons has to be synchronized with 100MHz clock;
//      *Debounce time <=100ns;

module button_debounce(
    input clk,                  //General 100MHz systems frequency;
    input rst,                  //Reset signal;
    input asynch_frequency,     //Bouncing input frequency button;
    input asynch_duty,          //Bouncing input duty cycle button;
    output debounced_frequency, //Synchronized and debounced frequency select button;
    output debounced_duty       //Synchronized and debounced duty cycle select button;
    );
    
wire synch_frequency;                   //Internal wire for synchronized frequency button;
wire synch_duty;                        //Internal wire for synchronized duty-cycle button;

//SYNCHRONIZATION WITH CLK
    reg [1:0] frequency_synchronizer;       //Double flip-flop for frequency synchronization with clk;
    reg [1:0] duty_cycle_synchronizer;      //Double flip-flop for duty-cycle synchronization with clk;
    
    always@(posedge clk) begin
        if (rst) begin
            frequency_synchronizer <= 2'd0;   //Cleans register if rst 1;
            duty_cycle_synchronizer <= 2'd0;  //Cleans register if rst 1;
        end
        else begin
            frequency_synchronizer[0] <= asynch_frequency; //Frequency and duty-cycle buttons passes through registers for synchronization with posedge clk;
            frequency_synchronizer[1] <= frequency_synchronizer[0];
            duty_cycle_synchronizer[0] <= asynch_duty;
            duty_cycle_synchronizer[1] <= duty_cycle_synchronizer[0];
        end
    end
    assign synch_frequency = frequency_synchronizer[1]; //Assigns synchronized values for debounce logic
    assign synch_duty = duty_cycle_synchronizer[1];
//Total synchronization time - 20ns;
    
    
endmodule
