`timescale 1ns / 1ps

//BUTTON DEBOUNCE LOGIC MODULE;
//Synchronizes and debounces PWM frequency and duty cycle push buttons;
//RESPONSE TIME: 30ns fixed (2 sync cycles + 1 pulse cycle);

//REQUIREMENTS:
//  *Asynchronous buttons has to be synchronized with 100MHz clock;
//  *Total debounce time <= 100ns;
//  *Generate 1 tick pulse to change only 1 parameter per button push;

module button_debounce(
    input clk,                              //General 100MHz systems frequency;
    input rst,                              //Reset signal;
    input asynch_frequency,                 //Bouncing input frequency button;
    input asynch_duty,                      //Bouncing input duty cycle button;
    output reg debounced_frequency_pulse,   //Synchronized and debounced frequency select button output;
    output reg debounced_duty_pulse         //Synchronized and debounced duty cycle select button output;
    );

        //SYNCHRONIZATION WITH CLK;
        //TOTAL SYNCHRONIZATION TIME - 20ns;
        reg [1:0] frequency_synchronizer;           //Double flip-flop register for frequency synchronization with clk;
        reg [1:0] duty_cycle_synchronizer;          //Double flip-flop register for duty-cycle synchronization with clk;
        wire synch_frequency;                       //Internal wire for synchronized frequency button connection with debounce logic;
        wire synch_duty;                            //Internal wire for synchronized duty-cycle button connection with debounce logic;
        
        always@(posedge clk) begin
            if (rst) begin
                frequency_synchronizer <= 2'd0;     
                duty_cycle_synchronizer <= 2'd0;    
            end
            else begin
                //Frequency and duty-cycle buttons passes through registers for synchronization with posedge clk;
                frequency_synchronizer[0] <= asynch_frequency;
                frequency_synchronizer[1] <= frequency_synchronizer[0];
                duty_cycle_synchronizer[0] <= asynch_duty;
                duty_cycle_synchronizer[1] <= duty_cycle_synchronizer[0];
            end
        end
        assign synch_frequency = frequency_synchronizer[1]; //Assigns synchronized values for debounce logic;
        assign synch_duty = duty_cycle_synchronizer[1];     //Assigns synchronized values for debounce logic;
    
        //DEBOUNCE LOGIC;
        //WAITS FOR THE FIRST HIGH SAMPLE, THEN IGNORES INPUT UNTIL 11 CONSECUTIVE LOW SAMPLES;
        //Latency - 10ns; 
        reg frequency_ready;                //Waits for the first HIGH synch_frequency;   
        reg duty_ready;                     //Waits for the first HIGH synch_duty;
        reg [3:0] frequency_zero_counter;   //Waits for 11 ZEROS to enable next button sampling;
        reg [3:0] duty_zero_counter;        //Waits for 11 ZEROS to enable next button sampling;
        
        //Frequency debounce block;
        always@(posedge clk) begin
            if (rst) begin
                frequency_ready <= 1'b1;
                frequency_zero_counter <= 4'b0;
                debounced_frequency_pulse <= 1'b0;
            end
            else begin
                debounced_frequency_pulse <= 1'b0;          //Default output value;
                if (frequency_ready) begin                  //Condition for first synchronized button push tick detection;
                    if (synch_frequency) begin              //First button HIGH detected;
                        debounced_frequency_pulse <= 1'b1;  //If first button push tick is detected, output gets HIGH for one clock period;
                        frequency_ready <= 1'b0;            //System enters to waiting mode; 
                        frequency_zero_counter <= 4'b0; 
                    end
                end
                else begin                                          //Waiting mode logic;
                    if (synch_frequency) begin
                        frequency_zero_counter <= 4'b0;             //Ignores button noise if synch_frequency is HIGH;
                    end
                    else begin                                      //Counter logic to wait for 11 cycles without noise;
                        if (frequency_zero_counter >= 4'd10) begin  //Waits for 110ns without HIGH noise before next sampling is enabled;
                            frequency_ready <= 1'b1;                //Ready to sample new button push;
                            frequency_zero_counter <= 4'd0;         //Button noise counter refresh;
                        end
                        else frequency_zero_counter <= frequency_zero_counter + 4'd1; //0 to 10 counter;
                    end 
                end 
            end
        end
        
        //Identical block for duty-cycle button debounce logic;
        always@(posedge clk) begin
            if (rst) begin
                duty_ready <= 1'b1;
                duty_zero_counter <= 4'b0;
                debounced_duty_pulse <= 1'b0;
            end
            else begin
                debounced_duty_pulse <= 1'b0; 
                if (duty_ready) begin
                    if (synch_duty) begin
                        debounced_duty_pulse <= 1'b1;
                        duty_ready <= 1'b0;
                        duty_zero_counter <= 4'b0; 
                    end
                end
                else begin
                    if (synch_duty) begin
                        duty_zero_counter <= 4'b0;
                    end
                    else begin
                        if (duty_zero_counter >= 4'd10) begin  
                            duty_ready <= 1'b1;                
                            duty_zero_counter <= 4'd0;
                        end
                        else duty_zero_counter <= duty_zero_counter + 4'd1;
                    end 
                end 
            end
        end  
              
endmodule
