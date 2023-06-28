/*
This file contains systemverilog code for a fifo, built using a circular buffer.

Reset:
	reset_n: active low async reset
	When reset, the fifo will be emptied and fifo status will indicate an empty fifo, i.e.
		item_count:0
		empty:1 
		full:0 
		underflow:0
		overflow:0
Control:
	wr: active high wr enable
	rd: active high rd enable
Input:
	wr_data: if wr is enabled, data is written into fifo

Output:
	rd_data: if rd is enabled, data is read out 
	item_count: the number of items currently stored in the fifo, range:0->LENGTH
	full: 1 if the fifo is full, 0 otherwise
	empty: 1 if the fifo is empty, 0 otherwise
	underflow: goes high for 1 clk cycle after an underflow has happened, 0 otherwise
	overrflow: goes high for 1 clk cycle after an overflow has happened, 0 otherwise

All input and output, except reset_n, to/from the fifo is synchronous to the posedge of clk.

Underflow occurs when we try and read from an empty fifo.

Simultanous reads and writes to a full fifo will not result in an overflow. 

So overflow only occurs when we try and write to a full fifo, and are not reading from it at the same time, i.e.
	input: wr = 1 rd = 0
	output: full = 1
*/

module fifo#(parameter LENGTH = 16, WIDTH = 8,ADDR_WIDTH = $clog2(LENGTH))
(
	input logic clk,
	input logic reset_n,			//active low async reset

	input logic [WIDTH-1:0] wr_data,	//data in
	input logic wr,				//wr enable
	input logic rd,				//rd enable
	
	output logic [WIDTH-1:0] rd_data,	//data out
	output logic [ADDR_WIDTH:0] item_count,	//total items currently in fifo
	output logic full,			
	output logic empty,
	output logic underflow,
	output logic overflow

);	
	
	logic [WIDTH-1:0] buffer [LENGTH-1:0];	//circular buffer to hold data

	//addresses are log2(length) wide, 
	//so that they will wrap around to
	//0 when they reach LENGTH 
	logic [ADDR_WIDTH-1:0] wr_addr,rd_addr;	//rd and wr address used to move around buffer

	//empty and full 	
	assign full = (item_count == LENGTH);
	assign empty = (item_count == 'd0);	

	//write into fifo
	always_ff @(posedge clk,negedge reset_n) begin
		if(!reset_n) begin					//if reseting
			for(int i=0;i<LENGTH;i++) buffer[i] <= 0; 	//reset buffer to 0
			wr_addr <= 'd0;					//reset wr_address to 0
		end 
		else if(wr && (~full || rd)) begin			//if succesful write
		 	wr_addr <= wr_addr + 'd1;			//move to next address
			buffer[wr_addr]  <= wr_data;			//write to buffer
		end
	end

	//rd from fifo
	always_ff @(posedge clk,negedge reset_n) begin	
		if(!reset_n) begin			//if reseting
			rd_addr	<= 'd0;			//start reading from address 0
			rd_data <= 'd0;
		end
		else if(rd && ~empty) begin		//if rd is sucesful
		 	rd_addr <= rd_addr + 'd1;	//inc address
			rd_data <= buffer[rd_addr];	//read from buffer
		end
	end

	//determine if overflow happened	
	always_ff @(posedge clk,negedge reset_n)
		if(!reset_n) 			overflow <= 'd0;	//no overflow when reseting
		else if(full && wr && !rd)	overflow <= 'd1;	//overflow if write failed
		else 				overflow <= 'd0;	//otherwise no overflow

	//determone if underflow happened	
	always_ff @(posedge clk,negedge reset_n)
		if(!reset_n) 		underflow <= 'd0;		//no underflow when reseting
		else if(empty && rd)	underflow <= 'd1;		//underflow if read failed
		else 			underflow <= 'd0;		//otherwise no underflow

	//calculate item_count
	always_ff @(posedge clk, negedge reset_n)
		if(!reset_n) item_count <= 'd0;					//reset item_count to 0
		else begin
			casez({wr,rd,!full,!empty})
				4'b01?1: item_count <= item_count - 'd1;	//if we only rd from non empty, dec count
				4'b101?: item_count <= item_count + 'd1;	//if we only wrote to non full fifo, inc count
				4'b1110: item_count <= item_count + 'd1;	//rd durring wr to empty fifo
											//results in succesful wr and failed rd
				default: item_count <= item_count;		//all other scenarios dont change item_count
			endcase	
		end

endmodule
