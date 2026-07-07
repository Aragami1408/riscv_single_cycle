module alu (
	input logic [2:0] alu_control,   // Operation selector
	input logic [31:0] src1,         // First operand
	input logic [31:0] src2,         // Second operand

	output logic [31:0] alu_result,  // Computation result
	output logic zero                // 1 if alu_result == 0
);

	always_comb begin
		case (alu_control)
			3'b000: alu_result = src1 + src2;           // ADD
			3'b010: alu_result = src1 & src2;           // AND
			3'b011: alu_result = src1 | src2;           // OR
			3'b001: alu_result = src1 + (~src2 + 1'b1); // SUB
			3'b101: alu_result = {31'b0, $signed(src1) < $signed(src2)};
			3'b111: alu_result = {31'b0, src1 < src2};
			default: alu_result = 32'b0;                // Unsupported operation
		endcase
	end

	assign zero = alu_result == 32'b0;
endmodule
