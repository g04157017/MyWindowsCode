`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:55:09 01/25/2024 
// Design Name:    liupeng
// Module Name:    usart_tx 
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
module usart_tx(
	input				sys_clk,
	input				sys_rst_n,
	
	input				usart_en,
	input		[7:0]	usart_din,
	
	output	reg			usart_txd,
	output				usart_tx_busy
	
);
reg [7:0] tx_data;
reg [15:0] clk_cnt;
reg [3:0] tx_cnt;

reg tx_flag;
wire en_flag;

reg usart_en_d0;
reg usart_en_d1;


parameter CLK_RREQ = 50000000;	//设置输入的时钟是50MHZ
parameter UART_BPS = 115200;	//设置的波特率是115200bit/s
localparam BPS_CNT = CLK_RREQ/UART_BPS;		//设置比特率的计数

assign  usart_tx_busy = tx_flag;
assign	en_flag = usart_en_d0&~usart_en_d1;	//抓取usart_en上升沿信号

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		usart_en_d0<=1'b0;
		usart_en_d1<=1'b0;
	end
	else begin
		usart_en_d0	<= usart_en;
		usart_en_d1	<= usart_en_d0;
	end
end

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		tx_flag<=1'b0;
		tx_data<=8'd0;
	end
	else if(en_flag)begin
		tx_flag<=1'b1;
		tx_data<=usart_din;
	end
	else if((tx_cnt == 4'd9)&&clk_cnt==(BPS_CNT-BPS_CNT/16))begin
		tx_flag<=1'b0;
		tx_data<=8'd0;
	end
	else begin
		tx_flag<=tx_flag;
		tx_data<=tx_data;
	end
end
		
always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		clk_cnt<=16'd0;
	else if(tx_flag)begin
		if(clk_cnt < BPS_CNT-1'b1)
		clk_cnt <=clk_cnt+1'b1;
		else
		clk_cnt<=16'd0;
	end
	else
		clk_cnt<=16'd0;
end

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		tx_cnt<=4'd0;
	else if(tx_flag)begin
		if(clk_cnt == BPS_CNT-1'b1) 
			tx_cnt<= tx_cnt+1'b1;
		else
			tx_cnt<=tx_cnt;
	end
	else
		tx_cnt<=4'd0;
end		
		
always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)	
		usart_txd<=1'b1;
	else if(tx_flag)
	case(tx_cnt)
		4'd0 :	usart_txd <= 1'b0;
		4'd1 :	usart_txd <= tx_data[0];
		4'd2 :	usart_txd <= tx_data[1];
		4'd3 :	usart_txd <= tx_data[2];
		4'd4 :	usart_txd <= tx_data[3];
		4'd5 :	usart_txd <= tx_data[4];
		4'd6 :	usart_txd <= tx_data[5];
		4'd7 :	usart_txd <= tx_data[6];
		4'd8 :	usart_txd <= tx_data[7];
		4'd9 :	usart_txd <= 1'b1;
	default : ;
	endcase
	else
		usart_txd<=1'b1;
end

endmodule
