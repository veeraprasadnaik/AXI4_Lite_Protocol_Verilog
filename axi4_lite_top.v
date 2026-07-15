// =====================================================================
// File        : axi_lite_top.v
// Module      : axi_lite_top
// Standard    : AMBA AXI4-Lite
// Description : Top-level integration of the AXI4-Lite subsystem:
//               axi_lite_master -> axi_lite_interconnect (contains
//               axi_lite_decoder) -> {axi_lite_slave0, axi_lite_slave1}
//               -> back to axi_lite_master.
//               Exposes a simple start/write/addr/wdata/rdata/done
//               interface to the outside world; the internal AXI
//               bus is fully self-contained.
// =====================================================================
module axi_lite_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                       ACLK,
    input                       ARESETn,

    input                       start,
    input                       write,
    input      [ADDR_WIDTH-1:0] addr,
    input      [DATA_WIDTH-1:0] wdata,
    output     [DATA_WIDTH-1:0] rdata,
    output                      done,
    output                      busy
);

    localparam STRB_WIDTH = DATA_WIDTH/8;

    // Master <-> Interconnect
    wire [ADDR_WIDTH-1:0] AWADDR;
    wire                   AWVALID;
    wire                   AWREADY;
    wire [DATA_WIDTH-1:0]  WDATA;
    wire [STRB_WIDTH-1:0]  WSTRB;
    wire                   WVALID;
    wire                   WREADY;
    wire [1:0]             BRESP;
    wire                   BVALID;
    wire                   BREADY;
    wire [ADDR_WIDTH-1:0]  ARADDR;
    wire                   ARVALID;
    wire                   ARREADY;
    wire [DATA_WIDTH-1:0]  RDATA;
    wire [1:0]             RRESP;
    wire                   RVALID;
    wire                   RREADY;

    // Interconnect <-> Slave0
    wire [ADDR_WIDTH-1:0] S0_AWADDR;
    wire                   S0_AWVALID, S0_AWREADY;
    wire [DATA_WIDTH-1:0]  S0_WDATA;
    wire [STRB_WIDTH-1:0]  S0_WSTRB;
    wire                   S0_WVALID, S0_WREADY;
    wire [1:0]             S0_BRESP;
    wire                   S0_BVALID, S0_BREADY;
    wire [ADDR_WIDTH-1:0]  S0_ARADDR;
    wire                   S0_ARVALID, S0_ARREADY;
    wire [DATA_WIDTH-1:0]  S0_RDATA;
    wire [1:0]             S0_RRESP;
    wire                   S0_RVALID, S0_RREADY;

    // Interconnect <-> Slave1
    wire [ADDR_WIDTH-1:0] S1_AWADDR;
    wire                   S1_AWVALID, S1_AWREADY;
    wire [DATA_WIDTH-1:0]  S1_WDATA;
    wire [STRB_WIDTH-1:0]  S1_WSTRB;
    wire                   S1_WVALID, S1_WREADY;
    wire [1:0]             S1_BRESP;
    wire                   S1_BVALID, S1_BREADY;
    wire [ADDR_WIDTH-1:0]  S1_ARADDR;
    wire                   S1_ARVALID, S1_ARREADY;
    wire [DATA_WIDTH-1:0]  S1_RDATA;
    wire [1:0]             S1_RRESP;
    wire                   S1_RVALID, S1_RREADY;

    //-----------------------------------------------------------------
    // AXI4-Lite Master
    //-----------------------------------------------------------------
    axi_lite_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi_lite_master (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        .start   (start),
        .write   (write),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .done    (done),
        .busy    (busy),

        .AWADDR  (AWADDR),  .AWVALID (AWVALID), .AWREADY (AWREADY),
        .WDATA   (WDATA),   .WSTRB   (WSTRB),   .WVALID  (WVALID),  .WREADY (WREADY),
        .BRESP   (BRESP),   .BVALID  (BVALID),  .BREADY  (BREADY),
        .ARADDR  (ARADDR),  .ARVALID (ARVALID), .ARREADY (ARREADY),
        .RDATA   (RDATA),   .RRESP   (RRESP),   .RVALID  (RVALID),  .RREADY (RREADY)
    );

    //-----------------------------------------------------------------
    // AXI4-Lite Interconnect (decode + channel routing)
    //-----------------------------------------------------------------
    axi_lite_interconnect #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi_lite_interconnect (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        .AWADDR (AWADDR), .AWVALID (AWVALID), .AWREADY (AWREADY),
        .WDATA  (WDATA),  .WSTRB   (WSTRB),   .WVALID  (WVALID),  .WREADY (WREADY),
        .BRESP  (BRESP),  .BVALID  (BVALID),  .BREADY  (BREADY),
        .ARADDR (ARADDR), .ARVALID (ARVALID), .ARREADY (ARREADY),
        .RDATA  (RDATA),  .RRESP   (RRESP),   .RVALID  (RVALID),  .RREADY (RREADY),

        .S0_AWADDR (S0_AWADDR), .S0_AWVALID (S0_AWVALID), .S0_AWREADY (S0_AWREADY),
        .S0_WDATA  (S0_WDATA),  .S0_WSTRB   (S0_WSTRB),   .S0_WVALID  (S0_WVALID),  .S0_WREADY (S0_WREADY),
        .S0_BRESP  (S0_BRESP),  .S0_BVALID  (S0_BVALID),  .S0_BREADY  (S0_BREADY),
        .S0_ARADDR (S0_ARADDR), .S0_ARVALID (S0_ARVALID), .S0_ARREADY (S0_ARREADY),
        .S0_RDATA  (S0_RDATA),  .S0_RRESP   (S0_RRESP),   .S0_RVALID  (S0_RVALID),  .S0_RREADY (S0_RREADY),

        .S1_AWADDR (S1_AWADDR), .S1_AWVALID (S1_AWVALID), .S1_AWREADY (S1_AWREADY),
        .S1_WDATA  (S1_WDATA),  .S1_WSTRB   (S1_WSTRB),   .S1_WVALID  (S1_WVALID),  .S1_WREADY (S1_WREADY),
        .S1_BRESP  (S1_BRESP),  .S1_BVALID  (S1_BVALID),  .S1_BREADY  (S1_BREADY),
        .S1_ARADDR (S1_ARADDR), .S1_ARVALID (S1_ARVALID), .S1_ARREADY (S1_ARREADY),
        .S1_RDATA  (S1_RDATA),  .S1_RRESP   (S1_RRESP),   .S1_RVALID  (S1_RVALID),  .S1_RREADY (S1_RREADY)
    );

    //-----------------------------------------------------------------
    // AXI4-Lite Slave 0  (0x0000_0000 - 0x0000_00FF)
    //-----------------------------------------------------------------
    axi_lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (4)
    ) u_axi_lite_slave0 (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        .AWADDR (S0_AWADDR), .AWVALID (S0_AWVALID), .AWREADY (S0_AWREADY),
        .WDATA  (S0_WDATA),  .WSTRB   (S0_WSTRB),   .WVALID  (S0_WVALID),  .WREADY (S0_WREADY),
        .BRESP  (S0_BRESP),  .BVALID  (S0_BVALID),  .BREADY  (S0_BREADY),
        .ARADDR (S0_ARADDR), .ARVALID (S0_ARVALID), .ARREADY (S0_ARREADY),
        .RDATA  (S0_RDATA),  .RRESP   (S0_RRESP),   .RVALID  (S0_RVALID),  .RREADY (S0_RREADY)
    );

    //-----------------------------------------------------------------
    // AXI4-Lite Slave 1  (0x0000_0100 - 0x0000_01FF)
    //-----------------------------------------------------------------
    axi_lite_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .NUM_REGS  (4)
    ) u_axi_lite_slave1 (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),

        .AWADDR (S1_AWADDR), .AWVALID (S1_AWVALID), .AWREADY (S1_AWREADY),
        .WDATA  (S1_WDATA),  .WSTRB   (S1_WSTRB),   .WVALID  (S1_WVALID),  .WREADY (S1_WREADY),
        .BRESP  (S1_BRESP),  .BVALID  (S1_BVALID),  .BREADY  (S1_BREADY),
        .ARADDR (S1_ARADDR), .ARVALID (S1_ARVALID), .ARREADY (S1_ARREADY),
        .RDATA  (S1_RDATA),  .RRESP   (S1_RRESP),   .RVALID  (S1_RVALID),  .RREADY (S1_RREADY)
    );

endmodule
