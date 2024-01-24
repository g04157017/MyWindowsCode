///////////////////////////////////////////////////////////////////////////////////////////////////
// Module Name: AD7606_drive
// Description: AD7606_SPI模式，驱动模块
//              输入时钟频率：50MHz      SPI_SCLK：12.5MHz
//              设置采样频率约为2Ksps（每采样完成一次停一会儿）_对应50MHz频率下6250个时钟周期
///////////////////////////////////////////////////////////////////////////////////////////////////

module AD7606_drive(
    input            clk     ,  // 模块时钟输入 _ 50MHz
    input            rst_n   ,  // 输入复位（低电平有效）
    input            ad_busy ,  // AD忙信号
    input            ad_dataA,  // AD_DB7，SPI_MISO模式逐位输出通道1-通道4 _ 双Dout线路
    input            ad_dataB,  // AD_DB8，SPI_MISO模式逐位输出通道5-通道8 _ 双Dout线路
    
    output    [2:0]  ad_os   ,  // AD过采样模式选择引脚
    output           ad_rage ,  // AD模拟输入范围选择， 1:+-10V  0:+-5V
    output reg       ad_rst  ,  // AD芯片复位（高电平有效），器件上电后应先复位50ns以上 
    output reg       ad_cvAB ,  // AD_启动AD转换控制信号，(CONVST A + CONVST B)接到一块使用
    output reg       ad_cs_n ,  // AD片选信号（低电平有效）_ SPI CS_N
    output reg       ad_sclk ,  // AD串行时钟线（SPI模式） _ SPI SCLK _ 设置为12.5MHz
    // AD转换数据输出
    output reg       ad_done ,  // AD所有通道转换完输出一次,持续一时钟周期_50MHz
    output reg[15:0] ad_ch1  ,  // AD第1通道输出数据
    output reg[15:0] ad_ch2  ,  // AD第2通道输出数据
    output reg[15:0] ad_ch3  ,  // AD第3通道输出数据
    output reg[15:0] ad_ch4  ,  // AD第4通道输出数据
    output reg[15:0] ad_ch5  ,  // AD第5通道输出数据
    output reg[15:0] ad_ch6  ,  // AD第6通道输出数据
    output reg[15:0] ad_ch7  ,  // AD第7通道输出数据
    output reg[15:0] ad_ch8     // AD第8通道输出数据
    );
 
// reg define    
reg [15:0] init_cnt      ;  // 上电AD复位计数器  
reg [15:0] state         ;  // 状态机
reg [15:0] state_cnt     ;  // 状态机中的等待计数器
reg [ 1:0] cnt_spi_clk   ;  // 分频计数器，0-3循环计数
reg        cnt_spi_clk_en;  // cnt_spi_clk计数器使能信号
reg        spi_start     ;  // SPI接收计数循环开始，创造SCLK

// parameter define 
parameter AD_IDLE  = 16'b0000_0000_0000_0001;  // 初始状态
parameter AD_CVAB  = 16'b0000_0000_0000_0010;  // AD全部通道开始转换状态
parameter AD_BUSY1 = 16'b0000_0000_0000_0100;  // 等待一段时间，待busy信号为高电平状态
parameter AD_BUSY2 = 16'b0000_0000_0000_1000;  // 然后等待busy信号下降沿(为低电平)状态
parameter AD_CSN   = 16'b0000_0000_0001_0000;  // 拉低AD(SPI)_CS_N片选信号
parameter AD_CH1_5 = 16'b0000_0000_0010_0000;  // 读取通道1和通道5的AD转换值
parameter AD_CH2_6 = 16'b0000_0000_0100_0000;  // 读取通道2和通道6的AD转换值
parameter AD_CH3_7 = 16'b0000_0000_1000_0000;  // 读取通道3和通道7的AD转换值
parameter AD_CH4_8 = 16'b0000_0001_0000_0000;  // 读取通道4和通道8的AD转换值 
parameter AD_STOP  = 16'b0000_0010_0000_0000;  // 读取结束 
 
/* ````````````````````````````````````````````````````` */
/* ``````````````````````main code`````````````````````` */
/* ````````````````````````````````````````````````````` */
 
assign ad_os   = 3'b000;  // 不使用AD过采样   
assign ad_rage = 1'b1  ;  // 输入范围：+-10V  
   
// cnt_spi_clk_en：cnt_spi_clk计数器使能信号
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_spi_clk_en <= 1'b0;
    else if(state == AD_STOP)   // 结束状态，拉低使能信号，停止cnt_spi_clk的计数
        cnt_spi_clk_en <= 1'b0;
    else if(spi_start == 1'b1)  // SPI_CS_N拉低,开始SPI数据接收，拉高cnt_spi_clk计数使能信号
        cnt_spi_clk_en <= 1'b1;
end      
// 分频计数器，0-3循环计数
always@(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        cnt_spi_clk <= 2'd0;
    else if(cnt_spi_clk_en == 1'b1)
        cnt_spi_clk <= cnt_spi_clk + 1'b1;
    else if(cnt_spi_clk_en == 1'b0)
        cnt_spi_clk <= 2'd0;    
end    
    
// 上电先复位_拉高AD芯片一段时间  
always@(posedge clk or negedge rst_n)   
begin    
    if(!rst_n) begin
        init_cnt <= 16'd0;
        ad_rst   <= 1'b1 ;  // 上电首先把AD芯片拉高复位
    end    
    else if(init_cnt < 16'hffff) begin
        init_cnt <= init_cnt + 1'b1;    
        ad_rst   <= 1'b1           ;  
    end
    else
        ad_rst   <= 1'b0           ;  // 一段时间后，AD芯片复位结束
end      
 
// AD转换开始 + AD_SPI读取数据状态机  
always@(posedge clk or negedge rst_n) 
begin
    if(!rst_n) begin
        state     <= AD_IDLE;
        ad_cvAB   <= 1'b1   ;
        ad_cs_n   <= 1'b1   ;
        spi_start <= 1'b0   ;
        state_cnt <= 16'd0  ;
        ad_ch1    <= 16'd0  ;
        ad_ch2    <= 16'd0  ;
        ad_ch3    <= 16'd0  ;
        ad_ch4    <= 16'd0  ;
        ad_ch5    <= 16'd0  ;
        ad_ch6    <= 16'd0  ;
        ad_ch7    <= 16'd0  ;
        ad_ch8    <= 16'd0  ;
        ad_done   <= 1'b0   ;
    end
    else case(state)
        AD_IDLE:  begin
            ad_cvAB   <= 1'b1;
            ad_cs_n   <= 1'b1;
            ad_done   <= 1'b0;
            if(state_cnt == 16'd6000) begin  // 采样频率2KHz：为6250个时钟周期(50MHz)采集一次，采集完一次约等6000个时钟周期，再进行下一次采集
                state_cnt <= 16'd0  ;
                state     <= AD_CVAB;    
            end
            else
                state_cnt <= state_cnt + 1'b1;
        end
        AD_CVAB:  begin
            if(state_cnt == 16'd2) begin
                state_cnt <= 16'd0   ;
                state     <= AD_BUSY1;
                ad_cvAB   <= 1'b1    ;  // 间隔一段时间后拉高AD_CONVSTA+CONVSTB
            end
            else begin
                state_cnt <= state_cnt + 1'b1;
                ad_cvAB   <= 1'b0;      // 拉低AD_CONVSTA+CONVSTB，启动采集
            end
        end
        AD_BUSY1: begin 
            if(state_cnt == 16'd5) begin  // 等5个时钟周期，待busy信号为高
                state_cnt <= 16'd0   ;
                state     <= AD_BUSY2;    
            end
            else
                state_cnt <= state_cnt + 1'b1;       
        end 
        AD_BUSY2:  begin  // 等待busy信号为低
            if(ad_busy == 1'b0) 
                state <= AD_CSN; 
        end
        AD_CSN:    begin
            ad_cs_n   <= 1'b0    ;  // 拉低SPI_CS_N片选
            spi_start <= 1'b1    ;  // 启动SPI接收计数循环，创造SCLK
            state     <= AD_CH1_5; 
        end
        AD_CH1_5:  begin  // 双Dout输出
            if(cnt_spi_clk == 2'd1) begin
                ad_ch1    <= {ad_ch1[14:0],ad_dataA};
                ad_ch5    <= {ad_ch5[14:0],ad_dataB};
                state_cnt <= state_cnt + 1'b1;
                if(state_cnt == 16'd15) begin
                    state_cnt <= 16'd0   ;
                    state     <= AD_CH2_6;  
                end
            end    
        end
        AD_CH2_6:  begin  // 双Dout输出
            if(cnt_spi_clk == 2'd1) begin
                ad_ch2    <= {ad_ch2[14:0],ad_dataA};
                ad_ch6    <= {ad_ch6[14:0],ad_dataB};
                state_cnt <= state_cnt + 1'b1;
                if(state_cnt == 16'd15) begin
                    state_cnt <= 16'd0   ;
                    state     <= AD_CH3_7;  
                end
            end    
        end 
        AD_CH3_7:  begin  // 双Dout输出
            if(cnt_spi_clk == 2'd1) begin
                ad_ch3    <= {ad_ch3[14:0],ad_dataA};
                ad_ch7    <= {ad_ch7[14:0],ad_dataB};
                state_cnt <= state_cnt + 1'b1;
                if(state_cnt == 16'd15) begin
                    state_cnt <= 16'd0   ;
                    state     <= AD_CH4_8;  
                end
            end    
        end 
        AD_CH4_8:  begin  // 双Dout输出
            if(cnt_spi_clk == 2'd1) begin
                ad_ch4    <= {ad_ch4[14:0],ad_dataA};
                ad_ch8    <= {ad_ch8[14:0],ad_dataB};
                state_cnt <= state_cnt + 1'b1;
                if(state_cnt == 16'd15) begin
                    state_cnt <= 16'd0  ;
                    state     <= AD_STOP;  
                end
            end    
        end 
        AD_STOP:   begin
            ad_cs_n   <= 1'b1;
            ad_done   <= 1'b1;
            state     <= AD_IDLE;   
        end 
        default: begin
           state      <= AD_IDLE;
        end               
    endcase        
end    
    
// SPI_SCLK：ad_sclk信号
always@(*)
begin
    case(state)
        AD_IDLE,AD_CVAB,AD_BUSY1,AD_BUSY2,AD_STOP:   // SPI读取数据之前和之后，SCLK一直保持高电平
            ad_sclk <= 1'b1;
        AD_CH1_5,AD_CH2_6,AD_CH3_7,AD_CH4_8 : begin  // SPI读取CH1-CH8时，SCLK的变化
            if(cnt_spi_clk == 2'd0 || cnt_spi_clk == 2'd1)  // cnt_iic_clk等于0、1时：SPI_SCLK为低电平
                ad_sclk <= 1'b0;
            else                                            // cnt_iic_clk等于2、3时：SPI_SCLK为高电平
                ad_sclk <= 1'b1;
        end
        default      :       // 其他情况，SCLK保持高电平
            ad_sclk <= 1'b1;
    endcase    
end 
 
endmodule

