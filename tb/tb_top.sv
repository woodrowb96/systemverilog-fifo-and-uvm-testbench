/*
This file is the top level module for the testbench

This file 
	Defines an interface, to connect DUT to Test
	Connects Test to DUT through interface
	Starts test
*/

import tb_tests::*;
import tb_config::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

interface des_if (input logic clk);
//this is the interface used to connect test to DUT
	//reset
	logic reset_n;

	//input to DUT
	logic [WIDTH-1:0] wr_data;
	logic wr;
	logic rd;

	//output from DUT
	logic [WIDTH-1:0] rd_data;
	logic [ADDR_WIDTH:0] item_count;
	logic full;
	logic empty;
	logic underflow;
	logic overflow;

	clocking cb @(posedge clk);
	//clocking is relative to clk
		default input #0 output #1;
			output wr_data;	//outputs are driven 1 timestep after posedge
			output wr;
			output rd;

			input rd_data; 	//inputs are sampled at posedge
			input item_count; 
			input full; 
			input empty; 
			input underflow; 
			input overflow; 
	endclocking	
endinterface

module tb_top;

	//define clock
	logic clk;
	always #(CLK_PERIOD * 0.5) clk <= ~clk;

	//interface
	des_if _if(clk);	

	//connect DUT to interface
	fifo #(LENGTH,WIDTH,ADDR_WIDTH) dut (
		.clk(clk),
		.reset_n(_if.reset_n),
		.wr_data(_if.wr_data),
		.wr(_if.wr),
		.rd(_if.rd),
		.rd_data(_if.rd_data),
		.item_count(_if.item_count),
		.full(_if.full),
		.empty(_if.empty),
		.underflow(_if.underflow),
		.overflow(_if.overflow)
	);

	initial begin
		clk <= 0;
		uvm_config_db#(virtual des_if)::set(null,"uvm_test_top","des_vif",_if);	//connect interface to test
		run_test("test_1");							//start test
	end
endmodule
