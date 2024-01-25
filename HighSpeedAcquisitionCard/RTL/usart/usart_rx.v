`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:43:28 01/25/2024 
// Design Name: 	liupeng
// Module Name:    usart_rx 
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
module usart_rx(
	input				sys_clk,
	input				sys_rst_n,

	input				usart_rxd,

	output reg [7:0] 	uart_data,
	output reg 		 	uart_done
    );

parameter CLK_RREQ = 50000000;	//设置输入的时钟是50MHZ
parameter UART_BPS = 115200;	//设置的波特率是115200bit/s
localparam BPS_CNT = CLK_RREQ/UART_BPS;		//设置比特率的计数

reg	[7:0]rx_data;
reg [3:0] rx_cnt;
reg [15:0] clk_cnt;

reg rx_flag;
reg	usart_rxd_d0;
reg	usart_rxd_d1;

wire start_flag;

assign	start_flag = ~usart_rxd_d0&usart_rxd_d1;	//抓住下降沿

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		usart_rxd_d0<=1'b0;
		usart_rxd_d1<=1'b0;
	end
	else begin
		usart_rxd_d0	<= usart_rxd;
		usart_rxd_d1	<= usart_rxd_d0;
	end
end

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
	rx_flag<=1'b0;
	else begin
		if(start_flag)
		rx_flag<=1'b1;
		else if((rx_cnt == 9)&&(clk_cnt==BPS_CNT/2))
		rx_flag<=1'b0;
		else
		rx_flag<=rx_flag;
	end
end
	
always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		clk_cnt<=16'd0;
	else if(rx_flag)begin
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
		rx_cnt<=4'd0;
	else if(rx_flag)begin
		if(clk_cnt == BPS_CNT-1'b1) 
			rx_cnt<= rx_cnt+1'b1;
		else
			rx_cnt<=rx_cnt;
	end
	else
		rx_cnt<=4'd0;
end

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)
		rx_data<=8'd0;
	else if(rx_flag)
		if(clk_cnt == BPS_CNT/2)begin
			case(rx_cnt)
				4'd1 :	rx_data[0] <= usart_rxd_d1;
				4'd2 :	rx_data[1] <= usart_rxd_d1;
				4'd3 :	rx_data[2] <= usart_rxd_d1;
				4'd4 :	rx_data[3] <= usart_rxd_d1;
				4'd5 :	rx_data[4] <= usart_rxd_d1;
				4'd6 :	rx_data[5] <= usart_rxd_d1;
				4'd7 :	rx_data[6] <= usart_rxd_d1;
				4'd8 :	rx_data[7] <= usart_rxd_d1;
			default : ;
			endcase
		end
		else
			rx_data<=rx_data;
	else
		rx_data<=8'd0;
	end

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n) begin
		uart_data<=8'd0;
		uart_done<=1'b0;
	end
	else if(rx_cnt ==4'd9) begin
		uart_data<=rx_data;
		uart_done<=1'b1;
	end
	else begin
		uart_data<=8'd0;
		uart_done<=1'b0;
	end
end

endmodule
