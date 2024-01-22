`timescale 1ns / 1ps

module ClockForwarding (
    input wire clk_100m_shift,
    output wire sdram_clk
);

    wire clk_out;

    // Instantiate ODDR2 component for clock forwarding
    ODDR2 #(
        .DDR_ALIGNMENT("C0D0"),
        .INIT(1'b0),
        .SRTYPE("ASYNC")
    ) u_oddr2 (
        .Q(clk_out),
        .C0(clk_100m_shift),
        .C1(~clk_100m_shift),
        .D0(1'b1),
        .D1(1'b0)
    );

    assign sdram_clk = clk_out;

endmodule

