// =====================================================================
// File        : axi_lite_slave.v
// Module      : axi_lite_slave
// Standard    : AMBA AXI4-Lite
// Description : Generic synthesizable AXI4-Lite slave with a
//               parameterized 32-bit register bank (default: 4 regs).
//               AWREADY/WREADY/ARREADY are tied high (zero added
//               latency accepting slave). Write address is latched
//               at the AW handshake and committed when write data
//               arrives on the W channel; BVALID/RVALID are held
//               until the master asserts BREADY/RREADY.
// =====================================================================
module axi_lite_slave #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS   = 4
)(
    input                           ACLK,
    input                           ARESETn,

    // Write Address channel
    input      [ADDR_WIDTH-1:0]     AWADDR,
    input                           AWVALID,
    output                          AWREADY,

    // Write Data channel
    input      [DATA_WIDTH-1:0]     WDATA,
    input      [(DATA_WIDTH/8)-1:0] WSTRB,
    input                           WVALID,
    output                          WREADY,

    // Write Response channel
    output     [1:0]                BRESP,
    output                          BVALID,
    input                           BREADY,

    // Read Address channel
    input      [ADDR_WIDTH-1:0]     ARADDR,
    input                           ARVALID,
    output                          ARREADY,

    // Read Data channel
    output reg [DATA_WIDTH-1:0]     RDATA,
    output     [1:0]                RRESP,
    output                          RVALID,
    input                           RREADY
);

    reg [DATA_WIDTH-1:0] regs [0:NUM_REGS-1];
    integer i;

    // Zero added latency: always ready to accept
    assign AWREADY = 1'b1;
    assign WREADY  = 1'b1;
    assign ARREADY = 1'b1;
    assign BRESP   = 2'b00; // OKAY
    assign RRESP   = 2'b00; // OKAY

    //-----------------------------------------------------------------
    // Write path: latch AW index, commit on W handshake
    //-----------------------------------------------------------------
    reg [1:0] aw_index;
    reg       bvalid_reg;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            aw_index <= 2'b00;
        else if (AWVALID)
            aw_index <= AWADDR[3:2];
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            for (i = 0; i < NUM_REGS; i = i + 1)
                regs[i] <= {DATA_WIDTH{1'b0}};
        end else if (WVALID && WSTRB != {(DATA_WIDTH/8){1'b0}}) begin
            regs[aw_index] <= WDATA;
        end
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            bvalid_reg <= 1'b0;
        else if (WVALID)
            bvalid_reg <= 1'b1;
        else if (BVALID && BREADY)
            bvalid_reg <= 1'b0;
    end

    assign BVALID = bvalid_reg;

    //-----------------------------------------------------------------
    // Read path: latch AR index, present RDATA, hold RVALID until
    // the master accepts it
    //-----------------------------------------------------------------
    reg [1:0] ar_index;
    reg       rvalid_reg;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            ar_index <= 2'b00;
        else if (ARVALID)
            ar_index <= ARADDR[3:2];
    end

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            rvalid_reg <= 1'b0;
        else if (ARVALID)
            rvalid_reg <= 1'b1;
        else if (RVALID && RREADY)
            rvalid_reg <= 1'b0;
    end

    assign RVALID = rvalid_reg;

    always @(*) begin
        RDATA = regs[ar_index];
    end

endmodule
