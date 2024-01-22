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
	 input      clk_50m,     //ϵͳʱ��
    input      rst_n,       //ϵͳ��λ
    
    input      error_flag,  //�����־�ź�
    output reg led          //LED��         
    );
//reg define
reg [24:0] led_cnt;         //����LED��˸���ڵļ�����

//*****************************************************
//**                    main code
//***************************************************** 

//��������50MHzʱ�Ӽ�������������Ϊ0.5s
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        led_cnt <= 25'd0;
    else if(led_cnt < 25'd25000000) 
        led_cnt <= led_cnt + 25'd1;
    else
        led_cnt <= 25'd0;
end

//����LED�Ʋ�ͬ����ʾ״ָ̬ʾ�����־�ĸߵ�
always @(posedge clk_50m or negedge rst_n) begin
    if(rst_n == 1'b0)
        led <= 1'b0;
    else if(error_flag) begin
        if(led_cnt == 25'd25000000) 
            led <= ~led;    //�����־Ϊ��ʱ��LED��ÿ��0.5s��˸һ��
        else
            led <= led;
    end    
    else
        led <= 1'b1;        //�����־Ϊ��ʱ��LED�Ƴ���
end


endmodule
