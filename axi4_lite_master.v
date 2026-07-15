// =====================================================================
// File        : axi_lite_master.v
// Module      : axi_lite_master
// Standard    : AMBA AXI4-Lite
// Description : Synthesizable AXI4-Lite master. Converts a simple
//               request interface (start/write/addr/wdata) into a
//               full 5-channel AXI4-Lite transaction:
//                 Write : AW -> W -> B
//                 Read  : AR -> R
//               Single outstanding transaction at a time.
//
// Ports
//   Request side : start, write, addr, wdata, rdata, done, busy
//   AXI side     : AW/W/B (write) and AR/R (read) channels
// =====================================================================
module axi_lite_master #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input                           ACLK,
    input                           ARESETn,

    // Simple request interface
    input                           start,
    input                           write,
    input      [ADDR_WIDTH-1:0]     addr,
    input      [DATA_WIDTH-1:0]     wdata,
    output reg [DATA_WIDTH-1:0]     rdata,
    output reg                      done,
    output                          busy,

    // Write Address channel
    output reg [ADDR_WIDTH-1:0]     AWADDR,
    output reg                      AWVALID,
    input                           AWREADY,

    // Write Data channel
    output reg [DATA_WIDTH-1:0]     WDATA,
    output     [(DATA_WIDTH/8)-1:0] WSTRB,
    output reg                      WVALID,
    input                           WREADY,

    // Write Response channel
    input      [1:0]                BRESP,
    input                            BVALID,
    output reg                       BREADY,

    // Read Address channel
    output reg [ADDR_WIDTH-1:0]     ARADDR,
    output reg                      ARVALID,
    input                           ARREADY,

    // Read Data channel
    input      [DATA_WIDTH-1:0]     RDATA,
    input      [1:0]                RRESP,
    input                           RVALID,
    output reg                      RREADY
);

    assign WSTRB = {(DATA_WIDTH/8){1'b1}}; // full-word strobes only

    localparam IDLE = 3'd0;
    localparam AW   = 3'd1;
    localparam WD   = 3'd2;
    localparam BR   = 3'd3;
    localparam AR   = 3'd4;
    localparam RD   = 3'd5;

    reg [2:0] state, next_state;

    assign busy = (state != IDLE);

    //-----------------------------------------------------------------
    // State register
    //-----------------------------------------------------------------
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn)
            state <= IDLE;
        else
            state <= next_state;
    end

    //-----------------------------------------------------------------
    // Next state logic
    //-----------------------------------------------------------------
    always @(*) begin
        case (state)
            IDLE : next_state = !start ? IDLE : (write ? AW : AR);
            AW   : next_state = (AWVALID && AWREADY) ? WD : AW;
            WD   : next_state = (WVALID && WREADY)   ? BR : WD;
            BR   : next_state = (BVALID && BREADY)   ? IDLE : BR;
            AR   : next_state = (ARVALID && ARREADY) ? RD : AR;
            RD   : next_state = (RVALID && RREADY)   ? IDLE : RD;
            default: next_state = IDLE;
        endcase
    end

    //-----------------------------------------------------------------
    // Address / data capture + channel valid signals
    //-----------------------------------------------------------------
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            AWADDR  <= {ADDR_WIDTH{1'b0}};
            WDATA   <= {DATA_WIDTH{1'b0}};
            ARADDR  <= {ADDR_WIDTH{1'b0}};
            AWVALID <= 1'b0;
            WVALID  <= 1'b0;
            BREADY  <= 1'b0;
            ARVALID <= 1'b0;
            RREADY  <= 1'b0;
            rdata   <= {DATA_WIDTH{1'b0}};
            done    <= 1'b0;
        end else begin
            done <= 1'b0; // default, 1-cycle pulse

            case (state)
                IDLE: begin
                    AWVALID <= 1'b0;
                    WVALID  <= 1'b0;
                    BREADY  <= 1'b0;
                    ARVALID <= 1'b0;
                    RREADY  <= 1'b0;
                    if (start) begin
                        if (write) begin
                            AWADDR  <= addr;
                            WDATA   <= wdata;
                            AWVALID <= 1'b1;
                        end else begin
                            ARADDR  <= addr;
                            ARVALID <= 1'b1;
                        end
                    end
                end

                AW: begin
                    if (AWVALID && AWREADY) begin
                        AWVALID <= 1'b0;
                        WVALID  <= 1'b1;
                    end
                end

                WD: begin
                    if (WVALID && WREADY) begin
                        WVALID <= 1'b0;
                        BREADY <= 1'b1;
                    end
                end

                BR: begin
                    if (BVALID && BREADY) begin
                        BREADY <= 1'b0;
                        done   <= 1'b1;
                    end
                end

                AR: begin
                    if (ARVALID && ARREADY) begin
                        ARVALID <= 1'b0;
                        RREADY  <= 1'b1;
                    end
                end

                RD: begin
                    if (RVALID && RREADY) begin
                        rdata  <= RDATA;
                        RREADY <= 1'b0;
                        done   <= 1'b1;
                    end
                end

                default: ;
            endcase
        end
    end

endmodule
