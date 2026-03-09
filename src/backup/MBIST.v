module MBIST (
	input wire 	  clk,
	input wire 	  rst_n,
	input wire [1:0]  mbist_mode,
	input wire [39:0] ram_data_o,
	
	output reg [2:0]  ram_addr,
	output reg [39:0] ram_data_i,
	output reg   	  ecc_bypass,
	output reg [2:0] results
	//output reg 		  ram_en
);

localparam MODE_NORMAL = 2'b00;
localparam MODE_MARCHC = 2'b01;
//localparam MODE_MBIST_FAULT_INJECTION = 3'b011;
localparam MODE_ECC_CHECK = 2'b11;
//localparam MODE_RESERVED = 3'b000;

localparam MARCHC_IDLE = 3'd0;
localparam MARCHC_W0 = 3'd1;
localparam MARCHC_R0W1 = 3'd2;
localparam MARCHC_R1W0 = 3'd3;
localparam MARCHC_R0W1_D = 3'd4;
localparam MARCHC_R1W0_D = 3'd5;
localparam MARCHC_R0 = 3'd6;
localparam MARCHC_DONE = 3'd7;

reg [2:0] mode;
//mode = mbist_mode;


reg [2:0] state;
//reg [2:0] next_state;
reg [2:0] local_addr;
reg 	  fail;

localparam F_ZERO = 40'h00_0000_0000;
localparam F_ONE  = 40'hFF_FFFF_FFFF;


always @(posedge clk) begin

	if (!rst_n) begin
		state <= MARCHC_IDLE;
		local_addr <= 3'b000;
		fail <= 1'b0;
		results <= 3'b000;
		ecc_bypass <= 1'b0;
		ram_addr <= 3'b000;
		ram_data_i <= F_ZERO;
	end
	else begin
		case (mbist_mode)
		
		MODE_MARCHC: begin
			case (state) 

				MARCHC_IDLE: begin
					ecc_bypass <= 1;
					local_addr <= 3'd0;
					fail <= 0;
					state <= MARCHC_W0;
				end

				MARCHC_W0: begin
					//ram_en <= 1'b1;
					ram_addr <= local_addr;
					ram_data_i <= F_ZERO;
					if (local_addr == 3'd7) begin
						local_addr <= 3'd0;
						state <= MARCHC_R0W1;
					end else begin
						local_addr <= local_addr + 1;
					end
				end

				MARCHC_R0W1: begin
					ram_addr <= local_addr;
					if (ram_data_o != F_ZERO) begin
						fail <= 1;
					end 
					ram_data_i <= F_ONE;
					if (local_addr == 3'd7) begin
						local_addr <= 3'd0;
						state <= MARCHC_R1W0;
					end else begin
						local_addr <= local_addr + 1;
					end
				end

				MARCHC_R1W0: begin
					ram_addr <= local_addr;
					if (ram_data_o != F_ONE) begin
						fail <= 1;
					end 
					ram_data_i <= F_ZERO;
					if (local_addr == 3'd0) begin
						local_addr <= 3'd0;
						state <= MARCHC_R0W1_D;
					end else begin
						local_addr <= local_addr - 1;
					end
				end

				MARCHC_R0W1_D: begin
    				ram_addr <= local_addr;

				    if (ram_data_o != F_ZERO) begin
						fail <= 1;
					end	

			   		ram_data_i <= F_ONE;

    				if (local_addr == 3'd0) begin
        			local_addr <= 3'd7;
        			state <= MARCHC_R1W0_D;
    				end else begin
        			local_addr <= local_addr - 1;
    				end
				end


				MARCHC_R1W0_D: begin
    				ram_addr <= local_addr;

    				if (ram_data_o != F_ONE) begin
						fail <= 1;
					end

    				ram_data_i <= F_ZERO;

    				if (local_addr == 3'd0) begin
        				local_addr <= 3'd0;
        				state <= MARCHC_R0;
    				end else begin
        				local_addr <= local_addr - 1;
    				end
				end

				MARCHC_R0: begin
					ram_addr <= local_addr;
					if (ram_data_o != F_ZERO) begin
						fail <= 1;
					end 
					if (local_addr == 3'd7) begin
						local_addr <= 3'd0;
						state <= MARCHC_DONE;
					end else begin
						local_addr <= local_addr + 1;
					end
				end

				MARCHC_DONE: begin
					if (mbist_mode != MODE_MARCHC) begin
        				state <= MARCHC_IDLE;
    				end
					results [0] <= 1'b1;
					results [1] <= fail;
					results [2] <= ~fail;
					ecc_bypass <= 0;
				end

				default: state <= MARCHC_IDLE;
			endcase
		end

		// MODE_MBIST_FAULT_INJECTION: begin
			
		// end

		MODE_NORMAL: begin
			ecc_bypass <= 0;
		end

		MODE_ECC_CHECK: begin
			//TBD
		end

		//default: MODE_NORMAL
		endcase
	end
end
endmodule
