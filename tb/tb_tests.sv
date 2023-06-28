/*
This contains the uvm tests for the testbech.

This includes
	base_test:uvm_test that all other tests are derived from

	test_1: a test that runs the constrained random testing testbench
*/

package tb_tests;
	import tb_components::*;
	import tb_config::*;
	import uvm_pkg::*;
	`include "uvm_macros.svh"

	class base_test extends uvm_test;
	//this class is the base test, that alll other tests can be derived from
	
		`uvm_component_utils(base_test)

		function new(string name = "base_test",uvm_component parent = null);
			super.new(name,parent);
		endfunction

		env e0;			//test environment
		gen_item_seq seq;	//test sequence
		virtual des_if vif;	//interface to DUT

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			e0 = env::type_id::create("e0",this);
		
			if(!uvm_config_db#(virtual des_if)::get(this, "","des_vif",vif))
				`uvm_fatal("TEST", "Could not get vif")

			uvm_config_db#(virtual des_if)::set(this,"e0.a0.*","des_vif",vif);
			
			seq = gen_item_seq::type_id::create("seq");
			seq.randomize();				//randomize the number of items generated in sequence
		endfunction	

		virtual task run_phase(uvm_phase phase);
		//at the start of run phase 
		//rest the design, then start the sequence
			phase.raise_objection(this);
			apply_reset();			//reset DUT
			seq.start(e0.a0.s0);		//start sequence
			#(CLK_PERIOD*1.5)		//wait 1 and a half cycles
			phase.drop_objection(this);	//then start testbench
		endtask

		virtual task apply_reset();	
		//this tast applys an active low reset to the DUT
			vif.reset_n <= 0;
			repeat(1) @(posedge vif.clk);	
			vif.reset_n <= 1;
			repeat(1) @(posedge vif.clk);	
		endtask

	endclass

	class test_1 extends base_test;
	//This test holds the main constrained random testing test bench
		`uvm_component_utils(test_1)
	
		function new(string name = "test_1",uvm_component parent = null);
			super.new(name,parent);
		endfunction

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);	
			//randomize num items generated in seqence between
			//these numbers
			seq.randomize() with { num inside {[MIN_NUM_TESTS:MAX_NUM_TESTS]}; };
		endfunction	
	endclass
endpackage
