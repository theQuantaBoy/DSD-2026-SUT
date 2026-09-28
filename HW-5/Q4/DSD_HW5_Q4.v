// Module: d_ff
// Description: Custom D Flip-Flop with async active-low reset, sync clear, and enable
module d_ff (
    input wire clk,
    input wire rst_n,
    input wire sync_clr,
    input wire en_shift,
    input wire d,
    output reg  q
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin // active-low reset
            q <= 1'b0;
        end else if (sync_clr) begin
            q <= 1'b0;
        end else if (en_shift) begin
            q <= d;
        end
    end

endmodule

// Module: crc_datapath
// Description: Structural datapath for CRC-8-ATM polynomial P(x) = x^8 + x^2 + x + 1
module crc_datapath (
    input wire clk,
    input wire rst_n,
    input wire en_shift,
    input wire sync_clr,   // Fixed port name
    input wire data_in,
    output wire [7:0] crc_value
);

    // feedback bit
    wire feedback;
    assign feedback = data_in ^ crc_value[7];

    // next-state values
    wire [7:0] crc_next;

    assign crc_next[7] = crc_value[6];
    assign crc_next[6] = crc_value[5];
    assign crc_next[5] = crc_value[4];
    assign crc_next[4] = crc_value[3];
    assign crc_next[3] = crc_value[2];
    assign crc_next[2] = crc_value[1] ^ feedback;
    assign crc_next[1] = crc_value[0] ^ feedback;
    assign crc_next[0] = feedback;

    // Structural instantiation using named port connections
    d_ff dff0 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[0]), .q(crc_value[0]));
    d_ff dff1 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[1]), .q(crc_value[1]));
    d_ff dff2 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[2]), .q(crc_value[2]));
    d_ff dff3 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[3]), .q(crc_value[3]));
    d_ff dff4 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[4]), .q(crc_value[4]));
    d_ff dff5 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[5]), .q(crc_value[5]));
    d_ff dff6 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[6]), .q(crc_value[6]));
    d_ff dff7 (.clk(clk), .rst_n(rst_n), .sync_clr(sync_clr), .en_shift(en_shift), .d(crc_next[7]), .q(crc_value[7]));

endmodule

// crc_controller: Behavioral FSM controller for managing state transitions and timing
module crc_controller (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [15:0] msg_length,
    output reg en_shift,
    output reg sync_clr,
    output reg valid
);

    // FSM state encodings
    localparam IDLE  = 2'b00;
    localparam CLEAR = 2'b01;
    localparam SHIFT = 2'b10;
    localparam DONE  = 2'b11;

    reg [1:0]  state, next_state;
    reg [15:0] bit_cnt;

    // FSM state register & bit_cnt update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            bit_cnt <= 16'd0;
        end else begin
            state <= next_state;
            if (state == CLEAR) begin
                bit_cnt <= 16'd0;
            end else if (state == SHIFT) begin
                bit_cnt <= bit_cnt + 1'b1;
            end
        end
    end

    // next state
    always @(*) begin
        case (state)
            IDLE: begin
                if (start)
                    next_state = CLEAR;
                else
                    next_state = IDLE;
            end

            CLEAR: begin
                if (msg_length == 16'd0)
                    next_state = DONE;  // if length = 0, bypass SHIFT state
                else
                    next_state = SHIFT;
            end

            SHIFT: begin
                if (bit_cnt >= msg_length - 1'b1)
                    next_state = DONE;
                else
                    next_state = SHIFT;
            end

            DONE: begin
                next_state = IDLE;     // return to IDLE after 1 clock cycle
            end

            default: next_state = IDLE;
        endcase
    end

    // output control signals
    always @(*) begin
        sync_clr = 1'b0;
        en_shift = 1'b0;
        valid    = 1'b0;

        case (state)
            CLEAR: sync_clr = 1'b1;
            SHIFT: en_shift = 1'b1;
            DONE:  valid    = 1'b1;
            default: ;
        endcase
    end

endmodule

// Top-Level module integrating FSM controller and datapath
module crc8_top (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire data_in,
    input wire [15:0] msg_length,
    output wire [7:0] crc_out,
    output wire valid      // Fixed: separated from [7:0]
);

    // Internal Control Signals between Controller and Datapath
    wire en_shift;
    wire sync_clr;
    wire [7:0] crc_value;

    crc_controller controller_inst (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (start),
        .msg_length (msg_length),
        .en_shift   (en_shift),
        .sync_clr   (sync_clr),
        .valid      (valid)
    );

    crc_datapath datapath_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .en_shift (en_shift),
        .sync_clr (sync_clr),
        .data_in  (data_in),
        .crc_value(crc_out)
    );

endmodule