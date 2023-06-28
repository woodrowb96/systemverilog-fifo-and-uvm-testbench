/*
This file holds constants used to cofnigure the testbech
*/
package tb_config;
	//We will test a 8x16 fifo
	parameter WIDTH = 8;
	parameter LENGTH = 16;
	parameter ADDR_WIDTH = $clog2(LENGTH);

	//want a sequence that has 500 items in it
	parameter MIN_NUM_TESTS = 500;
	parameter MAX_NUM_TESTS = 500;

	//clk period of 50 time steps	
	parameter CLK_PERIOD = 50;
endpackage
