`default_nettype none

module tt_um_datiuemm (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    //-----------------------------------------------------------------
    // MBIST mode decode
    //-----------------------------------------------------------------
    parameter NUM_BIT_OF_MODE = 2;

    wire [NUM_BIT_OF_MODE:0] mbist_mode;
    assign mbist_mode = ui_in[NUM_BIT_OF_MODE:0];

    wire [2:0] add_in;
    assign add_in = ui_in[NUM_BIT_OF_MODE+3:NUM_BIT_OF_MODE+1];

    wire mbist_en;
    assign mbist_en = (mbist_mode == 3'b001);

    //-----------------------------------------------------------------
    // Internal signals
    //-----------------------------------------------------------------
    wire        ram_en;
    wire [4:0]  ram_we;
    wire [2:0]  ram_addr;
    wire [39:0] ram_data_i;
    wire [39:0] ram_data_o;
    wire        ecc_bypass;
    wire [2:0]  results;

    //-----------------------------------------------------------------
    // Output mapping
    //-----------------------------------------------------------------
    assign uo_out[2:0] = results;
    assign uo_out[7:3] = 5'b0;

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    //-----------------------------------------------------------------
    // RAM instance
    //-----------------------------------------------------------------
    RAM8 inst_RAM8 (
        .CLK  (clk),
        .WE0  (ram_we),
        .EN0  (ram_en),
        .A0   (ram_addr),
        .Di0  (ram_data_i),
        .Do0  (ram_data_o)
    );

    //-----------------------------------------------------------------
    // MBIST instance
    //-----------------------------------------------------------------
    MBIST inst_MBIST (
        .clk       (clk),
        .rst_n     (rst_n),
        .mbist_en  (mbist_en),
        .ram_data_o(ram_data_o),

        .ram_en    (ram_en),
        .ram_we    (ram_we),
        .ram_addr  (ram_addr),
        .ram_data_i(ram_data_i),

        .ecc_bypass(ecc_bypass),
        .results   (results)
    );

    //-----------------------------------------------------------------
    // Unused pins
    //-----------------------------------------------------------------
    wire _unused = &{
        ena,
        uio_in,
        ecc_bypass,
        add_in,
        ui_in[7:6],
        1'b0
    };

endmodule
