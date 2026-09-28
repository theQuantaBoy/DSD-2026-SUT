`timescale 1ns / 1ps

module tb_traffic_light_controller;

    parameter GREEN_TIME   = 3;
    parameter YELLOW_TIME  = 1;
    parameter ALL_RED_TIME = 1;

    reg  clk, rst, start;
    wire ns_green, ns_yellow, ns_red;
    wire ew_green, ew_yellow, ew_red;

    integer passed, failed, test_num;
    integer cycle_count;

    traffic_light_controller #(
        .GREEN_TIME   (GREEN_TIME),
        .YELLOW_TIME  (YELLOW_TIME),
        .ALL_RED_TIME (ALL_RED_TIME)
    ) uut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .ns_green  (ns_green),
        .ns_yellow (ns_yellow),
        .ns_red    (ns_red),
        .ew_green  (ew_green),
        .ew_yellow (ew_yellow),
        .ew_red    (ew_red)
    );

    always #5 clk = ~clk;

    // Cycle counter (reset with rst)
    always @(posedge clk) begin
        if (rst) cycle_count <= 0;
        else     cycle_count <= cycle_count + 1;
    end

    // Per-cycle display + continuous safety assertions (combined block)
    // Runs every clock edge. #1 delay ensures NBA updates and combinatorial
    // signals have settled before reading.
    always @(posedge clk) begin
        #1;
        $display("  [Cycle %3d] NS=(G:%b Y:%b R:%b) | EW=(G:%b Y:%b R:%b)",
                 cycle_count,
                 ns_green, ns_yellow, ns_red,
                 ew_green, ew_yellow, ew_red);
        if (!rst) begin
            if (ns_green && ew_green)
                $display("  [SAFETY FAIL] Simultaneous greens at cycle %0d!", cycle_count);
            if ((ns_green + ns_yellow + ns_red) !== 1)
                $display("  [SAFETY FAIL] NS has %0d active lights at cycle %0d!",
                         ns_green + ns_yellow + ns_red, cycle_count);
            if ((ew_green + ew_yellow + ew_red) !== 1)
                $display("  [SAFETY FAIL] EW has %0d active lights at cycle %0d!",
                         ew_green + ew_yellow + ew_red, cycle_count);
        end
    end

    // Reference model + check task
    //
    // Takes an expected traffic phase and computes the expected 6-bit light
    // output from the specification rules, then compares against the DUT.
    //
    // Phase encoding:
    //   0 = SAFE / ALL_RED  -> both directions RED
    //   1 = NS_GREEN        -> NS green,  EW red
    //   2 = NS_YELLOW       -> NS yellow, EW red
    //   3 = EW_GREEN        -> NS red,    EW green
    //   4 = EW_YELLOW       -> NS red,    EW yellow
    task check_phase;
        input integer phase;
        reg exp_ns_g, exp_ns_y, exp_ns_r;
        reg exp_ew_g, exp_ew_y, exp_ew_r;
        begin
            test_num = test_num + 1;

            // Reference model: map expected phase -> expected light outputs
            exp_ns_g = 0; exp_ns_y = 0; exp_ns_r = 1; // default: both RED
            exp_ew_g = 0; exp_ew_y = 0; exp_ew_r = 1;
            case (phase)
                1: {exp_ns_g, exp_ns_y, exp_ns_r} = 3'b100; // NS GREEN
                2: {exp_ns_g, exp_ns_y, exp_ns_r} = 3'b010; // NS YELLOW
                3: {exp_ew_g, exp_ew_y, exp_ew_r} = 3'b100; // EW GREEN
                4: {exp_ew_g, exp_ew_y, exp_ew_r} = 3'b010; // EW YELLOW
            endcase

            if (ns_green === exp_ns_g && ns_yellow === exp_ns_y && ns_red === exp_ns_r &&
                ew_green === exp_ew_g && ew_yellow === exp_ew_y && ew_red === exp_ew_r) begin
                passed = passed + 1;
                $display("  [PASS] Check %0d: NS=(G:%b Y:%b R:%b) | EW=(G:%b Y:%b R:%b)",
                         test_num,
                         ns_green, ns_yellow, ns_red,
                         ew_green, ew_yellow, ew_red);
            end else begin
                failed = failed + 1;
                $display("  [FAIL] Check %0d:", test_num);
                $display("    Expected: NS=(G:%b Y:%b R:%b) | EW=(G:%b Y:%b R:%b)",
                         exp_ns_g, exp_ns_y, exp_ns_r, exp_ew_g, exp_ew_y, exp_ew_r);
                $display("    Got:      NS=(G:%b Y:%b R:%b) | EW=(G:%b Y:%b R:%b)",
                         ns_green, ns_yellow, ns_red, ew_green, ew_yellow, ew_red);
            end
            $display("  -----------------------------------------------");
        end
    endtask

    // Helper task: apply synchronous reset (active-high, 2 clock cycles)
    task apply_reset;
        begin
            rst   = 1'b1;
            start = 1'b0;
            repeat(2) @(posedge clk);
            #1;
            rst = 1'b0;
        end
    endtask

    initial begin
        clk         = 0;
        rst         = 1;
        start       = 0;
        passed      = 0;
        failed      = 0;
        test_num    = 0;
        cycle_count = 0;

        $dumpfile("DSD_HW5_Q2.vcd");
        $dumpvars(0, tb_traffic_light_controller);

        $display("\n=== Traffic Light Controller Testbench ===");
        $display("  GREEN_TIME=%0d | YELLOW_TIME=%0d | ALL_RED_TIME=%0d\n",
                 GREEN_TIME, YELLOW_TIME, ALL_RED_TIME);

        // Test 1: Synchronous Reset & Safe State
        // After rst is de-asserted, both directions must be RED.
        $display("--- Test 1: Synchronous Reset & Safe State ---");
        apply_reset();
        #2; // wait for per-cycle display block to finish first (+1ns), then check (+2ns)
        $display("  -> Expecting both RED after reset");
        check_phase(0);

        // Test 2: Safe State Hold (start = 0)
        // With start de-asserted, system must remain in safe state indefinitely.
        $display("\n--- Test 2: Safe State Hold (start=0) ---");
        repeat(5) @(posedge clk); #2;
        $display("  -> After 5 idle cycles; still expecting both RED");
        check_phase(0);

        // Test 3: Full Cyclic Operation (one complete NS <-> EW rotation)
        //
        // Timing rationale (two-process FSM, timer starts at 0):
        //   - 1 posedge  : SAFE -> NS_GREEN  (entry, timer=0)
        //   - GREEN_TIME  posedges: NS_GREEN (timer 0..GREEN_TIME-1) -> NS_YELLOW
        //   - YELLOW_TIME posedges: NS_YELLOW -> ALL_RED_1
        //   - ALL_RED_TIME posedges: ALL_RED_1 -> EW_GREEN
        //   - GREEN_TIME  posedges: EW_GREEN -> EW_YELLOW
        //   - YELLOW_TIME posedges: EW_YELLOW -> ALL_RED_2
        //   - ALL_RED_TIME posedges: ALL_RED_2 -> NS_GREEN (cycle repeats)
        $display("\n--- Test 3: Full Traffic Cycle (NS <-> EW rotation) ---");
        apply_reset();
        start = 1'b1;

        @(posedge clk); #2;
        $display("  -> SAFE to NS_GREEN");
        check_phase(1);

        repeat(GREEN_TIME) @(posedge clk); #2;
        $display("  -> NS_GREEN to NS_YELLOW");
        check_phase(2);

        repeat(YELLOW_TIME) @(posedge clk); #2;
        $display("  -> NS_YELLOW to ALL_RED (NS->EW transition)");
        check_phase(0);

        repeat(ALL_RED_TIME) @(posedge clk); #2;
        $display("  -> ALL_RED to EW_GREEN");
        check_phase(3);

        repeat(GREEN_TIME) @(posedge clk); #2;
        $display("  -> EW_GREEN to EW_YELLOW");
        check_phase(4);

        repeat(YELLOW_TIME) @(posedge clk); #2;
        $display("  -> EW_YELLOW to ALL_RED (EW->NS transition)");
        check_phase(0);

        repeat(ALL_RED_TIME) @(posedge clk); #2;
        $display("  -> ALL_RED to NS_GREEN (cycle repeats)");
        check_phase(1);

        // Test 4: De-asserting Start Mid-Cycle
        // The system must return to the safe state immediately when start=0,
        // regardless of the current FSM state.
        $display("\n--- Test 4: De-asserting Start Mid-Cycle ---");
        apply_reset();
        start = 1'b1;
        @(posedge clk);     // posedge 1: SAFE -> NS_GREEN
        @(posedge clk); #1; // posedge 2: NS_GREEN (timer=1); #1 steps past the edge
        start = 1'b0;       // de-assert clearly between posedge 2 and 3 (no race condition)
        @(posedge clk); #2; // posedge 3: start=0 sampled cleanly -> FSM returns to SAFE
        $display("  -> start de-asserted mid-cycle; expecting immediate return to SAFE");
        check_phase(0);

        // Test 5: Safety Assertions over 2 Full Cycles
        // The continuous always block checks on every posedge that:
        //   (ز) ns_green and ew_green are never simultaneously 1
        //   (ح) exactly one light is active per direction at all times
        // Any violation is printed inline. No violations = both properties hold.
        $display("\n--- Test 5: Safety Assertions over 2 Full Cycles ---");
        apply_reset();
        start = 1'b1;
        // 2 full cycles = 2 * 2 * (GREEN + YELLOW + ALL_RED) posedges
        repeat(2 * 2 * (GREEN_TIME + YELLOW_TIME + ALL_RED_TIME)) @(posedge clk);
        $display("  -> Safety check complete (violations, if any, shown above)");

        // Summary
        $display("\n=== %0d PASSED, %0d FAILED out of %0d explicit checks ===",
                 passed, failed, passed + failed);
        $finish;
    end

endmodule