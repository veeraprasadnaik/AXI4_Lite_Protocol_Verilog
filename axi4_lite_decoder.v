// =====================================================================
// File        : axi_lite_decoder.v
// Module      : axi_lite_decoder
// Standard    : AMBA AXI4-Lite
// Description : Combinational address decoder for both the write
//               (AWADDR) and read (ARADDR) address channels. Generates
//               independent select signals per channel since AXI
//               write and read paths operate concurrently.
//
// Address map
//   Slave0 : 0x0000_0000 - 0x0000_00FF  (ADDR[8] = 0)
//   Slave1 : 0x0000_0100 - 0x0000_01FF  (ADDR[8] = 1)
// K VEERA PRASAD NAIK
// =====================================================================
module axi_lite_decoder #(
    parameter ADDR_WIDTH = 32
)(
    input      [ADDR_WIDTH-1:0] AWADDR,
    output                      AWSEL0,
    output                      AWSEL1,

    input      [ADDR_WIDTH-1:0] ARADDR,
    output                      ARSEL0,
    output                      ARSEL1
);

    assign AWSEL0 = (AWADDR[ADDR_WIDTH-1:9] == 0) && (AWADDR[8] == 1'b0);
    assign AWSEL1 = (AWADDR[ADDR_WIDTH-1:9] == 0) && (AWADDR[8] == 1'b1);

    assign ARSEL0 = (ARADDR[ADDR_WIDTH-1:9] == 0) && (ARADDR[8] == 1'b0);
    assign ARSEL1 = (ARADDR[ADDR_WIDTH-1:9] == 0) && (ARADDR[8] == 1'b1);

endmodule
