`timescale 1ns / 1ps

module Datapath_tb();

reg clk;                //Input clk;
reg rst;                //Input rst;
reg asynch_frequency;   //Input asynchronious bouncing frequency button;
reg asynch_duty;        //Input asynchronious bouncing duty-cycle button;
wire PWM_signal;        //PWM signal generator output;
integer per, duty;      //PWM period and duty-cycle variables for pwm_measure task;
integer pwm_count = 0;  //PWM cycle counter for pwm_measure task;

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
task pwm_measure (
    output integer period_cycles,
    output integer high_cycles);
    
    integer cur, prev, empty;
    begin
        @(negedge clk);
        cur = PWM_signal;
        prev  = cur;
        empty = 0;
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

initial begin
reset();
pwm_measure(per, duty);
$display("T=%0d HIGH=%0d", per, duty);
$finish;
end

endmodule
