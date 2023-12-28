//****************************************Copyright (c)***********************************//
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_rw_test
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM��д���Զ���ģ��
//----------------------------------------------------------------------------------------
// Created by:          LiuPeng
// Created date:        2023/12/08 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module top(
    input         clk,                      //FPGA�ⲿʱ�ӣ�50M
    input         rst_n,                    //������λ���͵�ƽ��Ч
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
    output [ 1:0] sdram_dqm,                //SDRAM ��������
    //LED
    output        led                       //״ָ̬ʾ��
    );
    
//wire define
wire        clk_50m;                        //SDRAM ��д����ʱ��
wire        clk_100m;                       //SDRAM ������ʱ��
//wire        clk_100m_shift;                 //��λƫ��ʱ��
     
wire        wr_en;                          //SDRAM д�˿�:дʹ��
wire [15:0] wr_data;                        //SDRAM д�˿�:д�������
wire        rd_en;                          //SDRAM ���˿�:��ʹ��
wire [15:0] rd_data;                        //SDRAM ���˿�:����������
wire        sdram_init_done;                //SDRAM ��ʼ������ź�

wire        locked;                         //PLL�����Ч��־
wire        sys_rst_n;                      //ϵͳ��λ�ź�
wire        error_flag;                     //��д���Դ����־

wire			sdram_clock_out;						//ʱ�ӻ������
//*****************************************************
//**                    main code
//***************************************************** 

//��PLL����ȶ�֮��ֹͣϵͳ��λ
assign sys_rst_n = rst_n & locked;

//����PLL, ������ģ������Ҫ��ʱ��
pll_clk u_pll_clk(
    .CLK_IN1           (clk),
    .RESET             (~rst_n),
    
    .CLK_OUT1          (clk_50m),
    .CLK_OUT2          (clk_100m),
    .CLK_OUT3          (clk_100m_shift),
    .LOCKED            (locked)
    );

ODDR2 #(
    .DDR_ALIGNMENT("C0D0"),
    .INIT(1'b1)
) u_oddr2 (
    .Q(sdram_clock_out),
    .C0(clk_100m_shift),
    .C1(~clk_100m_shift),
    .D0(1'b1),
    .D1(1'b0)
);
//SDRAM����ģ�飬��SDRAM���ж�д����
sdram_test u_sdram_test(
    .clk_50m            (clk_50m),
    .rst_n              (sys_rst_n),
    
    .wr_en              (wr_en),
    .wr_data            (wr_data),
    .rd_en              (rd_en),
    .rd_data            (rd_data),   
    
    .sdram_init_done    (sdram_init_done),    
    .error_flag         (error_flag)
    );
//����LED��ָʾSDRAM��д���ԵĽ��
/*
led_disp u_led_disp(
    .clk_50m            (clk_50m),
    .rst_n              (sys_rst_n),
   
    .error_flag         (~sdram_init_done||error_flag),//SDRAM��ʼ��ʧ�ܻ��߶�д������Ϊ��ʵ��ʧ��
    .led                (led)             
    );
*/
//SDRAM ����������ģ��,��װ��FIFO�ӿ�
//SDRAM ��������ַ���: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
	.ref_clk			(clk_100m),			//sdram	�������ο�ʱ��
	.out_clk			(sdram_clock_out),	//�����������λƫ��ʱ��
	.rst_n		   (sys_rst_n),		//ϵͳ��λ
    
    //�û�д�˿�
	.wr_clk 			(clk_50m),		   //д�˿�FIFO: дʱ��
	.wr_en			(wr_en),			   //д�˿�FIFO: дʹ��
	.wr_data		   (wr_data),		   //д�˿�FIFO: д����
	.wr_min_addr	(24'd0),			   //дSDRAM����ʼ��ַ
	.wr_max_addr	(24'd1024),		   //дSDRAM�Ľ�����ַ
	.wr_len			(10'd512),			//дSDRAMʱ������ͻ������
	.wr_load			(~sys_rst_n),		//д�˿ڸ�λ: ��λд��ַ,���дFIFO
   
    //�û����˿�
	.rd_clk 			(clk_50m),			//���˿�FIFO: ��ʱ��
    .rd_en			(rd_en),			   //���˿�FIFO: ��ʹ��
	.rd_data	    	(rd_data),		   //���˿�FIFO: ������
	.rd_min_addr	(24'd0),			   //��SDRAM����ʼ��ַ
	.rd_max_addr	(24'd1024),	    	//��SDRAM�Ľ�����ַ
	.rd_len 			(10'd512),			//��SDRAM�ж�����ʱ��ͻ������
	.rd_load			(~sys_rst_n),		//���˿ڸ�λ: ��λ����ַ,��ն�FIFO
	   
     //�û����ƶ˿�  
	.sdram_read_valid	(1'b1),            //SDRAM ��ʹ��
	.sdram_init_done	(sdram_init_done), //SDRAM ��ʼ����ɱ�־
   
	//SDRAM оƬ�ӿ�
	.sdram_clk			(sdram_clk),        //SDRAM оƬʱ��
	.sdram_cke			(sdram_cke),        //SDRAM ʱ����Ч
	.sdram_cs_n			(sdram_cs_n),       //SDRAM Ƭѡ
	.sdram_ras_n		(sdram_ras_n),      //SDRAM ����Ч
	.sdram_cas_n		(sdram_cas_n),      //SDRAM ����Ч
	.sdram_we_n			(sdram_we_n),       //SDRAM д��Ч
	.sdram_ba			(sdram_ba),         //SDRAM Bank��ַ
	.sdram_addr			(sdram_addr),       //SDRAM ��/�е�ַ
	.sdram_data			(sdram_data),       //SDRAM ����
	.sdram_dqm			(sdram_dqm)         //SDRAM ��������
    );

endmodule 