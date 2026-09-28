`timescale 1ns / 1ps

module tb_sync_fifo;

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 16;
    parameter ADDR_WIDTH = 4;

    reg clk, rst;
    reg [DATA_WIDTH-1:0] din;
    reg wr_en, rd_en;
    wire [DATA_WIDTH-1:0] dout;
    wire full, empty;

    sync_fifo #(DATA_WIDTH, FIFO_DEPTH, ADDR_WIDTH) uut (
        .clk(clk),   .rst(rst),
        .din(din),   .wr_en(wr_en), .rd_en(rd_en),
        .dout(dout), .full(full),   .empty(empty)
    );

    always #5 clk = ~clk;

    integer passed, failed, test_num, cycle_num;
    reg tc_failed;
    integer i;

    // Helper task to check DUT outputs against expected values
    task check_step;
        input [DATA_WIDTH-1:0] exp_dout;
        input exp_full, exp_empty;
        begin
            #1; // Delay to let non-blocking assignments settle
            $display("  [Cycle %02d] IN: rst=%b din=0x%02h wr=%b rd=%b   |   DUT: dout=0x%02h full=%b empty=%b | EXP: dout=0x%02h full=%b empty=%b",
                     cycle_num, rst, din, wr_en, rd_en, dout, full, empty, exp_dout, exp_full, exp_empty);

            if (dout !== exp_dout || full !== exp_full || empty !== exp_empty) begin
                $display("       [ERROR] Mismatch at cycle %02d!", cycle_num);
                $display("               Expected: dout=0x%02h, full=%b, empty=%b", exp_dout, exp_full, exp_empty);
                $display("               Got:      dout=0x%02h, full=%b, empty=%b", dout, full, empty);
                tc_failed = 1;
            end
        end
    endtask

    task apply_reset;
        begin
            @(negedge clk);
            rst = 1; wr_en = 0; rd_en = 0; din = 0;
            @(posedge clk);
            cycle_num = cycle_num + 1;
            check_step(8'h00, 1'b0, 1'b1);
            @(negedge clk);
            rst = 0;
        end
    endtask

    task do_write;
        input [DATA_WIDTH-1:0] in_din;
        input [DATA_WIDTH-1:0] exp_dout;
        input exp_full, exp_empty;
        begin
            @(negedge clk); din = in_din; wr_en = 1; rd_en = 0;
            @(posedge clk);
            cycle_num = cycle_num + 1;
            check_step(exp_dout, exp_full, exp_empty);
            @(negedge clk); wr_en = 0;
        end
    endtask

    task do_read;
        input [DATA_WIDTH-1:0] exp_dout;
        input exp_full, exp_empty;
        begin
            @(negedge clk); wr_en = 0; rd_en = 1;
            @(posedge clk);
            cycle_num = cycle_num + 1;
            check_step(exp_dout, exp_full, exp_empty);
            @(negedge clk); rd_en = 0;
        end
    endtask

    task do_both;
        input [DATA_WIDTH-1:0] in_din;
        input [DATA_WIDTH-1:0] exp_dout;
        input exp_full, exp_empty;
        begin
            @(negedge clk); din = in_din; wr_en = 1; rd_en = 1;
            @(posedge clk);
            cycle_num = cycle_num + 1;
            check_step(exp_dout, exp_full, exp_empty);
            @(negedge clk); wr_en = 0; rd_en = 0;
        end
    endtask

    task finish_test_case;
        input reg [8*60:1] tc_name;
        begin
            test_num = test_num + 1;
            if (!tc_failed) begin
                passed = passed + 1;
                $display("[PASS] Test %0d (%0s): dout=0x%02h, full=%b, empty=%b",
                         test_num, tc_name, dout, full, empty);
            end else begin
                failed = failed + 1;
                $display("[FAIL] Test %0d (%0s): dout=0x%02h, full=%b, empty=%b",
                         test_num, tc_name, dout, full, empty);
            end
            $display("------------------------------------------------------------");
        end
    endtask

    initial begin
        clk       = 0;
        rst       = 0;
        din       = 0;
        wr_en     = 0;
        rd_en     = 0;
        passed    = 0;
        failed    = 0;
        test_num  = 0;
        cycle_num = 0;

        $dumpfile("DSD_HW5_Q3.vcd");
        $dumpvars(0, tb_sync_fifo);

        $display("\n=== Synchronous FIFO Testbench ===");

        // Test 1: Synchronous Reset 
        tc_failed = 0;
        apply_reset();
        finish_test_case("Synchronous Reset");

        // Test 2: Sequential Writes and Reads (FIFO ordering) 
        tc_failed = 0;
        apply_reset();
        do_write(8'hA1, 8'h00, 1'b0, 1'b0);
        do_write(8'hA2, 8'h00, 1'b0, 1'b0);
        do_write(8'hA3, 8'h00, 1'b0, 1'b0);
        do_write(8'hA4, 8'h00, 1'b0, 1'b0);
        do_read(8'hA1, 1'b0, 1'b0);
        do_read(8'hA2, 1'b0, 1'b0);
        do_read(8'hA3, 1'b0, 1'b0);
        do_read(8'hA4, 1'b0, 1'b1);
        finish_test_case("Sequential Write / Read / FIFO Order");

        // Test 3: Fill Completely + Write-to-Full Ignored 
        tc_failed = 0;
        apply_reset();
        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            do_write(8'h10 + i, 8'h00, (i == FIFO_DEPTH - 1), 1'b0);
        do_write(8'hFF, 8'h00, 1'b1, 1'b0); // Sentinel write to full FIFO
        do_read(8'h10, 1'b0, 1'b0);         // Verify head data remains 0x10
        finish_test_case("Fill Completely + Write-to-Full Ignored");

        // Test 4: Drain Completely + Read-from-Empty Ignored 
        tc_failed = 0;
        apply_reset();
        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            do_write(8'h20 + i, 8'h00, (i == FIFO_DEPTH - 1), 1'b0);
        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            do_read(8'h20 + i, 1'b0, (i == FIFO_DEPTH - 1));
        do_read(8'h20 + FIFO_DEPTH - 1, 1'b0, 1'b1); // Spurious read from empty
        finish_test_case("Drain Completely + Read-from-Empty Ignored");

        // Test 5: Simultaneous RW: Normal State 
        tc_failed = 0;
        apply_reset();
        for (i = 0; i < 8; i = i + 1)
            do_write(8'h30 + i, 8'h00, 1'b0, 1'b0);
        do_both(8'h40, 8'h30, 1'b0, 1'b0);
        do_both(8'h41, 8'h31, 1'b0, 1'b0);
        do_both(8'h42, 8'h32, 1'b0, 1'b0);
        do_both(8'h43, 8'h33, 1'b0, 1'b0);
        finish_test_case("Simultaneous RW: Normal State");

        // Test 6: Simultaneous RW: FIFO Empty 
        tc_failed = 0;
        apply_reset();
        do_both(8'hAB, 8'h00, 1'b0, 1'b0);  // Simultaneous RW on empty FIFO
        do_read(8'hAB, 1'b0, 1'b1);         // Read back newly written byte
        finish_test_case("Simultaneous RW: FIFO Empty");

        // Test 7: Simultaneous RW: FIFO Full 
        tc_failed = 0;
        apply_reset();
        for (i = 0; i < FIFO_DEPTH; i = i + 1)
            do_write(8'h50 + i, 8'h00, (i == FIFO_DEPTH - 1), 1'b0);
        do_both(8'hFF, 8'h50, 1'b0, 1'b0);  // Simultaneous RW on full FIFO
        do_read(8'h51, 1'b0, 1'b0);         // Confirm next item intact (0xFF was ignored)
        finish_test_case("Simultaneous RW: FIFO Full");

        // Summary Report 
        $display("\n%0d PASSED, %0d FAILED out of %0d tests.", passed, failed, passed + failed);

        $finish;
    end

endmodule