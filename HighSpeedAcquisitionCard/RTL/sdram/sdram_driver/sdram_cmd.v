//****************************************Copyright (c)***********************************//
//All rights reserved                               
//----------------------------------------------------------------------------------------
// File name:           sdram_cmd
// Last modified Date:  2018/3/18 8:41:06
// Last Version:        V1.0
// Descriptions:        SDRAM �������ģ��
//----------------------------------------------------------------------------------------
// Created by:          LiuPeng
// Created date:        2023/12/08 8:41:06
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module sdram_cmd(
    input             clk,			    //ϵͳʱ��
    input             rst_n,			//�͵�ƽ��λ�ź�

    input      [23:0] sys_wraddr,		//дSDRAMʱ��ַ
    input      [23:0] sys_rdaddr,		//��SDRAMʱ��ַ
    input      [ 9:0] sdram_wr_burst,	//ͻ��дSDRAM�ֽ���
    input      [ 9:0] sdram_rd_burst,	//ͻ����SDRAM�ֽ���
    
    input      [ 4:0] init_state,		//SDRAM��ʼ��״̬
    input      [ 3:0] work_state, 		//SDRAM����״̬
    input      [ 9:0] cnt_clk,		    //��ʱ������	
    input             sdram_rd_wr,	    //SDRAM��/д�����źţ��͵�ƽΪд
    
    output            sdram_cke,		//SDRAMʱ����Ч�ź�
    output            sdram_cs_n,		//SDRAMƬѡ�ź�
    output            sdram_ras_n,	    //SDRAM�е�ַѡͨ����
    output            sdram_cas_n,	    //SDRAM�е�ַѡͨ����
    output            sdram_we_n,		//SDRAMд����λ
    output reg [ 1:0] sdram_ba,		    //SDRAM��L-Bank��ַ��
    output reg [12:0] sdram_addr	    //SDRAM��ַ����
    );

`include "parameter.v"		            //����SDRAM��������ģ��

//reg define
reg  [ 4:0] sdram_cmd_r;	            //SDRAM����ָ��

//wire define
wire [23:0] sys_addr;		            //SDRAM��д��ַ	

//*****************************************************
//**                    main code
//***************************************************** 

//SDRAM �����ź��߸�ֵ
assign {sdram_cke,sdram_cs_n,sdram_ras_n,sdram_cas_n,sdram_we_n} = sdram_cmd_r;

//SDRAM ��/д��ַ���߿���
assign sys_addr = sdram_rd_wr ? sys_rdaddr : sys_wraddr;
	
//SDRAM ����ָ�����
always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			sdram_cmd_r <= `CMD_INIT;
			sdram_ba    <= 2'b11;
			sdram_addr  <= 13'h1fff;
	end
	else
		case(init_state)
                                        //��ʼ��������,����״̬��ִ���κ�ָ��
            `I_NOP,`I_TRP,`I_TRF,`I_TRSC: begin
                    sdram_cmd_r <= `CMD_NOP;
                    sdram_ba    <= 2'b11;
                    sdram_addr  <= 13'h1fff;	
                end
            `I_PRE: begin               //Ԥ���ָ��
                    sdram_cmd_r <= `CMD_PRGE;
                    sdram_ba    <= 2'b11;
                    sdram_addr  <= 13'h1fff;
                end 
            `I_AR: begin
                                        //�Զ�ˢ��ָ��
                    sdram_cmd_r <= `CMD_A_REF;
                    sdram_ba    <= 2'b11;
                    sdram_addr  <= 13'h1fff;						
                end 			 	
            `I_MRS: begin	            //ģʽ�Ĵ�������ָ��
                    sdram_cmd_r <= `CMD_LMR;
                    sdram_ba    <= 2'b00;
                    sdram_addr  <= {    //���õ�ַ������ģʽ�Ĵ���,�ɸ���ʵ����Ҫ�����޸�
                        3'b000,		    //Ԥ��
                        1'b0,		    //��д��ʽ A9=0��ͻ����&ͻ��д
                        2'b00,		    //Ĭ�ϣ�{A8,A7}=00
                        3'b011,		    //CASǱ�������ã���������Ϊ3��{A6,A5,A4}=011
                        1'b0,		    //ͻ�����䷽ʽ����������Ϊ˳��A3=0
                        3'b111		    //ͻ�����ȣ���������Ϊҳͻ����{A2,A1,A0}=011
					};
                end	
            `I_DONE:                    //SDRAM��ʼ�����
					case(work_state)    //���¹���״̬��ִ���κ�ָ��
                        `W_IDLE,`W_TRCD,`W_CL,`W_TWR,`W_TRP,`W_TRFC: begin
                                sdram_cmd_r <= `CMD_NOP;
                                sdram_ba    <= 2'b11;
                                sdram_addr  <= 13'h1fff;
                            end
                        `W_ACTIVE: begin//����Чָ��
                                sdram_cmd_r <= `CMD_ACTIVE;
                                sdram_ba    <= sys_addr[23:22];
                                sdram_addr  <= sys_addr[21:9];
                            end
                        `W_READ: begin  //������ָ��
                                sdram_cmd_r <= `CMD_READ;
                                sdram_ba    <= sys_addr[23:22];
                                sdram_addr  <= {4'b0000,sys_addr[8:0]};
                            end
                        `W_RD: begin    //ͻ��������ָֹ��
                                if(`end_rdburst) 
                                    sdram_cmd_r <= `CMD_B_STOP;
                                else begin
                                    sdram_cmd_r <= `CMD_NOP;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                            end								
                        `W_WRITE: begin //д����ָ��
                                sdram_cmd_r <= `CMD_WRITE;
                                sdram_ba    <= sys_addr[23:22];
                                sdram_addr  <= {4'b0000,sys_addr[8:0]};
                            end		
                        `W_WD: begin    //ͻ��������ָֹ��
                                if(`end_wrburst) 
                                    sdram_cmd_r <= `CMD_B_STOP;
                                else begin
                                    sdram_cmd_r <= `CMD_NOP;
                                    sdram_ba    <= 2'b11;
                                    sdram_addr  <= 13'h1fff;
                                end
                            end
                        `W_PRE:begin    //Ԥ���ָ��
                                sdram_cmd_r <= `CMD_PRGE;
                                sdram_ba    <= sys_addr[23:22];
                                sdram_addr  <= 13'h0000;
                            end				
                        `W_AR: begin    //�Զ�ˢ��ָ��
                                sdram_cmd_r <= `CMD_A_REF;
                                sdram_ba    <= 2'b11;
                                sdram_addr  <= 13'h1fff;
                            end
                        default: begin
                                sdram_cmd_r <= `CMD_NOP;
                                sdram_ba    <= 2'b11;
                                sdram_addr  <= 13'h1fff;
                            end
					endcase
            default: begin
                    sdram_cmd_r <= `CMD_NOP;
                    sdram_ba    <= 2'b11;
                    sdram_addr  <= 13'h1fff;
                end
		endcase
end

endmodule 