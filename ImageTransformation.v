`timescale 1ns / 1ps

module ImageTransformation(
    input [7:0] old_red,
    input [7:0] old_green,
    input [7:0] old_blue,
	  input clk,
	  input enable,
    output reg [7:0] new_red,
    output reg [7:0] new_green,
    output reg [7:0] new_blue,
	  output reg done
    );

	reg [7:0] tempold_red;
	reg [7:0] tempold_green;
	reg [7:0] tempold_blue;
	wire [7:0] tempnew_red;


	assign tempnew_red = tempold_red + tempold_green + tempold_blue;

	always @ (posedge clk) begin
		if(enable) begin

			tempold_red <= (old_red >> 3) + (old_red >> 4) + (old_red >> 5);
			tempold_green <= ((old_green >> 2) + (old_green >> 1));
			tempold_blue <= (old_blue >> 4);
			new_red <= tempnew_red;
			new_green <= tempnew_red;
			new_blue <= tempnew_red;
			done <= 1'b1;
		end
	end


endmodule
