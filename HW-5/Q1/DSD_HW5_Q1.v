module complex_multiplier #(
    parameter IN_WIDTH  = 15,
    parameter OUT_WIDTH = 31
)(
    input wire clk,
    input wire rst,
    input wire signed [IN_WIDTH-1:0] Ar, input wire signed [IN_WIDTH-1:0] Ai,
    input wire signed [IN_WIDTH-1:0] Br, input wire signed [IN_WIDTH-1:0] Bi,
    input wire conj,
    output reg signed [OUT_WIDTH-1:0] Yr, output reg signed [OUT_WIDTH-1:0] Yi
);

    // registers fot latching the inputs
    reg signed [IN_WIDTH-1:0] Ar_reg, Ai_reg;
    reg signed [IN_WIDTH-1:0] Br_reg, Bi_reg;
    reg conj_reg;

    // Intermediate products: 15-bit signed * 15-bit signed = 30-bit signed
    wire signed [29:0] ArBr = Ar_reg * Br_reg;
    wire signed [29:0] AiBi = Ai_reg * Bi_reg;
    wire signed [29:0] ArBi = Ar_reg * Bi_reg;
    wire signed [29:0] AiBr = Ai_reg * Br_reg;

    always @(posedge clk) begin
        // synchronous reset
        if (rst) begin
            Ar_reg   <= {IN_WIDTH{1'b0}};
            Ai_reg   <= {IN_WIDTH{1'b0}};
            Br_reg   <= {IN_WIDTH{1'b0}};
            Bi_reg   <= {IN_WIDTH{1'b0}};
            conj_reg <= 1'b0;
            Yr       <= {OUT_WIDTH{1'b0}};
            Yi       <= {OUT_WIDTH{1'b0}};
        end else begin
            // 1: latch inputs to the registers
            Ar_reg <= Ar; Ai_reg <= Ai;
            Br_reg <= Br; Bi_reg <= Bi;
            conj_reg <= conj;

            // 2: calculate outputs using values in the registers
            if (!conj_reg) begin
                Yr <= ArBr - AiBi;
                Yi <= ArBi + AiBr;
            end else begin
                Yr <= ArBr + AiBi;
                Yi <= AiBr - ArBi;
            end
        end
    end

endmodule