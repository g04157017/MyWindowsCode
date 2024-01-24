`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:41:12 01/11/2024 
// Design Name: liupeng
// Module Name:    sdram_test 
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
module sdram_test(
	input             clk_50m,          //ʱ��
    input             rst_n,            //��λ,����Ч
    
    output reg        wr_en,            //SDRAM дʹ��
    output reg [15:0] wr_data,          //SDRAM д�������
    output reg        rd_en,            //SDRAM ��ʹ��
    input      [15:0] rd_data,          //SDRAM ����������
    
    input             sdram_init_done,  //SDRAM ��ʼ����ɱ�־
    output reg        error_flag        //SDRAM ��д���Դ����־
    );

//reg define
reg        init_done_d0;                //�Ĵ�SDRAM��ʼ������ź�
reg        init_done_d1;                //�Ĵ�SDRAM��ʼ������ź�
reg [23:0] wr_cnt;                      //д����������
reg [23:0] rd_cnt;                      //������������
reg        rd_valid;                    //��������Ч��־

//parameter define 
parameter DATA_LENG = 24'd32768;
//*****************************************************
//**                    main code
//***************************************************** 

//ͬ��SDRAM��ʼ������ź�
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin
        init_done_d0 <= 1'b0;
        init_done_d1 <= 1'b0;
    end
    else begin
        init_done_d0 <= sdram_init_done;
        init_done_d1 <= init_done_d0;
    end
end            

//SDRAM��ʼ�����֮��,д������������ʼ����
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        wr_cnt <= 24'd0;  
    else if(init_done_d1 && (wr_cnt <= DATA_LENG))
        wr_cnt <= wr_cnt + 1'b1;
    else
        wr_cnt <= wr_cnt;
end    

//SDRAMд�˿�FIFO��дʹ�ܡ�д����(1~1024)
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) begin      
        wr_en   <= 1'b0;
        wr_data <= 16'd0;
    end
    else if(wr_cnt >= 24'd1 && (wr_cnt <= DATA_LENG)) begin
            wr_en   <= 1'b1;            //дʹ������
            wr_data <= wr_cnt;          //д������1~1024
        end    
    else begin
            wr_en   <= 1'b0;
            wr_data <= 16'd0;
        end                
end        

//д��������ɺ�,��ʼ������    
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        rd_en <= 1'b0;
    else if(wr_cnt > DATA_LENG)          //д�������
        rd_en <= 1'b1;                  //��ʹ������
end

//�Զ���������     
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        rd_cnt <= 24'd0;
    else if(rd_en) begin
        if(rd_cnt < DATA_LENG)
            rd_cnt <= rd_cnt + 1'b1;
        else
            rd_cnt <= 24'd1;
    end
end

//��һ�ζ�ȡ��������Ч,��������������ȡ�����ݲ���Ч
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n) 
        rd_valid <= 1'b0;
    else if(rd_cnt == DATA_LENG)         //�ȴ���һ�ζ���������
        rd_valid <= 1'b1;               //������ȡ��������Ч
    else
        rd_valid <= rd_valid;
end            

//��������Чʱ,����ȡ���ݴ���,������־�ź�
always @(posedge clk_50m or negedge rst_n) begin
    if(!rst_n)
        error_flag <= 1'b0; 
    else if(rd_valid && (rd_data != rd_cnt))
        error_flag <= 1'b1;             //����ȡ�����ݴ���,�������־λ���� 
    else
        error_flag <= error_flag;
end

endmodule
