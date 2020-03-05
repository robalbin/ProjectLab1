`timescale 1ns / 1ps
//.............................Top Level Module..................
module top(
    input clock,        //100MHz clock on the Basys board
    input IPS_L, IPS_C, IPS_R,      //left, center, and right IPS
    input SW0, SW14, SW15,     //switches to control duty cycle
    output EN_A, EN_B,      //PWM outouts to driver board
    output reg IN1, reg IN2, reg IN3, reg IN4,      //output to driver board
    output LED0, LED1, LED2, LED3,LED4,LED5,LED6     //LEDs assigned to IPS state
     );
   //top level state machine
   reg [1:0] state_machine;     //2 bit register for 4 possible states 
   reg [2:0] IPStemp;
   reg drive;       //either idle or follow tape 
   //driver
   reg flag;
   reg [18:0] counter;      //counter for PWM signal
   reg [18:0] width;        //width of PWM
   reg [2:0] IPS;       //one register for all three IPS 
   reg speed;     //Choose width using speed register
   reg [1:0] direction;     //4 possible directions
   reg [1:0] turn_sequence;     //stores the sequence of turns needed to avoid an obstacle
   reg turning;     //the rover enters the turning state when it falls off the tape
   reg temp_EN_A;       //temp PWM
   reg temp_EN_B;       //temp PWM
   reg useless;     //actually useless
   reg [1:0] duty;      //duty cycle control
    initial begin       //initialize all registers to zero
        //top level
        state_machine = 0;
        drive = 0;        
        //driver
        counter = 0;
        width = 0;
        flag=0; //set flag to zero
        speed = 0;
        direction = 0;
        turn_sequence = 3;      //turn sequence gets initialized to 3 so that it rolls over to 0 at the first T-intersection
        turning = 0;
        duty = 0;
    end
    always @(posedge clock) begin       //this always block contains all driving related stuff
        case (state_machine)        //pseudo state machine
            2'd0 : begin        //idle state
                drive = 0;  
                if (SW0) state_machine = 2'd1;        //no movement until switch 0 is on
            end 
               
            2'd1 : begin        //driving state where the rover follows the tape
                drive = 1; 
                   
            if (IPS == 3'b010 || IPS == 3'b011 || IPS==3'b110)begin 
            end
            end
            default : begin drive = 0; end         //default state is idle
        endcase
        
        case (drive)        //driving conditions for following the tape
                   1'd0 : begin speed = 2'd0; direction = 2'd0; end        //when driving is low the over will not move
            
                 1'd1 : begin    
                 if (IPS == 3'b000) begin
                    if(IPStemp==3'b011) begin  speed = 2'd1; direction = 2'd2; flag=1; end
                    if(IPStemp==3'b110) begin  speed = 2'd1; direction = 2'd3; flag=1; end 
                    if (IPStemp==3'b010 || IPStemp==3'b100 ||IPStemp==3'b001) begin speed = 2'd1; direction = 2'd1; flag=0; end 
      
                 end        //turn right when no IPS detect tape
                else if (IPS == 3'b001 && flag==0) begin speed = 2'd1; direction = 2'd3;IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1]; IPStemp[2]=IPS[2];end   //rotate right if right IPS detects tape
                else if (IPS == 3'b010) begin speed = 2'd1; direction = 2'd0; flag =0;IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1]; IPStemp[2]=IPS[2]; end   //forward if center IPS detects tape
                else if (IPS == 3'b011 && flag==0) begin speed = 2'd1; direction = 2'd0;IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1]; IPStemp[2]=IPS[2];end   //forward if right and center IPS detect tape
                else if (IPS == 3'b100 && flag==0) begin speed = 2'd1; direction = 2'd2;IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1]; IPStemp[2]=IPS[2];end   //rotate left if left IPS detects tape
                else if (IPS == 3'b101 && flag==0) begin speed = 2'd0; direction = 2'd0;IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1]; IPStemp[2]=IPS[2];end   //stop if right and left IPS detect
                else if (IPS == 3'b110 && flag==0) begin speed = 2'd1; direction = 2'd0;IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1];IPStemp[2]=IPS[2]; end  //forward if left and center IPS detect tape
                else if (IPS == 3'b111 && flag==0) begin speed = 2'd1; direction = 2'd0; IPStemp[0]=IPS[0]; IPStemp[1]=IPS[1]; IPStemp[2]=IPS[2];end  //forward if all IPS detect tape
            end
        endcase ////////////oVoxo
        end
    //..............driver ............................................ 
    always @* begin     //assigning one register for all three IPS
        IPS[0] = ~IPS_R;        //JA3 yellow, JA2 white, JA1 red //nope//nah//no//hellno//stillno//naw//fno//negative//not//not2.0
        IPS[1] = ~IPS_C;
        IPS[2] = ~IPS_L;

        
        duty[0] = SW14;     //assigning switches on the Basys to control the duty cycle register fast/slow
        duty[1] = SW15;
    end
    //............................driver board.......................................
    //PWM signal creation for motors
   always @(posedge clock) begin
        counter <= counter +1;      //continously increment counter
        
        if(counter < width) begin       //output high as long as the count is less than the width
            temp_EN_A <= 1;
            temp_EN_B <= 1;
        end else begin
            temp_EN_A <= 0;
            temp_EN_B <= 0;
        end
    end
    //Direction and speed cases    
    always @(*) begin       //converts direction and speed into output form for the driver board
        case (speed)        //duty cycle from speed
            2'd0 : width = 19'd0;       //0% duty cycle, stop
            2'd1 : begin
                if (duty == 2'b00) width = 19'd199715;  //25% duty cycle 
                else if (duty == 2'b01) width = 19'd314573; //60% duty cycle
                else if (duty == 2'b10) width = 19'd419430; //80% duty cycle
                else if (duty == 2'b11) width = 19'd524287; //100% duty cycle
            end
            default : width = 19'd0;
        endcase
        
        case (direction)       //sets the 4 input pins on the driver board 
            2'd0 : begin IN1 = 1; IN2 = 0; IN3 = 0; IN4 = 1; end        //forward
            2'd1 : begin IN1 = 0; IN2 = 1; IN3 = 1; IN4 = 0; end     //backward
            2'd2 : begin IN1 = 1; IN2 = 0; IN3 = 1; IN4 = 0; end     //rotate left
            2'd3 : begin IN1 = 0; IN2 = 1; IN3 = 0; IN4 = 1; end     //rotate right
            default : begin IN1 = 1; IN2 = 0; IN3 = 0; IN4 = 1; end        //forward
        endcase
    end
    //.........................................................
    //extra assignments
    assign LED0 = ~IPS_R;
    assign LED1 = ~IPS_C;
    assign LED2 = ~IPS_L;
    assign LED3 = ~flag;
    assign LED4 = ~IPStemp[0];
    assign LED5 = ~IPStemp[1];
    assign LED6 = ~IPStemp[2];
    assign EN_A = temp_EN_A;
    assign EN_B = temp_EN_B;

endmodule