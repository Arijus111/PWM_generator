`timescale 1ns / 1ps

module Datapath_tb();

reg clk;                                                //Input clk;
reg rst;                                                //Input rst;
reg asynch_frequency;                                   //Input asynchronious bouncing frequency button;
reg asynch_duty;                                        //Input asynchronious bouncing duty-cycle button;
wire PWM_signal;                                        //PWM signal generator output;
integer period, period_high;                            //PWM period and duty-cycle variables for pwm_measure task;
integer errors, checks_total;                           //Check task counters;
integer expected_frequency_index, expected_duty_index;  //Expected values for frequency and duty-cycle index counter;
integer high_window;                                    //Count_high task result;

initial clk = 0;
always #5 clk = ~clk;                                                           //Clk toggle;

Datapath DUT(                                                                   //Datapath module inicialization;
    .clk(clk),
    .rst(rst),
    .asynch_frequency(asynch_frequency),
    .asynch_duty(asynch_duty),
    .PWM_signal(PWM_signal)
    );

function integer exp_T();                                                       //Returns expected PWM period value from frequency_index;
    begin
        exp_T = 100 * (expected_frequency_index + 1);
    end
endfunction

function integer exp_high();                                                    //Returns expected HIGH value from duty_index;
    begin
        exp_high = (exp_T() / 10) * expected_duty_index;
    end
endfunction

task reset ();                                                                  //Reset task;
    begin
        rst = 1;
        asynch_frequency = 0;
        asynch_duty = 0;
        expected_frequency_index = 0;
        expected_duty_index = 0;
        #300;
        rst = 0;
        #300;
    end
endtask

task pwm_measure (output integer period_cycles, output integer high_cycles);    //PWM period and duty-cycle counter task;
    integer cur, prev, empty, pwm_count;
    begin
        @(negedge clk);
        cur = PWM_signal;
        prev  = cur;
        empty = 0;
        pwm_count = 0;
        //PHASE 1 - WAITING FOR RISING EDGE;
        while (!(cur == 1 && prev == 0) && empty < 3000) begin
            @(negedge clk);
            prev = cur;
            cur = PWM_signal;
            empty = empty + 1;
        end
        if (empty >= 3000) begin                                                //If signal is LOW/HIGH for more than 3000 cycles, duty cycle is 0% or 100%;
            period_cycles = -1;
            high_cycles   = -1;
        end
        //PHASE 2 - COUNTING CYCLES WHILE SIGNAL IS HIGH;
        else begin                                                              //Edge detection;
            pwm_count = 0;                                                      //Counter reset;
            while (!(cur == 0 && prev == 1)) begin                              //Waiting for falling edge;
                @(negedge clk);
                prev = cur;
                cur = PWM_signal;
                pwm_count = pwm_count + 1;                                      //Cycle counter;
            end
            high_cycles = pwm_count;
        //PHASE 3 - COUNTING CYCLES WHILE SIGNAL IS LOW;
            while (!(cur == 1 && prev == 0)) begin                              //Waits for rising edge to sample total PWM period;
                @(negedge clk);
                prev = cur;
                cur = PWM_signal;
                pwm_count = pwm_count + 1;                                      //Cycle counter for total PWM period (HIGH + LOW);
            end
            period_cycles = pwm_count;
        end
    end    
endtask

task count_high(input integer cycles, output integer high_count);               //Counts HIGH PWM_signal cycles when duty cycle is 0% or 100%;              
    integer i, cur;
    high_count = 0;
    for (i = 0; i < cycles; i = i + 1) begin
        @(negedge clk);
        cur = PWM_signal;
        if (cur == 1) high_count = high_count + 1;
    end
endtask

task check(input string name, input integer got, input integer expected);       //Compares expected and actual values; Displays the result;
    begin
        checks_total = checks_total + 1;
        if (got !== expected) begin
            errors = errors + 1;
            $display("FAIL: %0s. Expected=%0d ; Got=%0d", name, expected, got);
        end
        else begin
            $display("PASS: %0s. Expected=%0d ; Got=%0d", name, expected, got);
        end
    end
endtask

task automatic press(ref reg btn);                                              //General bouncing button press task; Do not use for initial block;
    begin
        repeat (3) begin
            btn = ~btn;
            #($urandom_range(1,15));
        end
        btn = 1;
        repeat (30) @(negedge clk);
        repeat (3) begin
            btn = ~btn;
            #($urandom_range(1,15));
        end
        btn = 0;
        repeat (30) @(negedge clk);
    end
endtask

task frequency_press();                                                         //Calls "press" task and increases expected_frequency_index counter 0 to 9;
    begin
        press(asynch_frequency);
        if (expected_frequency_index >= 9) expected_frequency_index = 0;
        else expected_frequency_index = expected_frequency_index + 1;
    end
endtask

task duty_press();                                                              //Calls "press" task and increases expected_duty_index counter 0 to 10;
    begin
        press(asynch_duty);
        if (expected_duty_index >= 10) expected_duty_index = 0;
        else expected_duty_index = expected_duty_index + 1;
    end
endtask

initial begin
    errors = 0;
    checks_total = 0;
    reset();
    $display("-----------------------------------------------");
    $display("Duty cycle increment test after reset at 1MHz (100 clock cycles):");
    count_high(exp_T(), high_window);                                               //Count_high task calculates PWM period when duty cycle is 0%;
    check(("High @ duty 0%"), high_window, exp_high());                             //Compares calculated high_window value with exp_high();
    for (integer i=1;i<=9;i=i+1) begin                                              //9 duty-cycle button presses and comparison of expected and true values;
        duty_press();
        repeat (1100) @(negedge clk);
        pwm_measure(period, period_high);                                           //PWM_measure task calculates PWM high_period and total period when duty cycle is between 10% and 90%;
        check($sformatf("High @ duty %0d0%%", i), period_high, exp_high());
    end
    duty_press();
    repeat (1100) @(negedge clk);
    count_high(exp_T(), high_window);                                               //Count_high task calculates PWM period when duty cycle is 100%;
    check(("High @ duty 100%"), high_window, exp_high());
    $display("Return to 0%% Duty cycle after the next button press: ");
    duty_press();                                                                   //Return to 0% duty cycle button press;
    repeat (1100) @(negedge clk);
    count_high(exp_T(), high_window);                                               //Count_high task calculates PWM period when duty cycle is 0%;
    check(("High @ duty 0%"), high_window, exp_high());    
    $display("-----------------------------------------------");
    $display("PWM frequency increment test after reset with 50%% duty cycle:");
    reset();                                                                        //Reset;
    repeat (5) duty_press();                                                        //5 duty cycle button presses to set 50% duty cycle;
    repeat (1100) @(negedge clk);
    pwm_measure(period, period_high);                                               //PWM period measurement at default frequency after reset;
    check($sformatf("Period @ frequency index %0d", expected_frequency_index), period, exp_T());    //Compares calculated PWM period value with expected value;
    for (integer i=1;i<=9;i=i+1) begin                                              //9 frequency button presses with PWM measurement and comparison;
        frequency_press();
        repeat (1100) @(negedge clk);
        pwm_measure(period, period_high);
        check($sformatf("Period @ frequency index %0d", expected_frequency_index), period, exp_T());
    end
    $display("Return to 1MHz (100 clock cycles) after the next button press: ");
    frequency_press();                                                              //Frequency button press to return to 1MHz;
    repeat (1100) @(negedge clk);
    pwm_measure(period, period_high);
    check($sformatf("Period @ frequency index %0d", expected_frequency_index), period, exp_T());
    $display("-----------------------------------------------");
    $display("Errors: %0d. Checks total: %0d.", errors, checks_total);              //Errors and checks_total counter display;
    $finish;
end

endmodule
