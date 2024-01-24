//----------------------------------------------------------------------------------------
// File name:           sdram_rw_test
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM��д���Զ���ģ��
//----------------------------------------------------------------------------------------
// Created by:          liupeng
// Created date:        2018/3/18 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sdram_rw_test(
    input         clk,                      //FPGA�ⲿʱ�ӣ�50M
    input         rst_n,                   //������λ���͵�ƽ��Ч
	//ADC
	input  [15:0] ad_data_in,
	input 		  ad_busy_in,
	input 		  first_data_in,
	
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
    output        led,                       //״ָ̬ʾ��
	//ADC
	output [2:0] ad_os_out,
	output		 ad_cs_out,
	output		ad_rd_out,
	output		ad_reset_out,
	output		ad_convstab_out
    );
    
////wire define
	 wire        clk_50m;                        //SDRAM ��д����ʱ��
	 wire        clk_100m;                       //SDRAM ������ʱ��
	 wire        clk_100m_shift;                 //��λƫ��ʱ��
	//     
	 wire        wr_en;                          //SDRAM д�˿�:дʹ��
	 wire [15:0] wr_data;                        //SDRAM д�˿�:д�������
	 wire        rd_en;                          //SDRAM ���˿�:��ʹ��
	 wire [15:0] rd_data;                        //SDRAM ���˿�:����������
	 wire        sdram_init_done;                //SDRAM ��ʼ������ź�
	//
	 wire        locked;                         //PLL�����Ч��־
	 wire        sys_rst_n;                      //ϵͳ��λ�ź�
	 wire        error_flag;                     //��д���Դ����־
	//ADC
	 wire [15:0] ad_ch1_out;
	 wire [15:0] ad_ch2_out;
	 wire [15:0] ad_ch3_out;
	 wire [15:0] ad_ch4_out;
	 wire [15:0] ad_ch5_out;
	 wire [15:0] ad_ch6_out;
	 wire [15:0] ad_ch7_out;
	 wire [15:0] ad_ch8_out;
//*****************************************************
//**                    main code
//***************************************************** 

//��PLL����ȶ�֮��ֹͣϵͳ��λ
assign sys_rst_n = rst_n & locked;

//assign testclk = clk; //�����һ�����Է�����

//����PLL, ������ģ������Ҫ��ʱ��
pll_clk u_pll_clk(
    .CLK_IN1             (clk),

    .CLK_OUT1            (clk_50m),
    .CLK_OUT2            (clk_100m),
    .CLK_OUT3            (clk_100m_shift),
	 
    .LOCKED              (locked),
	 .RESET               (~rst_n)
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
led_disp u_led_disp(
    .clk_50m            (clk_50m),
    .rst_n              (sys_rst_n),
   
    .error_flag         (~sdram_init_done||error_flag),//SDRAM��ʼ��ʧ�ܻ��߶�д������Ϊ��ʵ��ʧ��
    .led                (led)             
    );
//parameter define 
parameter DATA_LENG_MAX = 24'd32768;
//SDRAM ����������ģ��,��װ��FIFO�ӿ�
//SDRAM ��������ַ���: {bank_addr[1:0],row_addr[12:0],col_addr[8:0]}
sdram_top u_sdram_top(
	.ref_clk			(clk_100m),			//sdram	�������ο�ʱ��
	.out_clk			(clk_100m_shift),	//�����������λƫ��ʱ��
	.rst_n		   (sys_rst_n),		//ϵͳ��λ
    
    //�û�д�˿�
	.wr_clk 			(clk_50m),		   //д�˿�FIFO: дʱ��
	.wr_en			(wr_en),			   //д�˿�FIFO: дʹ��
	.wr_data		   (wr_data),		   //д�˿�FIFO: д����
	.wr_min_addr	(24'd0),			   //дSDRAM����ʼ��ַ
	.wr_max_addr	(DATA_LENG_MAX),		   //дSDRAM�Ľ�����ַ
	.wr_len			(10'd512),			//дSDRAMʱ������ͻ������
	.wr_load			(~sys_rst_n),		//д�˿ڸ�λ: ��λд��ַ,���дFIFO
   
    //�û����˿�
	.rd_clk 			(clk_50m),			//���˿�FIFO: ��ʱ��
    .rd_en			(rd_en),			   //���˿�FIFO: ��ʹ��
	.rd_data	    	(rd_data),		   //���˿�FIFO: ������
	.rd_min_addr	(24'd0),			   //��SDRAM����ʼ��ַ
	.rd_max_addr	(DATA_LENG_MAX),	    	//��SDRAM�Ľ�����ַ
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
ad7606 u_ad7606(
	.clk				(clk_50m),
	.rst_n				(sys_rst_n),
	.ad_data			(ad_data_in),
	.ad_busy			(ad_busy_in),
	.first_data			(first_data_in),
	.ad_os				(ad_os_out),
	.ad_cs				(ad_cs_out),
	.ad_rd				(ad_rd_out),
	.ad_reset			(ad_reset_out),
	.ad_convstab		(ad_convstab_out),
	.ad_ch1				(ad_ch1_out),
	.ad_ch2				(ad_ch2_out),
	.ad_ch3				(ad_ch3_out),
	.ad_ch4				(ad_ch4_out),
	.ad_ch5				(ad_ch5_out),
	.ad_ch6				(ad_ch6_out),
	.ad_ch7				(ad_ch7_out),
	.ad_ch8				(ad_ch8_out)
);
endmodule 