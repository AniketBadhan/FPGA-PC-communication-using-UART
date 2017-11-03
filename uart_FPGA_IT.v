`timescale 1ns / 1ps

module uart_FPGA_IT(
	clk,
	reset,
	rx_in,
	tx_out
    );

	//port declarations
	input clk;
	input reset;
	input rx_in;
	output tx_out;

	// Internal Variables
	reg temp_rx_in;
	wire tx_out;
	wire [7:0] rx_data;
	reg [7:0] temp_tx_data;
	wire tx_empty;
	wire rx_empty;
	reg tx_clk = 0;
	reg rx_clk = 0;
	reg tx_enable = 1;
	reg rx_enable = 1;
	reg ld_tx_data = 0;
	reg uld_rx_data = 0;
	reg [10:0] rx_counter = 10'b0000000000;
	reg [10:0] tx_counter = 10'b0000000000;
	reg [2:0] rx_state = 3'b000;
	reg [1:0] tx_state = 2'b00;
	reg [1:0] clk_cnt = 2'b00;
	reg [7:0] red_rx_data;
	reg [7:0] green_rx_data;
	reg [7:0] blue_rx_data;
	wire [7:0] red_tx_data;
	wire [7:0] green_tx_data;
	wire [7:0] blue_tx_data;
	reg [1:0] rx_data_cnt = 2'b00;
	reg [1:0] tx_data_cnt = 2'b00;
	wire conversion_done;
	reg start_conversion;

	always @ (posedge clk) begin
		temp_rx_in <= rx_in;
	end

	always@(posedge clk) begin
		if(reset) begin
			tx_counter <= 10'b0000000000;
			rx_counter <= 10'b0000000000;
		end
		else begin
			 tx_counter <= tx_counter + 1'b1;
			 rx_counter <= rx_counter + 1'b1;

			 if(tx_counter == 434) begin
				 tx_counter <= 10'b0000000000;
				 tx_clk <= ~tx_clk;
			 end
			 if(rx_counter == 27) begin
				 rx_counter <= 10'b0000000000;
				 rx_clk <= ~rx_clk;
			 end
		end
	end

	always @ (posedge rx_clk) begin
		if(reset) begin
			rx_data_cnt <= 2'b00;
			rx_state <= 3'b000;
		end
		case(rx_state)
		3'b000 : begin
				if (rx_data_cnt == 2'b11) begin
					rx_data_cnt <= 2'b00;
				end
				if(start_conversion)
					start_conversion <= 1'b0;
				uld_rx_data <= 1'b0;
				rx_enable <= 1'b1;
				rx_state <= 3'b001;
			 end
		3'b001 : begin
				if(rx_empty == 1'b1) begin
					uld_rx_data <= 1'b0;
					rx_data_cnt <= rx_data_cnt + 1'b1;
					clk_cnt <= 2'b00;
					rx_state <= 3'b010;
				end
			 end
		3'b010 : begin
				if(rx_empty == 1'b0) begin
					uld_rx_data <= 1'b1;
					rx_state <= 3'b011;
				end
			 end
		3'b011 : begin
				rx_state <= 3'b100;
			 end
		3'b100 : begin
				if(rx_data_cnt == 2'b01) begin
					red_rx_data <= rx_data;
				end
				if(rx_data_cnt == 2'b10) begin
					green_rx_data <= rx_data;
				end
				if(rx_data_cnt == 2'b11) begin
					blue_rx_data <= rx_data;
					start_conversion <= 1'b1;
				end
				rx_state <= 3'b101;
			 end
		3'b101 : begin
				rx_state <= 3'b001;
			 end
		endcase
	end

	always @ (posedge tx_clk) begin
		if(reset) begin
			tx_data_cnt <= 2'b11;
			tx_state <= 2'b00;
		end
		case(tx_state)
			2'b00 : begin
					if(tx_data_cnt == 2'b00) begin
						tx_data_cnt <= 2'b11;
					end
					ld_tx_data <= 1'b0;
					temp_tx_data <= 8'b00000000;
					tx_enable <= 1'b1;
					tx_state <= 2'b01;
				end
			2'b01 : begin
					if(tx_data_cnt ==  2'b11) begin
						temp_tx_data <= red_tx_data;
					end
					if(tx_data_cnt ==  2'b10) begin
						temp_tx_data <= green_tx_data;
					end
					if(tx_data_cnt ==  2'b01) begin
						temp_tx_data <= blue_tx_data;
					end
					if(tx_empty == 1'b1 && conversion_done == 1'b1) begin
						ld_tx_data <= 1'b1;
						tx_state <= 2'b10;
					end
				end
			2'b10 : begin
					if(tx_empty == 1'b0) begin
						ld_tx_data <= 1'b0;
						tx_state <= 2'b11;
					end
				end
			2'b11 : begin
					if(tx_empty == 1'b1) begin
						tx_data_cnt <= tx_data_cnt - 2'b01;
						tx_state <= 2'b00;
					end
				end
		endcase
	end

	ImageTransformation it (
		 .old_red(red_rx_data),
		 .old_green(green_rx_data),
		 .old_blue(blue_rx_data),
		 .clk(clk),
		 .enable(start_conversion),
		 .new_red(red_tx_data),
		 .new_green(green_tx_data),
		 .new_blue(blue_tx_data),
		 .done(conversion_done)
	);


	uart uut (
		.reset(reset),
		.txclk(tx_clk),
		.ld_tx_data(ld_tx_data),
		.tx_data(temp_tx_data),
		.tx_enable(tx_enable),
		.tx_out(tx_out),
		.tx_empty(tx_empty),
		.rxclk(rx_clk),
		.uld_rx_data(uld_rx_data),
		.rx_data(rx_data),
		.rx_enable(rx_enable),
		.rx_in(temp_rx_in),
		.rx_empty(rx_empty)
	);
endmodule
