`timescale 1ns / 1ps

module Datapath_tb();

reg clk;                        //Input clk;
reg rst;                        //Input rst;
reg asynch_frequency;           //Input asynchronious bouncing frequency button;
reg asynch_duty;                //Input asynchronious bouncing duty-cycle button;
wire PWM_signal;                //PWM signal generator output;
integer period, period_high;              //PWM period and duty-cycle variables for pwm_measure task;
integer errors, checks_total;   //Check task counters;

initial clk = 0;
always #5 clk = ~clk;   //Clk toggling;

Datapath DUT(           //Datapath module inicialization;
    .clk(clk),
    .rst(rst),
    .asynch_frequency(asynch_frequency),
    .asynch_duty(asynch_duty),
    .PWM_signal(PWM_signal)
    );

//Reset task;
task reset ();
    begin
        rst = 1;
        asynch_frequency = 0;
        asynch_duty = 0;
        #300;
        rst = 0;
        #300;
    end
endtask

//PWM period and duty-cycle counter task;
task pwm_measure (output integer period_cycles, output integer high_cycles);
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
        if (empty >= 3000) begin    //If signal is low for more than 3000 cycles, PWM output is LOW;
            period_cycles = -1;
            high_cycles   = -1;
        end
        //PHASE 2 - COUNTING CYCLES WHILE SIGNAL IS HIGH;
        else begin
            pwm_count = 0;      //Counter reset;
            while (!(cur == 0 && prev == 1)) begin //Waiting for falling edge;
                @(negedge clk);
                prev = cur;
                cur = PWM_signal;
                pwm_count = pwm_count + 1;  //Cycle counter;
            end
            high_cycles = pwm_count;
            //PHASE 3 - COUNTING CYCLES WHILE SIGNAL IS LOW;
            while (!(cur == 1 && prev == 0)) begin //Waits for rising edge to sample total PWM period;
                @(negedge clk);
                prev = cur;
                cur = PWM_signal;
                pwm_count = pwm_count + 1;  //Cycle counter for total PWM period (HIGH + LOW);
            end
            period_cycles = pwm_count;
        end
    end    
endtask

task check(input string name, input integer got, input integer expected);
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

task automatic press(ref reg btn);
    begin
        btn = 1;
        repeat (30) @(negedge clk);
        btn = 0;
        repeat (30) @(negedge clk);
    end
endtask

initial begin
errors = 0;
checks_total = 0;
reset();
press(asynch_duty);
press(asynch_duty);
press(asynch_duty);
press(asynch_duty);
press(asynch_frequency);
press(asynch_frequency);
press(asynch_frequency);
press(asynch_frequency);
press(asynch_frequency);
press(asynch_frequency);
pwm_measure(period, period_high);
check("Duty 40", period_high, 280);
check("Period 700", period, 700);
$display("Errors: %0d. Checks total: %0d.", errors, checks_total);
$finish;
end

endmodule
