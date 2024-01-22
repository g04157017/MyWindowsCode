`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:20:17 01/05/2024 
// Design Name: 
// Module Name:    led_disp 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module led_disp(
	 input      clk_50m,     //系统时钟
    input      rst_n,       //系统复位
    
    input      error_flag,  //错误标志信号
    output reg led          //LED灯         
    );
//reg define
reg [24:0] led_cnt;         //控制LED闪烁周期的计数器

//*****************************************************
//**                    main code
//***************************************************** 

//计数器对50MHz时钟计数，计数周期为0.5s
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        led_cnt <= 25'd0;
    else if(led_cnt < 25'd25000000) 
        led_cnt <= led_cnt + 25'd1;
    else
        led_cnt <= 25'd0;
end

//利用LED灯不同的显示状态指示错误标志的高低
always @(posedge clk_50m or negedge rst_n) begin
    if(rst_n == 1'b0)
        led <= 1'b0;
    else if(error_flag) begin
        if(led_cnt == 25'd25000000) 
            led <= ~led;    //错误标志为高时，LED灯每隔0.5s闪烁一次
        else
            led <= led;
    end    
    else
        led <= 1'b1;        //错误标志为低时，LED灯常亮
end


endmodule
