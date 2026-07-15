// =====================================================================
// File        : axi_lite_interconnect.v
// Module      : axi_lite_interconnect
// Standard    : AMBA AXI4-Lite
// Description : Routes the 5 AXI4-Lite channels between one master
//               and two slaves. Since the write address (AW) and
//               write data (W) / write response (B) channels can be
//               temporally separated, the interconnect latches which
//               slave was targeted at the AW handshake (wsel) and
//               uses it to route W and B until the write completes.
//               The read path is latched the same way at the AR
//               handshake (rsel), routing R until the read completes.
//               This models a single-outstanding-transaction AXI-Lite
//               interconnect (no AWID/ARID based multi-transaction
//               tracking).
// =====================================================================
module axi_lite_interconnect #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                           ACLK,
    input                           ARESETn,

    // ---------------- Master-facing ports ----------------
    input      [ADDR_WIDTH-1:0]     AWADDR,
    input                           AWVALID,
    output                          AWREADY,

    input      [DATA_WIDTH-1:0]     WDATA,
    input      [(DATA_WIDTH/8)-1:0] WSTRB,
    input                           WVALID,
    output                          WREADY,

    output     [1:0]                BRESP,
    output                          BVALID,
    input                           BREADY,

    input      [ADDR_WIDTH-1:0]     ARADDR,
    input                           ARVALID,
    output                          ARREADY,

    output     [DATA_WIDTH-1:0]     RDATA,
    output     [1:0]                RRESP,
    output                          RVALID,
    input                           RREADY,

    // ---------------- Slave0-facing ports ----------------
    output     [ADDR_WIDTH-1:0]     S0_AWADDR,
    output                          S0_AWVALID,
    input                           S0_AWREADY,

    output     [DATA_WIDTH-1:0]     S0_WDATA,
    output     [(DATA_WIDTH/8)-1:0] S0_WSTRB,
    output                          S0_WVALID,
    input                           S0_WREADY,

    input      [1:0]                S0_BRESP,
    input                           S0_BVALID,
    output                          S0_BREADY,

    output     [ADDR_WIDTH-1:0]     S0_ARADDR,
    output                          S0_ARVALID,
    input                           S0_ARREADY,

    input      [DATA_WIDTH-1:0]     S0_RDATA,
    input      [1:0]                S0_RRESP,
    input                           S0_RVALID,
    output                          S0_RREADY,

    // ---------------- Slave1-facing ports ----------------
    output     [ADDR_WIDTH-1:0]     S1_AWADDR,
    output                          S1_AWVALID,
    input                           S1_AWREADY,

    output     [DATA_WIDTH-1:0]     S1_WDATA,
    output     [(DATA_WIDTH/8)-1:0] S1_WSTRB,
    output                          S1_WVALID,
    input                           S1_WREADY,

    input      [1:0]                S1_BRESP,
    input                           S1_BVALID,
    output                          S1_BREADY,

    output     [ADDR_WIDTH-1:0]     S1_ARADDR,
    output                          S1_ARVALID,
    input                           S1_ARREADY,

    input      [DATA_WIDTH-1:0]     S1_RDATA,
    input      [1:0]                S1_RRESP,
    input                           S1_RVALID,
    output                          S1_RREADY
);

    //-----------------------------------------------------------------
    // Address decode
    //-----------------------------------------------------------------
    wire AWSEL0, AWSEL1, ARSEL0, ARSEL1;

    axi_lite_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_decoder (
        .AWADDR (AWADDR),
        .AWSEL0 (AWSEL0),
        .AWSEL1 (AWSEL1),
        .ARADDR (ARADDR),
        .ARSEL0 (ARSEL0),
        .ARSEL1 (ARSEL1)
    );

    //-----------------------------------------------------------------
    // Write-channel routing latch (wsel): 0 = slave0, 1 = slave1
    //-----------------------------------------------------------------
    reg wsel;
    wire aw_handshake = AWVALID && AWREADY;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            wsel <= 1'b0;
        else if (aw_handshake)
            wsel <= AWSEL1 ? 1'b1 : 1'b0;
    end

    // AW channel: broadcast address, gate valid by decode
    assign S0_AWADDR  = AWADDR;
    assign S1_AWADDR  = AWADDR;
    assign S0_AWVALID = AWVALID && AWSEL0;
    assign S1_AWVALID = AWVALID && AWSEL1;
    assign AWREADY    = AWSEL0 ? S0_AWREADY : AWSEL1 ? S1_AWREADY : 1'b1;

    // W / B channels: routed using the latched wsel
    assign S0_WDATA  = WDATA;
    assign S1_WDATA  = WDATA;
    assign S0_WSTRB  = WSTRB;
    assign S1_WSTRB  = WSTRB;
    assign S0_WVALID = WVALID && (wsel == 1'b0);
    assign S1_WVALID = WVALID && (wsel == 1'b1);
    assign WREADY    = (wsel == 1'b0) ? S0_WREADY : S1_WREADY;

    assign S0_BREADY = BREADY && (wsel == 1'b0);
    assign S1_BREADY = BREADY && (wsel == 1'b1);
    assign BVALID    = (wsel == 1'b0) ? S0_BVALID : S1_BVALID;
    assign BRESP     = (wsel == 1'b0) ? S0_BRESP  : S1_BRESP;

    //-----------------------------------------------------------------
    // Read-channel routing latch (rsel): 0 = slave0, 1 = slave1
    //-----------------------------------------------------------------
    reg rsel;
    wire ar_handshake = ARVALID && ARREADY;

    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            rsel <= 1'b0;
        else if (ar_handshake)
            rsel <= ARSEL1 ? 1'b1 : 1'b0;
    end

    // AR channel: broadcast address, gate valid by decode
    assign S0_ARADDR  = ARADDR;
    assign S1_ARADDR  = ARADDR;
    assign S0_ARVALID = ARVALID && ARSEL0;
    assign S1_ARVALID = ARVALID && ARSEL1;
    assign ARREADY    = ARSEL0 ? S0_ARREADY : ARSEL1 ? S1_ARREADY : 1'b1;

    // R channel: routed using the latched rsel
    assign S0_RREADY = RREADY && (rsel == 1'b0);
    assign S1_RREADY = RREADY && (rsel == 1'b1);
    assign RVALID    = (rsel == 1'b0) ? S0_RVALID : S1_RVALID;
    assign RDATA     = (rsel == 1'b0) ? S0_RDATA  : S1_RDATA;
    assign RRESP     = (rsel == 1'b0) ? S0_RRESP  : S1_RRESP;

endmodule
