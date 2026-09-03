`timescale 1ns / 1ps

//BUTTON DEBOUNCE LOGIC MODULE
//Synchronizes and debounces PWM frequency and duty cycle push buttons
//Total debounce logic response time = Synchronizer (20ns) + Debouncer (40ns to 70ns)

//REQUIREMENTS:
//  *Asynchronous buttons has to be synchronized with 100MHz clock;
//  *Total debounce time <= 100ns;
//  *Generate 1 tick pulse to change only 1 parameter per button push;

module button_debounce(
    input clk,                  //General 100MHz systems frequency;
    input rst,                  //Reset signal;
    input asynch_frequency,     //Bouncing input frequency button;
    input asynch_duty,          //Bouncing input duty cycle button;
    output debounced_frequency, //Synchronized and debounced frequency select button output;
    output debounced_duty       //Synchronized and debounced duty cycle select button output;
    );

    //SYNCHRONIZATION WITH CLK
    //TOTAL SYNCHRONIZATION TIME - 20ns;
        reg [1:0] frequency_synchronizer;           //Double flip-flop for frequency synchronization with clk;
        reg [1:0] duty_cycle_synchronizer;          //Double flip-flop for duty-cycle synchronization with clk;
        wire synch_frequency;                       //Internal wire for synchronized frequency button connection with debounce logic;
        wire synch_duty;                            //Internal wire for synchronized duty-cycle button connection with debounce logic;
        
        always@(posedge clk) begin
            if (rst) begin
                frequency_synchronizer <= 2'd0;     
                duty_cycle_synchronizer <= 2'd0;    
            end
            else begin
                frequency_synchronizer[0] <= asynch_frequency; //Frequency and duty-cycle buttons passes through registers for synchronization with posedge clk;
                frequency_synchronizer[1] <= frequency_synchronizer[0];
                duty_cycle_synchronizer[0] <= asynch_duty;
                duty_cycle_synchronizer[1] <= duty_cycle_synchronizer[0];
            end
        end
        assign synch_frequency = frequency_synchronizer[1]; //Assigns synchronized values for debounce logic
        assign synch_duty = duty_cycle_synchronizer[1];     //Assigns synchronized values for debounce logic
    
    //DEBOUNCE LOGIC
    //MAJORITY SHIFTER LOGIC: PICKS MOST COMMON VALUE FROM 7 SAMPLES; TOTAL DEBOUNCE TIME - 40ns to 70ns;
        reg [6:0] frequency_register;               //7-bit register for 7 frequency button samples;
        reg [6:0] duty_register;                    //7-bit register for 7 duty-cycle button samples;
        reg [2:0] frequency_register_sum_value;     //Sums total value of ones in frequency register;
        reg [2:0] duty_register_sum_value;          //Sums total value of ones in duty-cycle register;
        
        always@(posedge clk) begin  //Reset logic and button sample shifter;
            if (rst) begin
                frequency_register <= 7'b0000000;
                duty_register <= 7'b0000000;
            end
            else begin
                frequency_register <= {frequency_register[5:0], synch_frequency};   //Shifts synchronized button samples into 7-bit registers LSB position;
                duty_register <= {duty_register[5:0], synch_duty};
            end
        end
        
        integer i;  //Counter for bit sum;
        
        always@(*) begin    //Combinational block for frequency and duty-cycle sample registers bit sum;
            frequency_register_sum_value = 3'd0;
            duty_register_sum_value = 3'd0;
            for (i=0; i<=6; i=i+1) begin    
                frequency_register_sum_value = frequency_register_sum_value + frequency_register[i];    //frequency_register[0] + frequency_register[1] + ..
                duty_register_sum_value = duty_register_sum_value + duty_register[i];                   //duty_register[0] + duty_register[1] + ..
            end 
        end
        
        wire frequency_majority_value;  //Output for frequency majority value detection; 
        wire duty_majority_value;       //Output for duty-cycle majority value detection;      
        assign frequency_majority_value = (frequency_register_sum_value >= 4);  //Decides whether frequency_register_sum_value >=4;
        assign duty_majority_value = (duty_register_sum_value >= 4);            //Decides whether duty_register_sum_value >=4;
        
    //SINGLE TICK GENERATOR LOGIC
    //PURPOSE: GENERATE ONLY 1 TICK PULSE FOR 1 BUTTON PUSH;
    //COMPARES PREVIOUS AND CURRENT BUTTON VALUES FOR EDGE DETECTION;
        reg frequency_button_tick_prev; //Register for previous frequency value;
        reg duty_button_tick_prev;      //Register for previous duty-cycle value;
    
        always@(posedge clk) begin      //Previous value reset and storage block;
            if (rst) begin
                frequency_button_tick_prev <= 1'b0;
                duty_button_tick_prev <= 1'b0;
            end
            else begin
                frequency_button_tick_prev <= frequency_majority_value; //Stores previous frequency button value;
                duty_button_tick_prev <= duty_majority_value;           //Stores previous duty-cycle button value;
            end
        end
        
        assign debounced_frequency = frequency_majority_value && !frequency_button_tick_prev;   //Edge case detection - signal rises to HIGH for 1 cycle
        assign debounced_duty = duty_majority_value && !duty_button_tick_prev;                  //Edge case detection - signal rises to HIGH for 1 cycle      
endmodule
