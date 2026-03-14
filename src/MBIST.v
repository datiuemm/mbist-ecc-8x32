module MBIST (
    input wire        clk,
    input wire        rst_n,
    input wire        mbist_en,
    input wire [39:0] ram_data_o,


    output reg        ram_en, 
    output reg [4:0]  ram_we,
    output reg [2:0]  ram_addr,
    output reg [39:0] ram_data_i,
    output reg        ecc_bypass,
    output reg [2:0]  results
);

    localparam MARCHC_IDLE   = 3'd0;
    localparam MARCHC_W0     = 3'd1;
    localparam MARCHC_R0W1   = 3'd2;
    localparam MARCHC_R1W0   = 3'd3;
    localparam MARCHC_R0W1_D = 3'd4;
    localparam MARCHC_R1W0_D = 3'd5;
    localparam MARCHC_R0     = 3'd6;
    localparam MARCHC_DONE   = 3'd7;

    localparam F_ZERO = 40'h00_0000_0000;
    localparam F_ONE  = 40'hFF_FFFF_FFFF;

    reg [2:0] state;
    reg [2:0] local_addr;
    reg       fail;
    reg       read_valid;

    reg [2:0] check_pipe;     
    reg [2:0] exp_data_pipe;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= MARCHC_IDLE;
            local_addr   <= 3'b000;
            fail         <= 1'b0;
            results      <= 3'b000;
            ecc_bypass   <= 1'b0;
            ram_addr     <= 3'b000;
            ram_data_i   <= F_ZERO;
            ram_we       <= 5'b00000;
            read_valid   <= 1'b0;
            check_pipe   <= 3'b000;
            exp_data_pipe<= 3'b000;
            ram_en <= 1'b0;
        end
        else begin
            check_pipe    <= {check_pipe[1:0], 1'b0};
            exp_data_pipe <= {exp_data_pipe[1:0], 1'b0};

            if (mbist_en) begin
                case (state)
                    MARCHC_IDLE: begin
                        ecc_bypass <= 1;
                        local_addr <= 3'd0;
                        fail       <= 0;
                        results    <= 3'b000;
                        state      <= MARCHC_W0;
                        ram_en <= 1'b1;//EN berfore 1 cycle to make sure RAM timing...
                    end

                    MARCHC_W0: begin
                    	results[0] <= 1'b1;
                    	ram_en <= 1'b1;
                        ram_we     <= 5'b11111;
                        ram_addr   <= local_addr;
                        ram_data_i <= F_ZERO;
                        if (local_addr == 3'd7) begin
                            local_addr <= 3'd0;
                            state      <= MARCHC_R0W1;
                            read_valid <= 1'b1;
                        end else begin
                            local_addr <= local_addr + 1;
                        end
                    end

                    MARCHC_R0W1: begin
                        ram_addr <= local_addr;
                        if (read_valid) begin
                            ram_en <= 1'b1;
                            ram_we <= 5'b00000;
                            read_valid <= 1'b0;
                            check_pipe[0]    <= 1'b1;
                            exp_data_pipe[0] <= 1'b0; 
                        end else begin
                            ram_en <= 1'b1;
                            ram_we     <= 5'b11111;
                            ram_data_i <= F_ONE;
                            if (local_addr == 3'd7) begin
                                state      <= MARCHC_R1W0;
                                local_addr <= 3'd0;
                            end else begin
                                local_addr <= local_addr + 1;
                            end
                            read_valid <= 1'b1;
                        end
                    end

                    MARCHC_R1W0: begin
                        ram_addr <= local_addr;
                        if (read_valid) begin
                            ram_en <= 1'b1;
                            ram_we <= 5'b00000;
                            read_valid <= 1'b0;
                            check_pipe[0]    <= 1'b1;
                            exp_data_pipe[0] <= 1'b1;
                        end else begin
                            ram_en <= 1'b1;
                            ram_we     <= 5'b11111;
                            ram_data_i <= F_ZERO;
                            if (local_addr == 3'd7) begin
                                state      <= MARCHC_R0W1_D;
                                local_addr <= 3'd7;
                            end else begin
                                local_addr <= local_addr + 1;
                            end
                            read_valid <= 1'b1;
                        end
                    end

                    MARCHC_R0W1_D: begin
                        ram_addr <= local_addr;
                        if (read_valid) begin
                            ram_en <= 1'b1;
                            ram_we <= 5'b00000;
                            read_valid <= 1'b0;
                            check_pipe[0]    <= 1'b1;
                            exp_data_pipe[0] <= 1'b0;
                        end else begin
                            ram_en <= 1'b1;
                            ram_we     <= 5'b11111;
                            ram_data_i <= F_ONE;
                            if (local_addr == 3'd0) begin
                                state      <= MARCHC_R1W0_D;
                                local_addr <= 3'd7;
                            end else begin
                                local_addr <= local_addr - 1;
                            end
                            read_valid <= 1'b1;
                        end
                    end

                    MARCHC_R1W0_D: begin
                        ram_addr <= local_addr;
                        if (read_valid) begin
                            ram_en <= 1'b1;
                            ram_we <= 5'b00000;
                            read_valid <= 1'b0;
                            check_pipe[0]    <= 1'b1;
                            exp_data_pipe[0] <= 1'b1;
                        end else begin
                            ram_en <= 1'b1;
                            ram_we     <= 5'b11111;
                            ram_data_i <= F_ZERO;
                            if (local_addr == 3'd0) begin
                                state      <= MARCHC_R0;
                                local_addr <= 3'd7;
                            end else begin
                                local_addr <= local_addr - 1;
                            end
                            read_valid <= 1'b1;
                        end
                    end

                    MARCHC_R0: begin
                        ram_addr <= local_addr;
                        ram_en <= 1'b1;
                        ram_we   <= 5'b00000;
                        check_pipe[0]    <= 1'b1;
                        exp_data_pipe[0] <= 1'b0; 
                        if (local_addr == 3'd0) begin
                            state <= MARCHC_DONE;
                        end else begin
                            local_addr <= local_addr - 1;
                        end
                    end

                    MARCHC_DONE: begin
                        results[0] <= 1'b1;
                        results[1] <= fail;
                        results[2] <= ~fail;
                        ram_en <= 1'b0;
                        ecc_bypass <= 0;
                        if (!mbist_en) state <= MARCHC_IDLE;
                    end
                    
                    default: state <= MARCHC_IDLE;
                endcase
            end

            if (check_pipe[2]) begin
                if (^ram_data_o === 1'bX) begin
                    // skip transient unknown in gate-level simulation
                end
            else begin
                if (exp_data_pipe[2] == 1'b0) begin
                    if (ram_data_o != F_ZERO)
                        fail <= 1'b1;
                    end
                else begin
                    if (ram_data_o != F_ONE)
                        fail <= 1'b1;
                end
            end
        end
    end
    end

endmodule
