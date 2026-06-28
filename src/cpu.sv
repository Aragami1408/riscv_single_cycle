module cpu (
	input logic clk,
	input logic rst_n
);

	// -------------------- PROGRAM COUNTER --------------------
	logic [31:0] pc, pc_next;
	logic pc_source; // from control unit

	always_comb begin : pc_select
		pc_next = (pc_source) ? (pc + immediate) : (pc + 32'd4);
	end

	always @(posedge clk) begin
		if (rst_n == 0) begin
			pc <= 32'b0;
		end else begin
			pc <= pc_next;
		end
	end

	// -------------------- INSTRUCTION MEMORY (ROM) ------------
	wire [31:0] instruction;

	memory #(
		.mem_init("./test_imemory.hex")
	) instruction_memory (
		// Memory inputs
		.clk(clk),
		.address(pc),
		.write_data(32'b0),
		.write_enable(1'b0),
		.rst_n(1'b1),

		// Memory outputs
		.read_data(instruction)
	);


	// -------------------- INSTRUCTION FIELDS --------------------
	logic [6:0] op;
	logic [2:0] func3;
	logic [6:0] func7;
	logic [4:0] rs1, rs2, rd;

	assign op = instruction[6:0];
	assign func3 = instruction[14:12];
	assign func7 = instruction[31:25];
	assign rs1 = instruction[19:15];
	assign rs2 = instruction[24:20];
	assign rd = instruction[11:7];

	wire [2:0] alu_control;
	wire [1:0] imm_source;
	wire mem_write, reg_write;
	wire alu_source, write_back_source;
	wire alu_zero;

	control control_unit(
		.op(op),
		.func3(func3),
		.func7(func7),
		.alu_zero(alu_zero),
		.alu_control(alu_control),
		.imm_source(imm_source),
		.mem_write(mem_write),
		.reg_write(reg_write),
		.alu_source(alu_source),
		.write_back_source(write_back_source),
		.pc_source(pc_source)
	);


	// -------------------- REGISTER FILE --------------------
	wire [31:0] read_reg1, read_reg2;

	regfile regfile(
		.clk(clk),
		.rst_n(rst_n),

		.address1(rs1),
		.address2(rs2),

		.read_data1(read_reg1),
		.read_data2(read_reg2),

		.write_enable(reg_write),
		.write_data(write_back_data),
		.address3(rd)
	);

	// -------------------- SIGN EXTENDER -------------------
	
	logic [24:0] raw_imm;
	assign raw_imm = instruction[31:7];
	wire [31:0] immediate;

	signext sign_extender(
		.raw_src(raw_imm),
		.imm_source(imm_source),
		.immediate(immediate)
	);

	// -------------------- ALU -------------------
	
	wire [31:0] alu_result;
	logic [31:0] alu_src2;

	always_comb begin : alu_source_select
		alu_src2 = (alu_source) ? immediate : read_reg2;
	end

	alu alu_inst(
		.alu_control(alu_control),
		.src1(read_reg1),
		.src2(alu_src2),

		.alu_result(alu_result),
		.zero(alu_zero)
	);

	// -------------------- DATA MEMORY -------------------
	wire [31:0] mem_read;

	memory #(
		.mem_init("./test_dmemory.hex")
	) data_memory (
		.clk(clk),
		.address(alu_result),
		.write_data(read_reg2),
		.write_enable(mem_write),
		.rst_n(1'b1),
		.read_data(mem_read)
	);

	// -------------------- WRITE‑BACK MUX --------------------
	logic [31:0] write_back_data;

	always_comb begin
		write_back_data = (write_back_source) ? mem_read : alu_result;
	end

endmodule
