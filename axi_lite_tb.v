// =====================================================================
// File        : axi_lite_tb.v
// Module      : axi_lite_tb  (simulation only, not synthesizable)
// Description : Self-checking testbench for axi_lite_top. Issues
//               writes and reads to both slaves and verifies
//               read-back data.
// =====================================================================
`timescale 1ns/1ps

module axi_lite_tb;

    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    reg                     ACLK;
    reg                     ARESETn;

    reg                     start;
    reg                     write;
    reg  [ADDR_WIDTH-1:0]   addr;
    reg  [DATA_WIDTH-1:0]   wdata;
    wire [DATA_WIDTH-1:0]   rdata;
    wire                    done;
    wire                    busy;

    integer errors = 0;

    axi_lite_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .start   (start),
        .write   (write),
        .addr    (addr),
        .wdata   (wdata),
        .rdata   (rdata),
        .done    (done),
        .busy    (busy)
    );

    initial ACLK = 1'b0;
    always #5 ACLK = ~ACLK;

    task axi_write(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] d);
    begin
        @(posedge ACLK); #1;
        start = 1'b1;
        write = 1'b1;
        addr  = a;
        wdata = d;
        @(posedge ACLK); #1;
        start = 1'b0;
        wait (done == 1'b1);
        @(posedge ACLK);
    end
    endtask

    task axi_read(input [ADDR_WIDTH-1:0] a, input [DATA_WIDTH-1:0] expected);
    begin
        @(posedge ACLK); #1;
        start = 1'b1;
        write = 1'b0;
        addr  = a;
        @(posedge ACLK); #1;
        start = 1'b0;
        wait (done == 1'b1);
        if (rdata !== expected) begin
            $display("[%0t] ERROR: addr=%0h expected=%0h got=%0h", $time, a, expected, rdata);
            errors = errors + 1;
        end else begin
            $display("[%0t] PASS : addr=%0h data=%0h", $time, a, rdata);
        end
        @(posedge ACLK);
    end
    endtask

    initial begin
        ARESETn = 1'b0;
        start   = 1'b0;
        write   = 1'b0;
        addr    = {ADDR_WIDTH{1'b0}};
        wdata   = {DATA_WIDTH{1'b0}};

        repeat (4) @(posedge ACLK);
        ARESETn = 1'b1;
        @(posedge ACLK);

        $display("---------------------------------------------------");
        $display(" Starting AXI4-Lite transactions ");
        $display("---------------------------------------------------");

        axi_write(32'h0000_0000, 32'hAAAA_0001);
        axi_write(32'h0000_0004, 32'hAAAA_0002);
        axi_read (32'h0000_0000, 32'hAAAA_0001);
        axi_read (32'h0000_0004, 32'hAAAA_0002);

        axi_write(32'h0000_0100, 32'hBBBB_0001);
        axi_write(32'h0000_0104, 32'hBBBB_0002);
        axi_read (32'h0000_0100, 32'hBBBB_0001);
        axi_read (32'h0000_0104, 32'hBBBB_0002);

        axi_write(32'h0000_0000, 32'hCCCC_CCCC);
        axi_read (32'h0000_0000, 32'hCCCC_CCCC);

        $display("---------------------------------------------------");
        if (errors == 0)
            $display(" ALL TESTS PASSED ");
        else
            $display(" TEST FAILED with %0d error(s) ", errors);
        $display("---------------------------------------------------");

        $finish;
    end

    initial begin
        $dumpfile("axi_lite_tb.vcd");
        $dumpvars(0, axi_lite_tb);
    end

endmodule
