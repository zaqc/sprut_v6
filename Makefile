CC = iverilog
FLAGS = -Wall -Winfloop -g2005-sv
TARGET = mem_copy
SRC = tb.v data_stream.v hlpr_data_buf.v

$(TARGET) : $(SRC) Makefile
	$(CC) $(FLAGS) -o $(TARGET) $(SRC)
	vvp $(TARGET)
	gtkwave dumpfile_$(TARGET).vcd cfg_$(TARGET).gtkw
	rm -f $(TARGET)

wave:
	gtkwave dumpfile_$(TARGET).vcd cfg_$(TARGET).gtkw
	
edit:
	gedit -s $(SRC) Makefile &
	
clean:
	rm -f $(TARGET)

