`timescale 1ns / 1ps

module tb_complex_multiplier;

    parameter IN_WIDTH  = 15;
    parameter OUT_WIDTH = 31;

    reg clk, rst;
    reg signed [14:0] Ar, Ai, Br, Bi;
    reg conj;
    wire signed [30:0] Yr, Yi;

    complex_multiplier #(IN_WIDTH, OUT_WIDTH) uut(
        .clk(clk), .rst(rst),
        .Ar(Ar), .Ai(Ai), .Br(Br), .Bi(Bi),
        .conj(conj),
        .Yr(Yr), .Yi(Yi)
    );

    always #5 clk = ~clk;

    integer passed, failed, test_num;

    task run_test;
        input signed [IN_WIDTH-1:0] in_Ar, in_Ai;
        input signed [IN_WIDTH-1:0] in_Br, in_Bi;
        input in_conj;
        integer exp_Yr, exp_Yi;
        begin
            test_num = test_num + 1;

            Ar   = in_Ar;
            Ai   = in_Ai;
            Br   = in_Br;
            Bi   = in_Bi;
            conj = in_conj;

            @(posedge clk); // cycle 1: latch inputs into internal registers
            @(posedge clk); // cycle 2: compute outputs from latched registers
            #1;             // small delay to let outputs settle

            // reference model — mirrors the DUT formulas exactly
            if (in_conj == 1'b0) begin
                exp_Yr = ($signed(in_Ar) * $signed(in_Br)) - ($signed(in_Ai) * $signed(in_Bi));
                exp_Yi = ($signed(in_Ar) * $signed(in_Bi)) + ($signed(in_Ai) * $signed(in_Br));
            end else begin
                exp_Yr = ($signed(in_Ar) * $signed(in_Br)) + ($signed(in_Ai) * $signed(in_Bi));
                exp_Yi = ($signed(in_Ai) * $signed(in_Br)) - ($signed(in_Ar) * $signed(in_Bi));
            end

            if (Yr == exp_Yr && Yi == exp_Yi) begin
                passed = passed + 1;
                $display("[PASS] Vector %0d: A=(%0d, %0d) B=(%0d, %0d) conj=%0b | Yr=%0d, Yi=%0d",
                         test_num, in_Ar, in_Ai, in_Br, in_Bi, in_conj, Yr, Yi);
            end else begin
                failed = failed + 1;
                $display("[FAIL] Vector %0d: A=(%0d, %0d) B=(%0d, %0d) conj=%0b",
                         test_num, in_Ar, in_Ai, in_Br, in_Bi, in_conj);
                $display("       Expected: Yr=%0d, Yi=%0d", exp_Yr, exp_Yi);
                $display("       Got:      Yr=%0d, Yi=%0d", Yr, Yi);
            end
            $display("------------------------------------------------------------");
        end
    endtask

    initial begin
        clk      = 0;
        rst      = 1;
        Ar       = 0;
        Ai       = 0;
        Br       = 0;
        Bi       = 0;
        conj     = 0;
        passed   = 0;
        failed   = 0;
        test_num = 0;

        $dumpfile("DSD_HW5_Q1.vcd");
        $dumpvars(0, tb_complex_multiplier);

        $display("\n=== Complex Multiplier Testbench ===");

        #15;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // verify reset state: all outputs must be zero
        test_num = test_num + 1;
        if (Yr === 0 && Yi === 0) begin
            passed = passed + 1;
            $display("[PASS] Vector %0d (reset check): Yr=%0d, Yi=%0d", test_num, Yr, Yi);
        end else begin
            failed = failed + 1;
            $display("[FAIL] Vector %0d (reset check): Expected Yr=0, Yi=0, Got Yr=%0d, Yi=%0d",
                     test_num, Yr, Yi);
        end
        $display("------------------------------------------------------------");

        // Positive components (conj=0 and conj=1)
        run_test(15'sd10, 15'sd5,   15'sd4,    15'sd3,   1'b0);
        run_test(15'sd10, 15'sd5,   15'sd4,    15'sd3,   1'b1);

        // Negative components (conj=0 and conj=1)
        run_test(-15'sd8, -15'sd6, -15'sd3,   15'sd2,   1'b0);
        run_test(-15'sd8, -15'sd6, -15'sd3,   15'sd2,   1'b1);

        // Zero input
        run_test(15'sd0,  15'sd0,   15'sd100, -15'sd50, 1'b0);

        // Max positive boundary
        run_test(15'sh3FFF, 15'sh3FFF, 15'sh3FFF, 15'sh3FFF, 1'b0);

        // Min negative boundary (0x4000 = -16384 in 15-bit two's complement)
        run_test(15'sh4000, 15'sh4000, 15'sh3FFF, 15'sh3FFF, 1'b1);

        // Min negative boundary x min negative boundary
        run_test(15'sh4000, 15'sh4000, 15'sh4000, 15'sh4000, 1'b0);
        run_test(15'sh4000, 15'sh4000, 15'sh4000, 15'sh4000, 1'b1);

        $display("\n%0d PASSED, %0d FAILED out of %0d tests.", passed, failed, passed + failed);

        $finish;
    end

endmodule