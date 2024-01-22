`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:26:42 01/05/2024 
// Design Name: 
// Module Name:    sdram_top 
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
module sdram_top(
	input         ref_clk,                  //sdram �������ο�ʱ��
	input         out_clk,                  //�����������λƫ��ʱ��
	input         rst_n,                    //ϵͳ��λ
    
    //�û�д�˿�			
	input         wr_clk,                   //д�˿�FIFO: дʱ��
	input         wr_en,                    //д�˿�FIFO: дʹ��
	input  [15:0] wr_data,                  //д�˿�FIFO: д����
	input  [23:0] wr_min_addr,              //дSDRAM����ʼ��ַ
	input  [23:0] wr_max_addr,              //дSDRAM�Ľ�����ַ
	input  [ 9:0] wr_len,                   //дSDRAMʱ������ͻ������
	input         wr_load,                  //д�˿ڸ�λ: ��λд��ַ,���дFIFO
    
    //�û����˿�
	input         rd_clk,                   //���˿�FIFO: ��ʱ��
	input         rd_en,                    //���˿�FIFO: ��ʹ��
	output [15:0] rd_data,                  //���˿�FIFO: ������
	input  [23:0] rd_min_addr,              //��SDRAM����ʼ��ַ
	input  [23:0] rd_max_addr,              //��SDRAM�Ľ�����ַ
	input  [ 9:0] rd_len,                   //��SDRAM�ж�����ʱ��ͻ������
	input         rd_load,                  //���˿ڸ�λ: ��λ����ַ,��ն�FIFO
    
    //�û����ƶ˿�  
	input         sdram_read_valid,         //SDRAM ��ʹ��
	output        sdram_init_done,          //SDRAM ��ʼ����ɱ�־
    
	//SDRAM оƬ�ӿ�
	output        sdram_clk,                //SDRAM оƬʱ��
	output        sdram_cke,                //SDRAM ʱ����Ч
	output        sdram_cs_n,               //SDRAM Ƭѡ
	output        sdram_ras_n,              //SDRAM ����Ч
	output        sdram_cas_n,              //SDRAM ����Ч
	output        sdram_we_n,               //SDRAM д��Ч
	output [ 1:0] sdram_ba,                 //SDRAM Bank��ַ
	output [12:0] sdram_addr,               //SDRAM ��/�е�ַ
	inout  [15:0] sdram_data,               //SDRAM ����
	output [ 1:0] sdram_dqm                 //SDRAM ��������
);
//wire define
	wire        sdram_wr_req;                   //sdram д����
	wire        sdram_wr_ack;                   //sdram д��Ӧ
	wire [23:0]	sdram_wr_addr;                  //sdram д��ַ
	wire [15:0]	sdram_din;                      //д��sdram�е�����

	wire        sdram_rd_req;                   //sdram ������
	wire        sdram_rd_ack;                   //sdram ����Ӧ
	wire [23:0]	sdram_rd_addr;                   //sdram ����ַ
	wire [15:0]	sdram_dout;                     //��sdram�ж���������

//*****************************************************
//**                    main code
//***************************************************** 
//	assign	sdram_clk = out_clk;                //����λƫ��ʱ�������sdramоƬ
	assign	sdram_dqm = 2'b00;  

//����λƫ��ʱ�������sdramоƬ
ClockForwarding u_ClockForwarding(
		.clk_100m_shift  (out_clk),
		.sdram_clk       (sdram_clk)
);

//SDRAM ��д�˿�FIFO����ģ��
sdram_fifo_ctrl u_sdram_fifo_ctrl(
	.clk_ref			(ref_clk),			//SDRAM������ʱ��
	.rst_n				(rst_n),			//ϵͳ��λ

    //�û�д�˿�
	.clk_write 			(wr_clk),    	    //д�˿�FIFO: дʱ��
	.wrf_wrreq			(wr_en),			//д�˿�FIFO: д����
	.wrf_din			(wr_data),		    //д�˿�FIFO: д����	
	.wr_min_addr	    (wr_min_addr),		//дSDRAM����ʼ��ַ
	.wr_max_addr		(wr_max_addr),		//дSDRAM�Ľ�����ַ
	.wr_length			(wr_len),		    //дSDRAMʱ������ͻ������
	.wr_load			(wr_load),			//д�˿ڸ�λ: ��λд��ַ,���дFIFO    
    
    //�û����˿�
	.clk_read			(rd_clk),     	    //���˿�FIFO: ��ʱ��
	.rdf_rdreq			(rd_en),			//���˿�FIFO: ������
	.rdf_dout			(rd_data),		    //���˿�FIFO: ������
	.rd_min_addr		(rd_min_addr),	    //��SDRAM����ʼ��ַ
	.rd_max_addr		(rd_max_addr),		//��SDRAM�Ľ�����ַ
	.rd_length			(rd_len),		    //��SDRAM�ж�����ʱ��ͻ������
	.rd_load			(rd_load),			//���˿ڸ�λ: ��λ����ַ,��ն�FIFO
   
	//�û����ƶ˿�	
	.sdram_read_valid	(sdram_read_valid), //sdram ��ʹ��
	.sdram_init_done	(sdram_init_done),	//sdram ��ʼ����ɱ�־

    //SDRAM ������д�˿�
	.sdram_wr_req		(sdram_wr_req),		//sdram д����
	.sdram_wr_ack		(sdram_wr_ack),	    //sdram д��Ӧ
	.sdram_wr_addr		(sdram_wr_addr),	//sdram д��ַ
	.sdram_din			(sdram_din),		//д��sdram�е�����
    
    //SDRAM ���������˿�
	.sdram_rd_req		(sdram_rd_req),		//sdram ������
	.sdram_rd_ack		(sdram_rd_ack),	    //sdram ����Ӧ
	.sdram_rd_addr		(sdram_rd_addr),    //sdram ����ַ
	.sdram_dout			(sdram_dout)		//��sdram�ж���������
);

////SDRAM������
sdram_controller u_sdram_controller(
	.clk				(ref_clk),			//sdram ������ʱ��
	.rst_n				(rst_n),			//ϵͳ��λ
    
	//SDRAM ������д�˿�	
	.sdram_wr_req		(sdram_wr_req), 	//sdram д����
	.sdram_wr_ack		(sdram_wr_ack), 	//sdram д��Ӧ
	.sdram_wr_addr		(sdram_wr_addr), 	//sdram д��ַ
	.sdram_wr_burst		(wr_len),		    //дsdramʱ����ͻ������
	.sdram_din  		(sdram_din),    	//д��sdram�е�����
    
    //SDRAM ���������˿�
	.sdram_rd_req		(sdram_rd_req), 	//sdram ������
	.sdram_rd_ack		(sdram_rd_ack),		//sdram ����Ӧ
	.sdram_rd_addr		(sdram_rd_addr), 	//sdram ����ַ
	.sdram_rd_burst		(rd_len),		    //��sdramʱ����ͻ������
	.sdram_dout		    (sdram_dout),   	//��sdram�ж���������
    
	.sdram_init_done	(sdram_init_done),	//sdram ��ʼ����ɱ�־

	//SDRAM оƬ�ӿ�
	.sdram_cke			(sdram_cke),		//SDRAM ʱ����Ч
	.sdram_cs_n			(sdram_cs_n),		//SDRAM Ƭѡ
	.sdram_ras_n		(sdram_ras_n),		//SDRAM ����Ч	
	.sdram_cas_n		(sdram_cas_n),		//SDRAM ����Ч
	.sdram_we_n			(sdram_we_n),		//SDRAM д��Ч
	.sdram_ba			(sdram_ba),			//SDRAM Bank��ַ
	.sdram_addr			(sdram_addr),		//SDRAM ��/�е�ַ
	.sdram_data			(sdram_data)		//SDRAM ����	
);

endmodule
