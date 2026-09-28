module traffic_light (
    input wire [1:0] light_state, // 2'b00: Red, 2'b01: Yellow, 2'b10: Green
    output reg green, output reg yellow, output reg red
);
    always @(*) begin
        case (light_state)
            2'b10: begin   // GREEN
                green  = 1'b1;
                yellow = 1'b0;
                red    = 1'b0;
            end
            2'b01: begin   // YELLOW
                green  = 1'b0;
                yellow = 1'b1;
                red    = 1'b0;
            end
            default: begin // RED (default state)
                green  = 1'b0;
                yellow = 1'b0;
                red    = 1'b1;
            end
        endcase
    end
endmodule


module traffic_light_controller #(
    parameter GREEN_TIME   = 10,
    parameter YELLOW_TIME  = 3,
    parameter ALL_RED_TIME = 2
)(
    input  wire clk, rst, start,
    output wire ns_green, ns_yellow, ns_red,
    output wire ew_green, ew_yellow, ew_red
);

    // FSM State Encodings
    localparam [2:0] STATE_SAFE      = 3'd0; // Safe State (both RED)
    localparam [2:0] STATE_NS_GREEN  = 3'd1; // North-South Green, East-West Red
    localparam [2:0] STATE_NS_YELLOW = 3'd2; // North-South Yellow, East-West Red
    localparam [2:0] STATE_ALL_RED_1 = 3'd3; // All Red (NS->EW Transition)
    localparam [2:0] STATE_EW_GREEN  = 3'd4; // East-West Green, North-South Red
    localparam [2:0] STATE_EW_YELLOW = 3'd5; // East-West Yellow, North-South Red
    localparam [2:0] STATE_ALL_RED_2 = 3'd6; // All Red (EW->NS Transition)

    // Internal Registers
    reg [2:0]  current_state, next_state;
    reg [15:0] timer;

    // 2-Bit light command signals: 2'b00=RED | 2'b01=YELLOW | 2'b10=GREEN
    reg [1:0] ns_light_state;
    reg [1:0] ew_light_state;

    // Sequential Block: State Register + Timer ONLY
    // Registers next_state on every posedge; resets timer on any state change.
    always @(posedge clk) begin
        if (rst) begin
            current_state <= STATE_SAFE;
            timer         <= 16'd0;
        end else begin
            if (current_state != next_state) begin
                current_state <= next_state;
                timer         <= 16'd0; // Reset timer on every state transition
            end else begin
                timer <= timer + 1'b1;
            end
        end
    end

    // Combinatorial Block: Next-State Logic + Light Output Commands
    // De-asserting start forces a return to STATE_SAFE from any state.
    always @(*) begin
        // Defaults: hold state, both directions RED
        next_state     = current_state;
        ns_light_state = 2'b00; // RED
        ew_light_state = 2'b00; // RED

        if (!start) begin
            next_state = STATE_SAFE; // Return to safe state whenever start=0
        end else begin
            case (current_state)
                STATE_SAFE: begin
                    // Both lights RED (default above); immediately advance on start
                    next_state = STATE_NS_GREEN;
                end

                STATE_NS_GREEN: begin
                    ns_light_state = 2'b10; // GREEN
                    ew_light_state = 2'b00; // RED
                    if (timer >= GREEN_TIME - 1)
                        next_state = STATE_NS_YELLOW;
                end

                STATE_NS_YELLOW: begin
                    ns_light_state = 2'b01; // YELLOW
                    ew_light_state = 2'b00; // RED
                    if (timer >= YELLOW_TIME - 1) begin
                        // Skip ALL_RED_1 if ALL_RED_TIME=0 to avoid a phantom cycle
                        if (ALL_RED_TIME > 0)
                            next_state = STATE_ALL_RED_1;
                        else
                            next_state = STATE_EW_GREEN;
                    end
                end

                STATE_ALL_RED_1: begin
                    // Both lights RED (default above)
                    if (timer >= ALL_RED_TIME - 1)
                        next_state = STATE_EW_GREEN;
                end

                STATE_EW_GREEN: begin
                    ns_light_state = 2'b00; // RED
                    ew_light_state = 2'b10; // GREEN
                    if (timer >= GREEN_TIME - 1)
                        next_state = STATE_EW_YELLOW;
                end

                STATE_EW_YELLOW: begin
                    ns_light_state = 2'b00; // RED
                    ew_light_state = 2'b01; // YELLOW
                    if (timer >= YELLOW_TIME - 1) begin
                        // Skip ALL_RED_2 if ALL_RED_TIME=0 to avoid a phantom cycle
                        if (ALL_RED_TIME > 0)
                            next_state = STATE_ALL_RED_2;
                        else
                            next_state = STATE_NS_GREEN;
                    end
                end

                STATE_ALL_RED_2: begin
                    // Both lights RED (default above)
                    if (timer >= ALL_RED_TIME - 1)
                        next_state = STATE_NS_GREEN;
                end

                default: next_state = STATE_SAFE;
            endcase
        end
    end

    traffic_light ns_light_inst (
        .light_state (ns_light_state),
        .green       (ns_green),
        .yellow      (ns_yellow),
        .red         (ns_red)
    );

    traffic_light ew_light_inst (
        .light_state (ew_light_state),
        .green       (ew_green),
        .yellow      (ew_yellow),
        .red         (ew_red)
    );

endmodule