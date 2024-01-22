//****************************************Copyright (c)***********************************//
//����֧�֣�www.openedv.com
//�Ա����̣�http://openedv.taobao.com 
//��ע΢�Ź���ƽ̨΢�źţ�"����ԭ��"����ѻ�ȡFPGA & STM32���ϡ�
//��Ȩ���У�����ؾ���
//Copyright(C) ����ԭ�� 2018-2028
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_ctrl
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM ״̬����ģ��
//----------------------------------------------------------------------------------------
// Created by:          ����ԭ��
// Created date:        2018/3/18 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sdram_ctrl(
    input            clk,			    //ϵͳʱ��
    input            rst_n,			    //��λ�źţ��͵�ƽ��Ч
    
    input            sdram_wr_req,	    //дSDRAM�����ź�
    input            sdram_rd_req,	    //��SDRAM�����ź�
    output           sdram_wr_ack,	    //дSDRAM��Ӧ�ź�
    output           sdram_rd_ack,	    //��SDRAM��Ӧ�ź�
    input      [9:0] sdram_wr_burst,	//ͻ��дSDRAM�ֽ�����1-512����
    input      [9:0] sdram_rd_burst,	//ͻ����SDRAM�ֽ�����1-256����	
    output           sdram_init_done,   //SDRAMϵͳ��ʼ������ź�

    output reg [4:0] init_state,	    //SDRAM��ʼ��״̬
    output reg [3:0] work_state,	    //SDRAM����״̬
    output reg [9:0] cnt_clk,	        //ʱ�Ӽ�����
    output reg       sdram_rd_wr 		//SDRAM��/д�����źţ��͵�ƽΪд���ߵ�ƽΪ��
    );

`include "sdram_para.v"		            //����SDRAM��������ģ��
                                        
//parameter define                      
parameter  TRP_CLK	  = 10'd4;	        //Ԥ�����Ч����
parameter  TRC_CLK	  = 10'd6;	        //�Զ�ˢ������
parameter  TRSC_CLK	  = 10'd6;	        //ģʽ�Ĵ�������ʱ������
parameter  TRCD_CLK	  = 10'd2;	        //��ѡͨ����
parameter  TCL_CLK	  = 10'd3;	        //��Ǳ����(cl)
parameter  TWR_CLK	  = 10'd2;	        //д��У��
                                        
//reg define                            
reg [14:0] cnt_200us;                   //SDRAM �ϵ��ȶ���200us������
reg [10:0] cnt_refresh;	                //ˢ�¼����Ĵ���
reg        sdram_ref_req;		        //SDRAM �Զ�ˢ�������ź�
reg        cnt_rst_n;		            //��ʱ��������λ�źţ�����Ч	
reg [ 3:0] init_ar_cnt;                 //��ʼ�������Զ�ˢ�¼�����
                                        
//wire define                           
wire       done_200us;		            //�ϵ��200us�����ȶ��ڽ�����־λ
wire       sdram_ref_ack;		        //SDRAM�Զ�ˢ������Ӧ���ź�	

//*****************************************************
//**                    main code
//***************************************************** 

//SDRAM�ϵ��200us�ȶ��ڽ�����,����־�ź�����
assign done_200us = (cnt_200us == 15'd20_000);

//SDRAM��ʼ����ɱ�־ 
assign sdram_init_done = (init_state == `I_DONE);

//SDRAM �Զ�ˢ��Ӧ���ź�
assign sdram_ref_ack = (work_state == `W_AR);

//дSDRAM��Ӧ�ź�
assign sdram_wr_ack = ((work_state == `W_TRCD) & ~sdram_rd_wr) | 
					  ( work_state == `W_WRITE)|
					  ((work_state == `W_WD) & (cnt_clk < sdram_wr_burst - 2'd2));
                      
//��SDRAM��Ӧ�ź�
assign sdram_rd_ack = (work_state == `W_RD) & 
					  (cnt_clk >= 10'd1) & (cnt_clk < sdram_rd_burst + 2'd1);
                      
//�ϵ���ʱ200us,�ȴ�SDRAM״̬�ȶ�
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 
        cnt_200us <= 15'd0;
	else if(cnt_200us < 15'd20_000) 
        cnt_200us <= cnt_200us + 1'b1;
    else
        cnt_200us <= cnt_200us;
end
 
//ˢ�¼�����ѭ������7812ns (60ms�����ȫ��8192��ˢ�²���)
always @ (posedge clk or negedge rst_n)
	if(!rst_n) 
        cnt_refresh <= 11'd0;
	else if(cnt_refresh < 11'd781)      // 64ms/8192 =7812ns
        cnt_refresh <= cnt_refresh + 1'b1;	
	else 
        cnt_refresh <= 11'd0;	

//SDRAM ˢ������
always @ (posedge clk or negedge rst_n)
	if(!rst_n) 
        sdram_ref_req <= 1'b0;
	else if(cnt_refresh == 11'd780) 
        sdram_ref_req <= 1'b1;	        //ˢ�¼�������ʱ��7812nsʱ����ˢ������
	else if(sdram_ref_ack) 
        sdram_ref_req <= 1'b0;		    //�յ�ˢ��������Ӧ�źź�ȡ��ˢ������ 

//��ʱ��������ʱ�Ӽ���
always @ (posedge clk or negedge rst_n) 
	if(!rst_n) 
        cnt_clk <= 10'd0;
	else if(!cnt_rst_n)                 //��cnt_rst_nΪ�͵�ƽʱ��ʱ����������
        cnt_clk <= 10'd0;
	else 
        cnt_clk <= cnt_clk + 1'b1;
        
//��ʼ�������ж��Զ�ˢ�²�������
always @ (posedge clk or negedge rst_n) 
	if(!rst_n) 
        init_ar_cnt <= 4'd0;
	else if(init_state == `I_NOP) 
        init_ar_cnt <= 4'd0;
	else if(init_state == `I_AR)
        init_ar_cnt <= init_ar_cnt + 1'b1;
    else
        init_ar_cnt <= init_ar_cnt;
	
//SDRAM�ĳ�ʼ��״̬��
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 
        init_state <= `I_NOP;
	else 
		case (init_state)
                                        //�ϵ縴λ��200us�����������һ״̬
            `I_NOP:  init_state <= done_200us  ? `I_PRE : `I_NOP;
                                        //Ԥ���״̬
			`I_PRE:  init_state <= `I_TRP;
                                        //Ԥ���ȴ���TRP_CLK��ʱ������
			`I_TRP:  init_state <= (`end_trp)  ? `I_AR  : `I_TRP;
                                        //�Զ�ˢ��
			`I_AR :  init_state <= `I_TRF;	
                                        //�ȴ��Զ�ˢ�½���,TRC_CLK��ʱ������
			`I_TRF:  init_state <= (`end_trfc) ? 
                                        //����8���Զ�ˢ�²���
                                   ((init_ar_cnt == 4'd8) ? `I_MRS : `I_AR) : `I_TRF;
                                        //ģʽ�Ĵ�������
			`I_MRS:	 init_state <= `I_TRSC;	
                                        //�ȴ�ģʽ�Ĵ���������ɣ�TRSC_CLK��ʱ������
			`I_TRSC: init_state <= (`end_trsc) ? `I_DONE : `I_TRSC;
                                        //SDRAM�ĳ�ʼ��������ɱ�־
			`I_DONE: init_state <= `I_DONE;
			default: init_state <= `I_NOP;
		endcase
end

//SDRAM�Ĺ���״̬��,������������д�Լ��Զ�ˢ�²���
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) 
		work_state <= `W_IDLE;          //����״̬
	else
		case(work_state)
                                        //��ʱ�Զ�ˢ��������ת���Զ�ˢ��״̬
            `W_IDLE: if(sdram_ref_req & sdram_init_done) begin
						 work_state <= `W_AR; 		
					     sdram_rd_wr <= 1'b1;
				     end 		        
                                        //дSDRAM������ת������Ч״̬
					 else if(sdram_wr_req & sdram_init_done) begin
						 work_state <= `W_ACTIVE;
						 sdram_rd_wr <= 1'b0;	
					 end                
                                        //��SDRAM������ת������Ч״̬
					 else if(sdram_rd_req && sdram_init_done) begin
						 work_state <= `W_ACTIVE;
						 sdram_rd_wr <= 1'b1;	
					 end                
                                        //�޲������󣬱��ֿ���״̬
					 else begin 
						 work_state <= `W_IDLE;
						 sdram_rd_wr <= 1'b1;
					 end
                     
            `W_ACTIVE:                  //����Ч����ת������Ч�ȴ�״̬
                         work_state <= `W_TRCD;
            `W_TRCD: if(`end_trcd)      //����Ч�ȴ��������жϵ�ǰ�Ƕ�����д
						 if(sdram_rd_wr)//�������������״̬
                             work_state <= `W_READ;
						 else           //д������д����״̬
                             work_state <= `W_WRITE;
					 else 
                         work_state <= `W_TRCD;
                         
            `W_READ:	                //����������ת��Ǳ����
                         work_state <= `W_CL;	
            `W_CL:		                //Ǳ���ڣ��ȴ�Ǳ���ڽ�������ת��������״̬
                         work_state <= (`end_tcl) ? `W_RD:`W_CL;	                                        
            `W_RD:		                //�����ݣ��ȴ������ݽ�������ת��Ԥ���״̬
                         work_state <= (`end_tread) ? `W_PRE:`W_RD;
                         
            `W_WRITE:	                //д��������ת��д����״̬
                         work_state <= `W_WD;
            `W_WD:		                //д���ݣ��ȴ�д���ݽ�������ת��д������״̬
                         work_state <= (`end_twrite) ? `W_TWR:`W_WD;                         
            `W_TWR:	                    //д�����ڣ�д�����ڽ�������ת��Ԥ���״̬
                         work_state <= (`end_twr) ? `W_PRE:`W_TWR;
                         
            `W_PRE:		                //Ԥ��磺��ת��Ԥ���ȴ�״̬
                         work_state <= `W_TRP;
            `W_TRP:	                //Ԥ���ȴ���Ԥ���ȴ��������������״̬
                         work_state <= (`end_trp) ? `W_IDLE:`W_TRP;
                         
            `W_AR:		                //�Զ�ˢ�²�������ת���Զ�ˢ�µȴ�
                         work_state <= `W_TRFC;             
            `W_TRFC:	                //�Զ�ˢ�µȴ����Զ�ˢ�µȴ��������������״̬
                         work_state <= (`end_trfc) ? `W_IDLE:`W_TRFC;
            default: 	 work_state <= `W_IDLE;
		endcase
end

//�����������߼�
always @ (*) begin
	case (init_state)
        `I_NOP:	 cnt_rst_n <= 1'b0;     //��ʱ����������(cnt_rst_n�͵�ƽ��λ)
                                        
        `I_PRE:	 cnt_rst_n <= 1'b1;     //Ԥ��磺��ʱ����������(cnt_rst_n�ߵ�ƽ����)
                                        //�ȴ�Ԥ�����ʱ�������������������
        `I_TRP:	 cnt_rst_n <= (`end_trp) ? 1'b0 : 1'b1;
                                        //�Զ�ˢ�£���ʱ����������
        `I_AR:
                 cnt_rst_n <= 1'b1;
                                        //�ȴ��Զ�ˢ����ʱ�������������������
        `I_TRF:
                 cnt_rst_n <= (`end_trfc) ? 1'b0 : 1'b1;	
                                        
        `I_MRS:  cnt_rst_n <= 1'b1;	    //ģʽ�Ĵ������ã���ʱ����������
                                        //�ȴ�ģʽ�Ĵ���������ʱ�������������������
        `I_TRSC: cnt_rst_n <= (`end_trsc) ? 1'b0:1'b1;
                                        
        `I_DONE: begin                  //��ʼ����ɺ�,�жϹ���״̬
		    case (work_state)
				`W_IDLE:	cnt_rst_n <= 1'b0;
                                        //����Ч����ʱ����������
				`W_ACTIVE: 	cnt_rst_n <= 1'b1;
                                        //����Ч��ʱ�������������������
				`W_TRCD:	cnt_rst_n <= (`end_trcd)   ? 1'b0 : 1'b1;
                                        //Ǳ������ʱ�������������������
				`W_CL:		cnt_rst_n <= (`end_tcl)    ? 1'b0 : 1'b1;
                                        //��������ʱ�������������������
				`W_RD:		cnt_rst_n <= (`end_tread)  ? 1'b0 : 1'b1;
                                        //д������ʱ�������������������
				`W_WD:		cnt_rst_n <= (`end_twrite) ? 1'b0 : 1'b1;
                                        //д��������ʱ�������������������
				`W_TWR:	    cnt_rst_n <= (`end_twr)    ? 1'b0 : 1'b1;
                                        //Ԥ���ȴ���ʱ�������������������
				`W_TRP:	cnt_rst_n <= (`end_trp) ? 1'b0 : 1'b1;
                                        //�Զ�ˢ�µȴ���ʱ�������������������
				`W_TRFC:	cnt_rst_n <= (`end_trfc)   ? 1'b0 : 1'b1;
				default:    cnt_rst_n <= 1'b0;
		    endcase
        end
		default: cnt_rst_n <= 1'b0;
	endcase
end
 
endmodule 