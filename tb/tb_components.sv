/*
This file contains components used to construct a constrained random test bench using uvm.

This testbench:
	drives a sequence of random inputs onto the DUT, 
	
	checks the outputs of the DUT to determine correctness, 
		
	collects functional coverage to ensure tb is testing specific corner cases. 

Components in this file: 
	Item: uvm_sequence_item that is randomized and eventualy driven onto the DUT
	
	gen_item_seq: uvm_sequence that generates a sequence of randomized items and sends them to driver
	
	driver: uvm_driver that drives Items recieved from gen_item_seq onto the DUT through an interface
	
	monitor: uvm_monitor that monitors the DUT, stores sets of input and outputs inside Items, 
		and send those Items to the scoreboard

	coverage: class that holds the functional coverage for the testbench 
	
	scoreboard: a uvm_scoreboard that compares Items from the monitor to a reference DUT, in order to determine DUT correctnes
	
	funct_cov_sub: uvm_subscriber that collects functional coverage using Items sent over monitors analysis port
	
	agent: uvm_agent for the tb
	
	env: uvm_env for the tb

The testbench test components are stored in the tb_tests.sv file
*/

package tb_components;

	import tb_config::*;
	import uvm_pkg::*;
	import ref_fifo::*;
	`include "uvm_macros.svh"

	class Item extends uvm_sequence_item;
	//This class holds the Item component that is passed between components
		`uvm_object_utils(Item)

		//randomized input
		rand logic wr;
		rand logic [WIDTH-1:0]  wr_data;
		rand logic rd; 
	
		//output
		logic [WIDTH-1:0] rd_data;
		logic [ADDR_WIDTH:0] item_count;
		logic empty;
		logic full;
		logic underflow;
		logic overflow;

		virtual function string convert2str();
		//this function retruns values of each Item component in
		//string to be printed
			return $sformatf("wr=%0d, wr_data=%0d, rd=%0d, rd_data=%0d, item_count=%0d, empty=%0d,full=%0d, underflow=%0d, overflow=%0d",
					wr,wr_data,rd,rd_data,item_count,empty,full,underflow,overflow);
		endfunction

		function new(string name = "Item");
			super.new(name);
		endfunction

	endclass

	class gen_item_seq extends uvm_sequence;
	//The testbenches sequence generates a sequence of randomized items
	//and sends them to the driver	
		`uvm_object_utils(gen_item_seq)

		function new(string name = "gen_item_seq");
			super.new(name);
		endfunction

		//num is randomized in the test component
		rand int num;	//number of items to be generated

		//soft contrainet can be overidden to change sequence size
		constraint c1 { soft num inside {[10:50]}; }

		virtual task body();
		//create and randomize each item in sequence, 
		//then send to driver
			for(int i=0;i<num;i++) begin
				Item m_item = Item::type_id::create("m_item");
				start_item(m_item);
				m_item.randomize();
				`uvm_info("SEQ",$sformatf("Generate new item: %s",m_item.convert2str()),UVM_HIGH)
				finish_item(m_item);
			end
			`uvm_info("SEQ",$sformatf("Done generating %0d items",num),UVM_HIGH)
		endtask
	
	endclass

	class driver extends uvm_driver #(Item);
	//this class drives the sequence into the DUT, through the interface
		`uvm_component_utils(driver)

		function new(string name = "driver",uvm_component parent=null);
			super.new(name,parent);
		endfunction

		virtual des_if vif;	//interface to DUT

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if(!uvm_config_db#(virtual des_if)::get(this, "","des_vif",vif))
				`uvm_fatal("DRV", "Could not get vif")
		endfunction

		virtual task run_phase(uvm_phase phase);
		//this function loops and gets an item from sequence, then
		//drives that item onto the interface
			super.run_phase(phase);

			forever begin
				Item m_item;
				`uvm_info("DRV",$sformatf("WAIT for item from sequence"),UVM_HIGH)
				seq_item_port.get_next_item(m_item);	//get item 
				drive_item(m_item);			//drive onto interface
				seq_item_port.item_done();			
			end
		endtask

		virtual task drive_item(Item m_item);
		//this task drives input onto the DUT 

			//at interface clocking block
			//drive input onto the interface
			@(vif.cb);	
				vif.cb.wr <= m_item.wr;
				vif.cb.wr_data <= m_item.wr_data;
				vif.cb.rd <= m_item.rd;
		endtask	
	endclass

	class monitor extends uvm_monitor;
	//monitor interface
	//store sets of i/o inside item, 
	//send item to scoreboard
		`uvm_component_utils(monitor)

		function new(string name = "monitor",uvm_component parent=null);
			super.new(name,parent);
		endfunction

		uvm_analysis_port #(Item) mon_analysis_port;	//connect monitor to scoreboard
		virtual des_if vif;

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			if(!uvm_config_db#(virtual des_if)::get(this, "","des_vif",vif))
				`uvm_fatal("MON", "Could not get vif")

			mon_analysis_port = new("mon_analysis_port",this);
		endfunction

		virtual task run_phase(uvm_phase phase);
		//during run phase collect sets of i/o, 
		//store them inside an item,
		//send item to scoreboard
			super.run_phase(phase);
			
			forever begin
				//at interface timing
				@(vif.cb);
					//if design is not being reset
					if(vif.reset_n) begin
						//create and load item with
						//interface i/o
						Item item = Item::type_id::create("item");
						item.wr = vif.wr;
						item.wr_data = vif.wr_data;
						item.rd = vif.rd;
						item.rd_data = vif.cb.rd_data;
						item.item_count = vif.cb.item_count;
						item.full = vif.cb.full;
						item.empty = vif.cb.empty;
						item.underflow = vif.cb.underflow;
						item.overflow = vif.cb.overflow;
						
						//send item to scoreboard
						mon_analysis_port.write(item);
						`uvm_info("MON",$sformatf("Saw item %s",item.convert2str()),UVM_HIGH)
					end
			end
		endtask	
	endclass

	class coverage;
	//this class defines functional coverage for the testbench
	
	//the testbench should cover the following scenarios
		//rd and wr at same time
		//wr to full fifo
		//wr to empty fifo
		//rd from full fifo
		//rd from empty fifo
		//rd and wr at same time to full fifo
		//rd and wr at same time to an empty fifo

		Item m_item;
	
		covergroup cg;
			wr: coverpoint m_item.wr {
				bins en = {1};		//wr is enabled
				bins dis = {0};		//wr is disabled
			}
			rd: coverpoint m_item.rd {
				bins en = {1};		//rd is enabled
				bins dis = {0};		//rd is disabled
			}

			full: coverpoint m_item.full {
				bins t = {1};		//full is true
				bins f = {0};		//full is false
			}
			empty: coverpoint m_item.empty {
				bins t = {1};		//empty is true
				bins f = {0};		//empty is false
			}

			cross_cvg: cross rd,empty,wr,full {
				//rd and wr at same time
				bins rd_during_wr = binsof(wr.en) && binsof(rd.en); 	

				//wr to full and empty fifo
				bins wr_to_full = binsof(wr.en) && binsof(full.t);
				bins wr_to_empty = binsof(wr.en) && binsof(empty.t);

				//rd from empty and full fifo
				bins rd_from_empty = binsof(rd.en) && binsof(empty.t);
				bins rd_from_full = binsof(rd.en) && binsof(full.t);
			
	
				//rd and wr at same time to full and empty fifo
				bins rd_during_wr_to_full = binsof(wr.en) && binsof(rd.en) && binsof(full.t);
				bins rd_during_wr_from_empty = binsof(wr.en) && binsof(rd.en) && binsof(empty.t);
			
				//full and empty should never both be full at
				//same time	
				illegal_bins empty_and_full = binsof(full.t) && binsof(empty.t);
			}			
		endgroup	
		
		function new();
			cg = new();
		endfunction

		function void sample(Item t);
		//subscriber can call this function to sample coverage
			m_item = t;
			cg.sample();
		endfunction
	endclass

	class funct_cov_subscriber extends uvm_subscriber #(Item);
	//this class is a subscriber to the monitors analysis_port
	//it is used to collect coverage, using items that appear on the port
	
		`uvm_component_utils(funct_cov_subscriber)

		typedef uvm_subscriber #(Item) this_type;

		uvm_analysis_imp #(Item, this_type) analysis_export;	//will get connected to monitor analysis port

		coverage funct_cov;

		function new(string name, uvm_component parent);
			super.new(name,parent);
			analysis_export = new("analysis_export",this);
			funct_cov = new();
		endfunction

		function void write(Item t);
		//when write is called sample coverage, using item on
		//analysis_port
			funct_cov.sample(t);
		endfunction
	endclass

	class scoreboard extends uvm_scoreboard;
	//this is the testbenches scoreboard
	//it compares items recieved from monitor
	//to a reference DUT to determine correctness of DUT
		`uvm_component_utils(scoreboard)

		function new(string name = "scoreboard",uvm_component parent=null);
			super.new(name,parent);
		endfunction

		//////vals/////

		ref_fifo #(LENGTH) exp_fifo;	//reference fifo

		uvm_analysis_imp #(Item,scoreboard) m_analysis_imp;
	
		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			m_analysis_imp = new("m_analysis_imp",this);

			exp_fifo = new();
		endfunction

		virtual function void write(Item item);
		//this function compares the item sent from monitor to 
		//the reference fifo
		//It also uses the item to update the reference fifo

			`uvm_info("SCB",$sformatf("%s",item.convert2str()),UVM_LOW);	//display item values
		
			//check that item output matches, reference fifo output
			//If it does not match, output an error and
			//terminate the sim, using uvm_fatal	
			if(item.underflow != exp_fifo.underflow)
				`uvm_fatal("SCB",$sformatf("Error! exp_underflow=%0d, underflow=%0d",exp_fifo.underflow,item.underflow));

			if(item.overflow != exp_fifo.overflow)
				`uvm_fatal("SCB",$sformatf("Error! exp_overflow=%0d, overflow=%0d",exp_fifo.overflow,item.overflow));
		
			if(item.rd_data != exp_fifo.rd_data) 
				`uvm_fatal("SCB",$sformatf("Error! exp_rd_data=%0d, rd_data=%0d",exp_fifo.rd_data,item.rd_data));

			if(item.underflow != exp_fifo.underflow) 
				`uvm_fatal("SCB",$sformatf("Error! exp_underflow=%0d, underflow=%0d",exp_fifo.underflow,item.underflow));			
			if(item.overflow != exp_fifo.overflow) 
				`uvm_fatal("SCB",$sformatf("Error! exp_overflow=%0d, overflow=%0d",exp_fifo.overflow,item.overflow));	

			if(item.item_count != exp_fifo.item_count) 
				`uvm_fatal("SCB",$sformatf("Error! exp_item_count=%0d, item_count=%0d",exp_fifo.item_count,item.item_count));	

			if(item.full != exp_fifo.full)
				`uvm_fatal("SCB",$sformatf("Error! exp_full=%0d, full=%0d",exp_fifo.full,item.full));		

			if(item.empty != exp_fifo.empty) 
				`uvm_fatal("SCB",$sformatf("Error! exp_empty=%0d, empty=%0d",exp_fifo.empty,item.empty));			

			//if item output matched ref_fifo output, then the
			//design passed	
			`uvm_info("SCB",$sformatf("PASS!"),UVM_LOW);

			exp_fifo.update(item.wr,item.rd,item.wr_data);	//update the reference fifo
		
		endfunction
	endclass

	class agent extends uvm_agent;
	//this class is the testbenches agent
		`uvm_component_utils(agent)

		function new(string name = "agent",uvm_component parent=null);
			super.new(name,parent);
		endfunction

		driver	d0;
		monitor	m0;
		uvm_sequencer #(Item) s0;

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);

			s0 = uvm_sequencer#(Item)::type_id::create("s0",this);
			d0 = driver::type_id::create("d0",this);
			m0 = monitor::type_id::create("m0",this);
		endfunction

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			d0.seq_item_port.connect(s0.seq_item_export);	//connect driver to sequencer
		endfunction	
	endclass

	class env extends uvm_env;
	//this class holds the testbenches environment
		`uvm_component_utils(env)

		function new(string name = "env",uvm_component parent=null);
			super.new(name,parent);
		endfunction

		agent	a0;
		scoreboard sb0;
		funct_cov_subscriber fc0;

		virtual function void build_phase(uvm_phase phase);
			super.build_phase(phase);
			a0 = agent::type_id::create("a0",this);
			sb0 = scoreboard::type_id::create("sb0",this);
			fc0 = funct_cov_subscriber::type_id::create("fc0",this);
		endfunction

		virtual function void connect_phase(uvm_phase phase);
			super.connect_phase(phase);
			a0.m0.mon_analysis_port.connect(sb0.m_analysis_imp);	//connect monitor and scoreboard
			a0.m0.mon_analysis_port.connect(fc0.analysis_export);	//connect monitor and functional cov subscriber
		endfunction	
	endclass

endpackage
