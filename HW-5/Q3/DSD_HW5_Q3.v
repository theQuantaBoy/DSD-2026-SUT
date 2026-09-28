module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input wire clk, rst,     
    input wire [DATA_WIDTH-1:0] din,     
    input wire wr_en, rd_en,
    output reg [DATA_WIDTH-1:0] dout,
    output wire full, empty
);

    // 2D Register Array for Circular Data Storage
    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    // Pointer registers for tracking read/write locations
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // Element Counter: requires (ADDR_WIDTH + 1) bits to store values from 0 to FIFO_DEPTH
    reg [ADDR_WIDTH:0] count;

    // Status Logic
    assign empty = (count == 0);
    assign full = (count == FIFO_DEPTH);

    // Synchronous FIFO State Machine & Memory Control
    always @(posedge clk) begin
        if (rst) begin
            // clear pointers, output registers, and counter
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            count  <= {(ADDR_WIDTH+1){1'b0}};
            dout   <= {DATA_WIDTH{1'b0}};
        end else begin
            // Write Operation
            if ((wr_en && !full) || (wr_en && rd_en && empty)) begin
                fifo_mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // Read Operation
            if ((rd_en && !empty) || (wr_en && rd_en && full)) begin
                dout <= fifo_mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Counter Logic
            case ({wr_en, rd_en})
                2'b10: if (!full)  count <= count + 1'b1; // Write only
                2'b01: if (!empty) count <= count - 1'b1; // Read only
                2'b11: begin // Simultaneous
                    if (empty) 
                        count <= count + 1'b1;
                    else if (full)
                        count <= count - 1'b1;
                end
                default: ;
            endcase
        end
    end

endmodule