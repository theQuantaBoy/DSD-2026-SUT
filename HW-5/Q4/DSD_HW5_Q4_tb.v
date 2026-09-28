`timescale 1ns / 1ps

module tb_crc8_top;

    // Signal Declarations
    reg        clk;
    reg        rst_n;
    reg        start;
    reg        data_in;
    reg [15:0] msg_length;

    wire [7:0] crc_out;
    wire       valid;

    // Testbench Variables
    integer passed, failed, test_num;

    // Unit Under Test (UUT) Instantiation using named port connections
    crc8_top uut (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .data_in    (data_in),
        .msg_length (msg_length),
        .crc_out    (crc_out),
        .valid      (valid)
    );

    // Clock Generation: 10ns period (100 MHz)
    always #5 clk = ~clk;

    // Software Reference Model for CRC-8-ATM (P(x) = x^8 + x^2 + x + 1)
    function [7:0] calc_crc_bit;
        input [7:0] crc_curr;
        input       bit_in;
        reg         feedback;
        begin
            feedback        = bit_in ^ crc_curr[7];
            calc_crc_bit[7] = crc_curr[6];
            calc_crc_bit[6] = crc_curr[5];
            calc_crc_bit[5] = crc_curr[4];
            calc_crc_bit[4] = crc_curr[3];
            calc_crc_bit[3] = crc_curr[2];
            calc_crc_bit[2] = crc_curr[1] ^ feedback;
            calc_crc_bit[1] = crc_curr[0] ^ feedback;
            calc_crc_bit[0] = feedback;
        end
    endfunction

    function [7:0] calc_crc_stream;
        input [127:0] msg_data;
        input [15:0]  len;
        integer i;
        reg [7:0] crc_temp;
        begin
            crc_temp = 8'h00; // Initial CRC seed
            for (i = len - 1; i >= 0; i = i - 1)
                crc_temp = calc_crc_bit(crc_temp, msg_data[i]);
            calc_crc_stream = crc_temp;
        end
    endfunction

    // Test Driver Task
    task run_crc_test;
        input [127:0] msg_data;
        input [15:0]  len;
        input         trigger_busy_start;

        reg [7:0] exp_crc;
        reg [7:0] ref_crc; // Running expected CRC for per-bit trace
        integer i;
        begin
            test_num = test_num + 1;
            exp_crc  = calc_crc_stream(msg_data, len);

            // Assert start for one cycle
            start      = 1'b1;
            msg_length = len;
            data_in    = 1'b0;
            @(posedge clk);
            start = 1'b0; // Start pulse lasts exactly 1 clock cycle

            // CLEAR state completes on this edge (CRC register zeroed, counter reset)
            @(posedge clk);

            // SHIFT phase: stream bits MSB-first, print per-bit trace
            if (len > 0) begin
                ref_crc = 8'h00; // Mirrors the CLEAR state initial value
                $display("  --- SHIFT trace: %0d bit(s), MSB-first ---", len);
                $display("  %-9s  %-9s  %-20s  %-20s",
                         "Bit", "data_in", "crc_reg (DUT)", "crc_reg (expected)");

                for (i = len - 1; i >= 0; i = i - 1) begin
                    data_in = msg_data[i];

                    // Inject start mid-stream if busy-handling test is requested
                    if (trigger_busy_start && (i == len / 2))
                        start = 1'b1;
                    else
                        start = 1'b0;

                    @(posedge clk);
                    #1; // Let non-blocking assignments settle

                    ref_crc = calc_crc_bit(ref_crc, msg_data[i]);
                    $display("  [Bit %3d]    %b         0x%02h                  0x%02h%s",
                             len - 1 - i, data_in, crc_out, ref_crc,
                             (crc_out !== ref_crc) ? "   <<< MISMATCH" : "");
                end
                start   = 1'b0;
                data_in = 1'b0;
            end

            #1; // Settling delay before sampling DONE state

            // DONE state: validate CRC output value and valid pulse duration
            if (valid === 1'b1 && crc_out === exp_crc) begin
                @(posedge clk);
                #1; // Settle into IDLE
                if (valid === 1'b0) begin
                    passed = passed + 1;
                    $display("[PASS] Test %0d: Msg=0x%h, Len=%0d bits | CRC=0x%02h (Exp=0x%02h), Valid=1-cycle",
                             test_num, msg_data, len, crc_out, exp_crc);
                end else begin
                    failed = failed + 1;
                    $display("[FAIL] Test %0d: Valid remained HIGH for >1 clock cycle!", test_num);
                end
            end else begin
                failed = failed + 1;
                $display("[FAIL] Test %0d: Msg=0x%h, Len=%0d bits", test_num, msg_data, len);
                $display("       Expected: CRC=0x%02h, valid=1", exp_crc);
                $display("       Got:      CRC=0x%02h, valid=%0b", crc_out, valid);
            end
            $display("------------------------------------------------------------");
        end
    endtask

    // Main Test Sequence
    initial begin
        // Initialize Signals
        clk        = 0;
        rst_n      = 0;
        start      = 0;
        data_in    = 0;
        msg_length = 0;
        passed     = 0;
        failed     = 0;
        test_num   = 0;

        // Waveform Dump Setup
        $dumpfile("DSD_HW5_Q4.vcd");
        $dumpvars(0, tb_crc8_top);

        $display("\n=== Serial CRC-8 Calculator Testbench ===");

        // Apply async reset
        #15;
        @(posedge clk);
        rst_n = 1; // Release async reset
        @(posedge clk);

        // Test 1: Asynchronous Active-Low Reset
        // Drop rst_n mid-cycle; DUT outputs must respond immediately
        // without waiting for the next clock edge.
        test_num = test_num + 1;
        rst_n = 0; #2; // Assert mid-cycle (asynchronous)
        if (valid === 1'b0 && crc_out === 8'h00) begin
            passed = passed + 1;
            $display("[PASS] Test %0d (Async Reset): crc_out=0x%02h, valid=%0b",
                     test_num, crc_out, valid);
        end else begin
            failed = failed + 1;
            $display("[FAIL] Test %0d (Async Reset): Expected crc_out=0x00, valid=0 | Got crc_out=0x%02h, valid=%0b",
                     test_num, crc_out, valid);
        end
        $display("------------------------------------------------------------");
        rst_n = 1;
        @(posedge clk);

        // Test 2: Zero Message Length
        // FSM must bypass SHIFT and go CLEAR -> DONE with CRC = 0x00.
        $display("Test 2: length_msg = 0  (boundary: CLEAR->DONE, CRC = 0x00)");
        run_crc_test(128'h0, 16'd0, 1'b0);

        // Test 3: Single-Bit Message  [boundary: minimum non-zero length]
        // bit = 1, MSB-first -> only one SHIFT cycle executes.
        $display("Test 3: Single-bit message, bit=1  (boundary: length = 1)");
        run_crc_test(128'h1, 16'd1, 1'b0);

        // Test 4: Standard 8-bit message 0xA5
        $display("Test 4: Msg=0xA5, Len=8 bits");
        run_crc_test(128'hA5, 16'd8, 1'b0);

        // Test 5: 16-bit message 0x1234  (different length from Test 4)
        $display("Test 5: Msg=0x1234, Len=16 bits");
        run_crc_test(128'h1234, 16'd16, 1'b0);

        // Test 6: 24-bit message 0x8D2F31  (third distinct length)
        $display("Test 6: Msg=0x8D2F31, Len=24 bits");
        run_crc_test(128'h8D2F31, 16'd24, 1'b0);

        // Test 7: Busy Protection — re-assert start mid-stream
        // FSM must ignore start in CLEAR/SHIFT/DONE states; final CRC
        // must be identical to the uninterrupted calculation.
        $display("Test 7: Busy protection — start re-asserted mid-stream (Msg=0x3B1A, Len=16)");
        run_crc_test(128'h3B1A, 16'd16, 1'b1);

        // Test 8: Consecutive Execution — circuit must return to IDLE
        // and accept a new message immediately after DONE.
        $display("Test 8: Consecutive message (Msg=0xFF00, Len=16)");
        run_crc_test(128'hFF00, 16'd16, 1'b0);

        // Final Summary
        $display("\n%0d PASSED, %0d FAILED out of %0d tests.", passed, failed, passed + failed);
        $finish;
    end

endmodule