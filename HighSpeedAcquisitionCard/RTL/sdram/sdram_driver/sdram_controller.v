//****************************************Copyright (c)***********************************//
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_controller
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM ������
//----------------------------------------------------------------------------------------
// Created by:          LiuPeng
// Created date:        2023/12/08 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sdram_controller(
    input         clk,		        //SDRAM������ʱ�ӣ�100MHz
    input         rst_n,	        //ϵͳ��λ�źţ��͵�ƽ��Ч
    
	//SDRAM ������д�˿�	
    input         sdram_wr_req,		//дSDRAM�����ź�
    output        sdram_wr_ack,		//дSDRAM��Ӧ�ź�
    input  [23:0] sdram_wr_addr,	//SDRAMд�����ĵ�ַ
    input  [ 9:0] sdram_wr_burst,   //дsdramʱ����ͻ������
    input  [15:0] sdram_din,	    //д��SDRAM������
    
	//SDRAM ���������˿�	
    input         sdram_rd_req,		//��SDRAM�����ź�
    output        sdram_rd_ack,		//��SDRAM��Ӧ�ź�
    input  [23:0] sdram_rd_addr,	//SDRAMд�����ĵ�ַ
    input  [ 9:0] sdram_rd_burst,   //��sdramʱ����ͻ������
    output [15:0] sdram_dout,	    //��SDRAM����������
    
    output	      sdram_init_done,  //SDRAM ��ʼ����ɱ�־
                                     
	// FPGA��SDRAMӲ���ӿ�
    output        sdram_cke,		// SDRAM ʱ����Ч�ź�
    output        sdram_cs_n,		// SDRAM Ƭѡ�ź�
    output        sdram_ras_n,		// SDRAM �е�ַѡͨ����
    output        sdram_cas_n,		// SDRAM �е�ַѡͨ����
    output        sdram_we_n,		// SDRAM д����λ
    output [ 1:0] sdram_ba,		    // SDRAM L-Bank��ַ��
    output [12:0] sdram_addr,	    // SDRAM ��ַ����
    inout  [15:0] sdram_data		// SDRAM ��������
    );

//wire define
wire [4:0] init_state;	            // SDRAM��ʼ��״̬
wire [3:0] work_state;	            // SDRAM����״̬
wire [9:0] cnt_clk;		            // ��ʱ������
wire       sdram_rd_wr;			    // SDRAM��/д�����ź�,�͵�ƽΪд���ߵ�ƽΪ��

//*****************************************************
//**                    main code
//*****************************************************     

// SDRAM ״̬����ģ��                
sdram_ctrl u_sdram_ctrl(		    
    .clk                (clk),						
    .rst_n              (rst_n),

    .sdram_wr_req       (sdram_wr_req), 
    .sdram_rd_req       (sdram_rd_req),
    .sdram_wr_ack       (sdram_wr_ack),
    .sdram_rd_ack       (sdram_rd_ack),						
    .sdram_wr_burst     (sdram_wr_burst),
    .sdram_rd_burst     (sdram_rd_burst),
    .sdram_init_done    (sdram_init_done),
    
    .init_state         (init_state),
    .work_state         (work_state),
    .cnt_clk            (cnt_clk),
    .sdram_rd_wr        (sdram_rd_wr)
    );

// SDRAM �������ģ��
sdram_cmd u_sdram_cmd(		        
    .clk                (clk),
    .rst_n              (rst_n),

    .sys_wraddr         (sdram_wr_addr),			
    .sys_rdaddr         (sdram_rd_addr),
    .sdram_wr_burst     (sdram_wr_burst),
    .sdram_rd_burst     (sdram_rd_burst),
    
    .init_state         (init_state),	
    .work_state         (work_state),
    .cnt_clk            (cnt_clk),
    .sdram_rd_wr        (sdram_rd_wr),
    
    .sdram_cke          (sdram_cke),		
    .sdram_cs_n         (sdram_cs_n),	
    .sdram_ras_n        (sdram_ras_n),	
    .sdram_cas_n        (sdram_cas_n),	
    .sdram_we_n         (sdram_we_n),	
    .sdram_ba           (sdram_ba),			
    .sdram_addr         (sdram_addr)
    );

// SDRAM ���ݶ�дģ��
sdram_data u_sdram_data(		
    .clk                (clk),
    .rst_n              (rst_n),
    
    .sdram_data_in      (sdram_din),
    .sdram_data_out     (sdram_dout),
    .work_state         (work_state),
    .cnt_clk            (cnt_clk),
    
    .sdram_data         (sdram_data)
    );

endmodule 