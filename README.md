# systemverilog-fifo-and-uvm-testbench
This repository contains a fifo, written using systemverilog.

It also contains a testbench, which applies a constrained random sequence to the fifo, checks the correctness of the fifo, and collects functional coverage on the test.

The testbench is constructed using uvm.

The rtl source code for the fifo is stored in the rtl_src directory.

Code for the testbench is stored in the tb directory.

Testbench waveform:
![Screenshot from 2023-06-28 17-01-47](https://github.com/woodrowb96/systemverilog-fifo-and-uvm-testbench/assets/39601174/5d03c2ac-f166-45aa-a45f-7859c42824dc)

UVM Summary:

![Screenshot from 2023-06-28 17-05-26](https://github.com/woodrowb96/systemverilog-fifo-and-uvm-testbench/assets/39601174/6bfd9886-a726-4f36-9f48-faeac40ad174)

Coverage Report:
![Screenshot from 2023-06-28 17-09-50](https://github.com/woodrowb96/systemverilog-fifo-and-uvm-testbench/assets/39601174/6f710173-d3a0-4907-92f8-172507740d29)
