/*
This file contains a reference fifo, that is used to verify the correctnes of the DUT fifo
*/
package ref_fifo;
	class ref_fifo #(parameter LENGTH);
	//This class is used to model an rtl fifo, 
	//that can be used as a reference to 
	//compare the DUT fifo against in the test bench

		int queue [$:LENGTH-1];	//a bounded queue to hold data stored in FIFO
		
		int item_count;		//returns number of valid items currently in queue
		int full;		//returns 1 if full 0 if not full
		int empty;		//returns 1 if empty 0 if not empty
		int underflow;		//returns 1 if input results in an underflow condition, 0 otherwise
		int overflow;		//returns 1 if input results in an overflow condition, 0 otherwise
		
		int rd_data;		//data currently being read out of fifo
	
		function new();
		//create a new fifo and initialize data
		//this function corresponds to reseting the rtl fifo
			full = 0;
			empty = 1;
			underflow = 0;
			overflow = 0;
			item_count = 0;
			rd_data = 0;
		endfunction 	

		function void write(int wr,int rd,int wr_data);
		//this function models a wr to the fifo
		
		//if wr is sucessfull wr_data should be stored in the fifo	
		//if wr was unsucesfull it sets overflow 
		
			if(wr && (full && !rd)) overflow = 1;	//overflow if we are writing to a full fifo, and not reading at same time
			else 			overflow = 0; 	

			if(wr && (!full || rd))			//write into queue if we are not causing an overflow
				queue.push_back(wr_data);
		endfunction

		function void read(int rd);
		//this function models a rd from the fifo

		//if rd is sucesfull data is read out and stored on rd_data	
		//it also sets underflow if an underflow has occured
		
			if(rd && empty) underflow = 1;	//underflow if we read from empty fifo
			else 		underflow = 0;
		
			if(rd && !empty) 		//if there is no underflow update rd data
				rd_data = queue.pop_front();	
		endfunction	
	
		function void update(int wr,int rd,int wr_data);
		//the testbench can use this function to send input to fifo 

		//fifo  state will be updated according to the input
			read(rd); 		//read
			write(wr,rd,wr_data);	//write

			full = queue.size() == LENGTH;	//update full
			empty = queue.size() == 0;	//update empty
			item_count = queue.size();	//update item_count
		endfunction

	endclass
endpackage
