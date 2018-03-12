module UART_rec_48Bytes(clk,
					 rst_n,
//					 rx_status,
					 en_rec,
					 Uart_Data,
					 Rx
					 ); 
					 //flag_recv1
reg [15:0] cnt_baud;//波特率

reg [7:0] rx_tmp_Data;
reg [3:0] num_data;
reg [3:0] num_start;//从开始起，第几个数据
reg rx_start;


input clk,rst_n,en_rec,Rx;//flag_recv1;
reg [383:0] rxData/*sythensis preserve = 1*/;
output reg [383:0]  Uart_Data;

wire data_in,baudSpy;

reg pre;//之前的波形状态
reg now;//现在的波形状态


//=============检测数据及波特率(20Mhz)============================================

//baud		cnt			spycnt
//9600		2083		   1041
//19200     1041			520 
//38400		520			260
//115200		173			86

always @(posedge clk or negedge rst_n) 
	begin	
		if(!rst_n)cnt_baud <= 16'd0;
		else if((cnt_baud == 16'd433) || (!rx_start)) //400M=115200 bps(50Mhz) 传输速度使一位数6943据的周期是1/9600；以20Mhz时钟频率要得到上述的定时需要：cnt_baud =(1/9600bps)/(1/20Mhz)；因为从0开始计数，故而cnt_baud = 2604-1;
			begin
				cnt_baud <= 16'd0;
				
			end
		else if(rx_start)//判断是否有数据来临，如果有，则开始计数；产生采集用计数，否则为0；
			begin
				cnt_baud <= cnt_baud + 1'b1;
			end
		else 
			cnt_baud <= 16'd0;
	end	
	assign	baudSpy = (cnt_baud == 16'd216) ? 1'b1 : 1'b0;//216//监测数据用，为1/2波特率

		  
//============判断下降沿==================================================
always @(posedge clk or negedge rst_n)
	begin
		if(!rst_n) 
			begin
				pre <= 0;
				now <= 0;
			end
		else 
			begin
				now <= Rx;  //采集两次波形的状态，如果pre和now 不同，则表明波形有变化；反之则无，即无数据到来；
				pre <= now;		
			end
	end
	assign	data_in = pre & ~now;//用于检测下降沿

//=================对数据进行处理=====================================
always @(posedge clk or negedge rst_n)
begin
	if(!rst_n) 
		begin 
			num_data 	<= 4'd0;
		   rx_start    <= 0;
			rx_tmp_Data <= 8'd0;
		end 
	
	else
		begin
//			if(flag_recv1 == 1'b1)
//				begin
//					rxData <= 240'd0;
//				end
//			else
//				begin
					if(data_in == 4'd1)//开始计数
						begin
							rx_start <= 1'b1;			
						end	
					
					else if(en_rec )
							begin
								
								if(rx_start)
									begin
										if(baudSpy)
											begin
												num_data <= num_data + 4'd1;
												case(num_data)//将数据取出；
													4'd1:rx_tmp_Data[0] <= Rx;
													4'd2:rx_tmp_Data[1] <= Rx;
													4'd3:rx_tmp_Data[2] <= Rx;
													4'd4:rx_tmp_Data[3] <= Rx;
													4'd5:rx_tmp_Data[4] <= Rx;
													4'd6:rx_tmp_Data[5] <= Rx;
													4'd7:rx_tmp_Data[6] <= Rx;
													4'd8:rx_tmp_Data[7] <= Rx; 
													default : ;
												endcase	
											 if(num_data == 4'd9) //计8+1个数据。
													begin
														num_data <= 4'd0;
														rx_start <= 0;	//127
														
														rxData[7    : 0  ]   <=  rx_tmp_Data;         //0xFD
														rxData[15	: 8  ]   <=  rxData[7	  : 0   ];//0xFC
														rxData[23	: 16 ]   <=  rxData[15	  : 8   ];//
														rxData[31	: 24 ]   <=  rxData[23	  : 16  ];//
														rxData[39	: 32 ]   <=  rxData[31	  : 24  ];///
														rxData[47	: 40 ]   <=  rxData[39	  : 32  ];//
														rxData[55	: 48 ]   <=  rxData[47	  : 40  ];//
				 										rxData[63	: 56 ]   <=  rxData[55	  : 48  ];//
				 										rxData[71	: 64 ]   <=  rxData[63	  : 56  ];//
				 										rxData[79	: 72 ]   <=  rxData[71	  : 64  ];//
				 										rxData[87	: 80 ]   <=  rxData[79	  : 72  ];//
				 										rxData[95	: 88 ]   <=  rxData[87	  : 80  ];//
				 										rxData[103	: 96 ]   <=  rxData[95	  : 88  ];//ORH_clk_sel
				 										rxData[111	: 104 ]   <=  rxData[103  : 96  ];//OLP_SO
				 										rxData[119	: 112 ]   <=  rxData[111  : 104 ];//read_out_H
				 										rxData[127	: 120 ]   <=  rxData[119  : 112 ];//read_out_L
														rxData[135	: 128 ]   <=  rxData[127  : 120 ];//integ_cycles_H
														rxData[143	: 136 ]   <=  rxData[135  : 128 ];//integ_cycles_L	
														rxData[151	: 144 ]   <=  rxData[143  : 136 ];//fram_cycles_H
														rxData[159	: 152 ]   <=  rxData[151  : 144 ];//fram_cycles_L
														rxData[167	: 160 ]   <=  rxData[159  : 152 ];//TEL_SO_H
														rxData[175	: 168 ]   <=  rxData[167  : 160 ];//TEL_SO_L
														rxData[183	: 176 ]   <=  rxData[175  : 168 ];//ORH_TH
														rxData[191	: 184 ]   <=  rxData[183  : 176 ];//ORH_pre
														rxData[199	: 192 ]   <=  rxData[191  : 184 ];//RHV_H
														rxData[207	: 200 ]   <=  rxData[199  : 192 ];//TH_R3
														rxData[215	: 208 ]   <=  rxData[207  : 200 ];//TH_R2
														rxData[223	: 216 ]   <=  rxData[215  : 208 ];//TH_R1
														rxData[231	: 224 ]   <=  rxData[223  : 216 ];//TSH_RO2_H
														rxData[239	: 232 ]   <=  rxData[231  : 224 ];//TSH_RO2_L
														rxData[247  : 240 ]   <=  rxData[239  : 232 ];//TSH_RO1_H
														rxData[255  : 248 ]   <=  rxData[247  : 240 ];//TSH_RO1_L
														rxData[263  : 256 ]   <=  rxData[255  : 248 ];//TFH_RO2_H
														rxData[271  : 264 ]   <=  rxData[263  : 256 ];//TFH_RO2_L          
														rxData[279  : 272 ]   <=  rxData[271  : 264 ];//THF_RO1_H
														rxData[287  : 280 ]   <=  rxData[279  : 272 ];//THF_RO1_L
														rxData[295  : 288 ]   <=  rxData[287  : 280 ];//TL_RO
														rxData[303  : 296 ]   <=  rxData[295  : 288 ];//TH_RO
														rxData[311  : 304 ]   <=  rxData[303  : 296 ];//OLP_IO
														rxData[319  : 312 ]   <=  rxData[311  : 304 ];//TFL_SO_H
														rxData[327  : 320 ]   <=  rxData[319  : 312 ];//TFL_SO_L
														rxData[335  : 328 ]   <=  rxData[327  : 320 ];//TL_Io
														rxData[343  : 336 ]   <=  rxData[335  : 328 ];//TH_IO
														rxData[351  : 344 ]   <=  rxData[343  : 336 ];//THF_IO_H
														rxData[359  : 352 ]   <=  rxData[351  : 344 ];//THF_IO_L
														rxData[367  : 360 ]   <=  rxData[359  : 352 ];//clk_select
														rxData[375  : 368 ]   <=  rxData[367  : 360 ];//FB
														rxData[383  : 376 ]   <=  rxData[375  : 368 ];//FA
													end
											end
										end
								end	
							
							
					
					
//				end
		end
end
always@(posedge clk or negedge rst_n)
	begin
		if(rst_n == 0)
			begin
								//FA FB sys 
				Uart_Data <= 0;//{16'hFAFB,8'd0,8'd30,8'd0,8'd10,16h'FCFD};
			end
		else
			begin
				if(rxData[383  : 376 ] == 8'hFA && rxData[7:0] == 8'hFD)
					begin
						Uart_Data <= rxData;
					end
				else
					begin
						Uart_Data <= Uart_Data;
					end
			end
	end
//assign rx_status = rx_start ;


endmodule
