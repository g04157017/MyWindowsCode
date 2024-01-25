`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:46:46 01/25/2024 
// Design Name: 
// Module Name:    uart_loop 
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
module uart_loop(
  	input				sys_clk,
	input				sys_rst_n,
	
	input				recv_done,
	input	[7:0]		recv_data,
	
	input				tx_busy,
	
	output	reg			sent_en,
	output	reg	[7:0]	send_data	
	
);

reg recv_done_d0;
reg recv_done_d1;
reg tx_ready;
wire recv_done_flag;

assign	recv_done_flag = recv_done_d0&~recv_done_d1;	//抓取recv_done上升沿信号

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		recv_done_d0<=1'b0;
		recv_done_d1<=1'b0;
	end
	else begin
		recv_done_d0	<= recv_done;
		recv_done_d1	<= recv_done_d0;
	end
end

always	@(posedge sys_clk or negedge sys_rst_n)begin
	if(!sys_rst_n)begin
		sent_en<=1'b0;
		send_data<=8'd0;
		tx_ready<=1'b0;
	end
	else begin
		if(recv_done_flag)begin
			tx_ready<=1'b1;
			sent_en<=1'b0;
			send_data<=recv_data;
		end
		else if((~tx_busy)&&tx_ready)begin
			tx_ready<=1'b0;
			sent_en<=1'b1;
		end
	end
end

endmodule
