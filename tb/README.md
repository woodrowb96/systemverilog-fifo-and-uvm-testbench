This directory contains code used to contrusct a constrained random testbench, using UVM.

This testbench is made using the following files
	
	tb_components.sv: Contains all components used to construct uvm testbench, except uvm_test. Also contains code used to collect coverage.
	tb_tests.sv: Contains the uvm_test components.
	tb_config.sv: Configuration for the testbench.
	tb_top.sv: Top level module for the testbench.
	ref_fifo.sv: A reference fifo, used in the testbench`s scoreboard to check the fifos correctness.
