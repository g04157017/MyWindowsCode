//****************************************Copyright (c)***********************************//
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡFPGA & STM32���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_fifo_ctrl
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM ��д�˿�FIFO����ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2018/3/18 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sdram_fifo_ctrl(
	input             clk_ref,		     //SDRAM������ʱ��
	input             rst_n,			 //ϵͳ��λ 
                                         
    //�û�д�˿�                         
	input             clk_write,		 //д�˿�FIFO: дʱ�� 
	input             wrf_wrreq,		 //д�˿�FIFO: д���� 
	input      [15:0] wrf_din,		     //д�˿�FIFO: д����	
	input      [23:0] wr_min_addr,	     //дSDRAM����ʼ��ַ
	input      [23:0] wr_max_addr,	     //дSDRAM�Ľ�����ַ
 	input      [ 9:0] wr_length,		 //дSDRAMʱ������ͻ������ 
	input             wr_load,		     //д�˿ڸ�λ: ��λд��ַ,���дFIFO 
                                         
    //�û����˿�                         
	input             clk_read,		     //���˿�FIFO: ��ʱ��
	input             rdf_rdreq,		 //���˿�FIFO: ������ 
	output     [15:0] rdf_dout,		     //���˿�FIFO: ������
	input      [23:0] rd_min_addr,	     //��SDRAM����ʼ��ַ
	input      [23:0] rd_max_addr,	     //��SDRAM�Ľ�����ַ
	input      [ 9:0] rd_length,		 //��SDRAM�ж�����ʱ��ͻ������ 
	input             rd_load,		     //���˿ڸ�λ: ��λ����ַ,��ն�FIFO
	                                     
	//�û����ƶ˿�	                     
	input             sdram_read_valid,  //SDRAM ��ʹ��
	input             sdram_init_done,   //SDRAM ��ʼ����ɱ�־
                                         
    //SDRAM ������д�˿�                 
	output reg		  sdram_wr_req,	     //sdram д����
	input             sdram_wr_ack,	     //sdram д��Ӧ
	output reg [23:0] sdram_wr_addr,	 //sdram д��ַ
	output	   [15:0] sdram_din,		 //д��SDRAM�е����� 
                                         
    //SDRAM ���������˿�                 
	output reg        sdram_rd_req,	     //sdram ������
	input             sdram_rd_ack,	     //sdram ����Ӧ
	output reg [23:0] sdram_rd_addr,	     //sdram ����ַ 
	input      [15:0] sdram_dout 		 //��SDRAM�ж��������� 
    );

//reg define
reg	       wr_ack_r1;                    //sdramд��Ӧ�Ĵ���      
reg	       wr_ack_r2;                    
reg        rd_ack_r1;                    //sdram����Ӧ�Ĵ���      
reg	       rd_ack_r2;                    
reg	       wr_load_r1;                   //д�˿ڸ�λ�Ĵ���      
reg        wr_load_r2;                   
reg	       rd_load_r1;                   //���˿ڸ�λ�Ĵ���      
reg        rd_load_r2;                   
reg        read_valid_r1;                //sdram��ʹ�ܼĴ���      
reg        read_valid_r2;                
                                         
//wire define                            
wire       write_done_flag;              //sdram_wr_ack �½��ر�־λ      
wire       read_done_flag;               //sdram_rd_ack �½��ر�־λ      
wire       wr_load_flag;                 //wr_load      �����ر�־λ      
wire       rd_load_flag;                 //rd_load      �����ر�־λ      
wire [9:0] wrf_use;                      //д�˿�FIFO�е�������
wire [9:0] rdf_use;                      //���˿�FIFO�е�������

//*****************************************************
//**                    main code
//***************************************************** 

//����½���
assign write_done_flag = wr_ack_r2   & ~wr_ack_r1;	
assign read_done_flag  = rd_ack_r2   & ~rd_ack_r1;

//���������
assign wr_load_flag    = ~wr_load_r2 & wr_load_r1;
assign rd_load_flag    = ~rd_load_r2 & rd_load_r1;

//�Ĵ�sdramд��Ӧ�ź�,���ڲ���sdram_wr_ack�½���
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n) begin
		wr_ack_r1 <= 1'b0;
		wr_ack_r2 <= 1'b0;
    end
	else begin
		wr_ack_r1 <= sdram_wr_ack;
		wr_ack_r2 <= wr_ack_r1;		
    end
end	

//�Ĵ�sdram����Ӧ�ź�,���ڲ���sdram_rd_ack�½���
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n) begin
		rd_ack_r1 <= 1'b0;
		rd_ack_r2 <= 1'b0;
    end
	else begin
		rd_ack_r1 <= sdram_rd_ack;
		rd_ack_r2 <= rd_ack_r1;
    end
end	

//ͬ��д�˿ڸ�λ�źţ����ڲ���wr_load������
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n) begin
		wr_load_r1 <= 1'b0;
		wr_load_r2 <= 1'b0;
    end
	else begin
		wr_load_r1 <= wr_load;
		wr_load_r2 <= wr_load_r1;
    end
end

//ͬ�����˿ڸ�λ�źţ�ͬʱ���ڲ���rd_load������
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n) begin
		rd_load_r1 <= 1'b0;
		rd_load_r2 <= 1'b0;
    end
	else begin
		rd_load_r1 <= rd_load;
		rd_load_r2 <= rd_load_r1;
    end
end

//ͬ��sdram��ʹ���ź�
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n) begin
		read_valid_r1 <= 1'b0;
		read_valid_r2 <= 1'b0;
    end
	else begin
		read_valid_r1 <= sdram_read_valid;
		read_valid_r2 <= read_valid_r1;
    end
end

//sdramд��ַ����ģ��
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n)
		sdram_wr_addr <= wr_min_addr;	
    else if(wr_load_flag)                //��⵽д�˿ڸ�λ�ź�ʱ��д��ַ��λ
		sdram_wr_addr <= wr_min_addr;	
	else if(write_done_flag) begin		 //��ͻ��дSDRAM����������д��ַ
                                         //��δ����дSDRAM�Ľ�����ַ����д��ַ�ۼ�
		if(sdram_wr_addr < wr_max_addr - wr_length)
			sdram_wr_addr <= sdram_wr_addr + wr_length;
            else                         //���ѵ���дSDRAM�Ľ�����ַ����ص�д��ʼ��ַ
            sdram_wr_addr <= wr_min_addr;
    end
end

//sdram����ַ����ģ��
always @(posedge clk_ref or negedge rst_n) begin
	if(!rst_n)
		sdram_rd_addr <= rd_min_addr;
	else if(rd_load_flag)				 //��⵽���˿ڸ�λ�ź�ʱ������ַ��λ
		sdram_rd_addr <= rd_min_addr;
	else if(read_done_flag) begin        //ͻ����SDRAM���������Ķ���ַ
                                         //��δ�����SDRAM�Ľ�����ַ�������ַ�ۼ�
		if(sdram_rd_addr < rd_max_addr - rd_length)
			sdram_rd_addr <= sdram_rd_addr + rd_length;
		else                             //���ѵ����SDRAM�Ľ�����ַ����ص�����ʼ��ַ
            sdram_rd_addr <= rd_min_addr;
	end
end

//sdram ��д�����źŲ���ģ��
always@(posedge clk_ref or negedge rst_n) begin
	if(!rst_n) begin
		sdram_wr_req <= 0;
		sdram_rd_req <= 0;
	end
	else if(sdram_init_done) begin       //SDRAM��ʼ����ɺ������Ӧ��д����
                                         //����ִ��д��������ֹд��SDRAM�е����ݶ�ʧ
		if(wrf_use >= wr_length) begin   //��д�˿�FIFO�е��������ﵽ��дͻ������
			sdram_wr_req <= 1;		     //����дsdarm����
			sdram_rd_req <= 0;		     
		end
		else if((rdf_use < rd_length)    //�����˿�FIFO�е�������С�ڶ�ͻ�����ȣ�
                 && read_valid_r2) begin //ͬʱsdram��ʹ���ź�Ϊ��
			sdram_wr_req <= 0;		     
			sdram_rd_req <= 1;		     //������sdarm����
		end
		else begin
			sdram_wr_req <= 0;
			sdram_rd_req <= 0;
		end
	end
	else begin
		sdram_wr_req <= 0;
		sdram_rd_req <= 0;
	end
end

//����д�˿�FIFO
wrfifo	u_wrfifo(
    //�û��ӿ�
	.wr_clk		(clk_write),		     //дʱ��
	.wr_en		(wrf_wrreq),		     //д����
	.din		(wrf_din),			     //д����
    
    //sdram�ӿ�
	.rd_clk		(clk_ref),			     //��ʱ��
	.rd_en		(sdram_wr_ack),		     //������
	.dout			(sdram_din),		     //������

	.rd_data_count	(wrf_use),			     //FIFO�е�������
	.rst		(~rst_n | wr_load_flag),  //�첽�����ź�
	
	.full(_), // output full
   .empty(_) // output empty
);	

//�������˿�FIFO
rdfifo	u_rdfifo(
	//sdram�ӿ�
	.wr_clk		(clk_ref),       	     //дʱ��
	.wr_en		(sdram_rd_ack),  	     //д����
	.din		(sdram_dout),  		     //д����
    
	//�û��ӿ�
	.rd_clk		(clk_read),              //��ʱ��
	.rd_en		(rdf_rdreq),     	     //������
	.dout			(rdf_dout),			     //������

	.wr_data_count	(rdf_use),        	     //FIFO�е�������
	.rst		(~rst_n | rd_load_flag),  //�첽�����ź� 
   .full(_), // output full
   .empty(_) //output empty
);
    
endmodule 