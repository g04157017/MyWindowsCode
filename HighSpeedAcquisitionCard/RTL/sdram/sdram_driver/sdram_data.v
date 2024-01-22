//****************************************Copyright (c)***********************************//
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡFPGA & STM32���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_data
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM ���ݶ�дģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2018/3/18 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sdram_data(
    input             clk,			    //ϵͳʱ��
    input             rst_n,			//�͵�ƽ��λ�ź�

    input   [15:0]    sdram_data_in,    //д��SDRAM�е�����
    output  [15:0]    sdram_data_out,   //��SDRAM�ж�ȡ������
    input   [ 3:0]    work_state,	    //SDRAM����״̬�Ĵ���
    input   [ 9:0]    cnt_clk, 		    //ʱ�Ӽ���
    
    inout   [15:0]    sdram_data		//SDRAM��������
    );

`include "sdram_para.v"		            //����SDRAM��������ģ��

//reg define
reg        sdram_out_en;		        //SDRAM�����������ʹ��
reg [15:0] sdram_din_r;	                //�Ĵ�д��SDRAM�е�����
reg [15:0] sdram_dout_r;	            //�Ĵ��SDRAM�ж�ȡ������

//*****************************************************
//**                    main code
//***************************************************** 

//SDRAM ˫����������Ϊ����ʱ���ָ���̬
assign sdram_data = sdram_out_en ? sdram_din_r : 16'hzzzz;

//���SDRAM�ж�ȡ������
assign sdram_data_out = sdram_dout_r;

//SDRAM �����������ʹ��
always @ (posedge clk or negedge rst_n) begin 
	if(!rst_n) 
       sdram_out_en <= 1'b0;
   else if((work_state == `W_WRITE) | (work_state == `W_WD)) 
       sdram_out_en <= 1'b1;            //��SDRAM��д����ʱ,���ʹ������
   else 
       sdram_out_en <= 1'b0;
end

//����д�������͵�SDRAM����������
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 
        sdram_din_r <= 16'd0;
	else if((work_state == `W_WRITE) | (work_state == `W_WD))
        sdram_din_r <= sdram_data_in;	//�Ĵ�д��SDRAM�е�����
end

//������ʱ,�Ĵ�SDRAM�������ϵ�����
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 
        sdram_dout_r <= 16'd0;
	else if(work_state == `W_RD) 
        sdram_dout_r <= sdram_data;	    //�Ĵ��SDRAM�ж�ȡ������
end

endmodule 