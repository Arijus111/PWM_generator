`timescale 1ns / 1ps

module PWM_main_module(
    input clk,                          //100MHz clk;
    input rst,                          //Reset;
    input debounced_frequency_pulse,    //Frequency step request: 1-cycle pulse, one per button press;
    input debounced_duty_pulse,         //Duty-cycle step request: 1-cycle pulse, one per button press;
    output PWM_signal               //PWM output signal;
    );
    
//FREQUENCY PARAMETERS TABLE;
localparam SYSTEM_CLK     = 100000000;                //General systems 100MHz clock;
localparam PERIOD_1MHZ    = SYSTEM_CLK / 1000000;     //1MHz      -> 100 clock cycles;
localparam PERIOD_500KHZ  = SYSTEM_CLK / 500000;      //500kHz    -> 200 clock cycles;
localparam PERIOD_333KHZ  = SYSTEM_CLK / 333333;      //333.33kHz -> 300 clock cycles;
localparam PERIOD_250KHZ  = SYSTEM_CLK / 250000;      //250kHz    -> 400 clock cycles;
localparam PERIOD_200KHZ  = SYSTEM_CLK / 200000;      //200kHz    -> 500 clock cycles;
localparam PERIOD_166KHZ  = SYSTEM_CLK / 166666;      //166.67kHz -> 600 clock cycles;
localparam PERIOD_142KHZ  = SYSTEM_CLK / 142857;      //142.86kHz -> 700 clock cycles;
localparam PERIOD_125KHZ  = SYSTEM_CLK / 125000;      //125kHz    -> 800 clock cycles;
localparam PERIOD_111KHZ  = SYSTEM_CLK / 111111;      //111.11kHz -> 900 clock cycles;
localparam PERIOD_100KHZ  = SYSTEM_CLK / 100000;      //100kHz    -> 1000 clock cycles;

reg [3:0] frequency_index;  //4-bit register to hold current frequency parameter value; TOTAL STATES - 10;
reg [3:0] duty_index;       //4-bit register to hold current duty-cycle parameter value; TOTAL STATES - 11; 

always@(posedge clk) begin  //Button sensitive frequency and duty-cycle index increment block;
    if (rst) begin
        frequency_index <= 4'd0;    //After reset, frequency is 1MHz;
        duty_index <= 4'd0;         //After reset, duty-cycle is 0%. Output signal is LOW; 
    end
    else begin
        if (debounced_frequency_pulse) begin                        //0-9 frequency index increment when button is pressed;
            if (frequency_index >= 4'd9) frequency_index <= 4'd0;   //Frequency returns to 1MHz after 100kHz;
            else frequency_index <= frequency_index + 4'd1;         //Frequency index increment;  
        end
        if (debounced_duty_pulse) begin                             //0-10 duty-cycle index increment when button is pressed;
            if (duty_index >= 4'd10) duty_index <= 4'd0;            //Duty-cycle returns to 0% after 100%
            else duty_index <= duty_index + 4'd1;                   //Duty-cycle index increment;
        end
    end
end

//Frequency selection multiplexer;
//Duty-cycle calculation algorithm: (T_PWM/10) * duty_index;
reg [9:0] T_PWM;            //PWM period value;
reg [6:0] period_tenth;     //T_PWM/10;

always@(*) begin
    T_PWM = 0;
    period_tenth = 0;
    case (frequency_index) //T_PWM and period_tenth is selected by frequency_index;
        4'd0: begin
            T_PWM = PERIOD_1MHZ;
            period_tenth = PERIOD_1MHZ / 10;
        end
        4'd1: begin
            T_PWM = PERIOD_500KHZ;
            period_tenth = PERIOD_500KHZ / 10;
        end
        4'd2: begin
            T_PWM = PERIOD_333KHZ;
            period_tenth = PERIOD_333KHZ / 10;
        end
        4'd3: begin
            T_PWM = PERIOD_250KHZ;
            period_tenth = PERIOD_250KHZ / 10;
        end
        4'd4: begin
            T_PWM = PERIOD_200KHZ;
            period_tenth = PERIOD_200KHZ / 10;
        end
        4'd5: begin
            T_PWM = PERIOD_166KHZ;
            period_tenth = PERIOD_166KHZ / 10;
        end
        4'd6: begin
            T_PWM = PERIOD_142KHZ;
            period_tenth = PERIOD_142KHZ / 10;
        end
        4'd7: begin
            T_PWM = PERIOD_125KHZ;
            period_tenth = PERIOD_125KHZ / 10;
        end
        4'd8: begin
            T_PWM = PERIOD_111KHZ;
            period_tenth = PERIOD_111KHZ / 10;
        end
        4'd9: begin
            T_PWM = PERIOD_100KHZ;
            period_tenth = PERIOD_100KHZ / 10;
        end
        default: begin
            T_PWM = PERIOD_1MHZ;
            period_tenth = PERIOD_1MHZ / 10;            
        end
    endcase
end

wire [9:0] duty_value;
assign duty_value = period_tenth * duty_index;  //Calculates duty-cycle period from period_tenth and duty_index;

//PWM generator block
reg [9:0] PWM_counter;      //PWM cycle counter;
reg [9:0] active_T_PWM;     //Stores active frequency button value to prevent frequency change during PWM pulse;
reg [9:0] active_duty;      //Stores active duty_cycle button value to prevent frequency change during PWM pulse;

always@(posedge clk) begin
    if (rst) begin
        PWM_counter <= 10'd0;
        active_T_PWM <= 10'd0;
        active_duty <= 10'd0;
    end
    else begin
        if (PWM_counter >= active_T_PWM) begin
            PWM_counter <= 10'd0;
            active_T_PWM <= T_PWM;
            active_duty <= duty_value;
        end
        else begin
            PWM_counter <= PWM_counter + 10'd1;
        end
    end
end

assign PWM_signal = (PWM_counter <= active_duty) ? 1 : 0;

endmodule
