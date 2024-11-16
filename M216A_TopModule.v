`timescale 1ns / 100ps

//Do NOT Modify This Module
module P1_Reg_8_bit (DataIn, DataOut, rst, clk);

    input [7:0] DataIn;
    output [7:0] DataOut;
    input rst;
    input clk;
    reg [7:0] DataReg;
   
    always @(posedge clk)
  	if(rst)
            DataReg <= 8'b0;
        else
            DataReg <= DataIn;
    assign DataOut = DataReg;
endmodule

//Do NOT Modify This Module
module P1_Reg_5_bit (DataIn, DataOut, rst, clk);

    input [4:0] DataIn;
    output [4:0] DataOut;
    input rst;
    input clk;
    reg [4:0] DataReg;
    
    always @(posedge clk)
        if(rst)
            DataReg <= 5'b0;
        else
            DataReg <= DataIn;
    assign DataOut = DataReg;
endmodule

//Do NOT Modify This Module
module P1_Reg_4_bit (DataIn, DataOut, rst, clk);

    input [3:0] DataIn;
    output [3:0] DataOut;
    input rst;
    input clk;
    reg [3:0] DataReg;
    
    always @(posedge clk)
        if(rst)
            DataReg <= 4'b0;
        else
            DataReg <= DataIn;
    assign DataOut = DataReg;
endmodule

//Do NOT Modify This Module's I/O Definition
module M216A_TopModule(
    clk_i,
    width_i,
    height_i,
    index_x_o,
    index_y_o,
    strike_o,
    rst_i
);

input clk_i;
input [4:0] width_i;
input [4:0] height_i;
output [7:0] index_x_o;
output [7:0] index_y_o;
output [3:0] strike_o;
input rst_i;

wire [4:0] width;
wire [4:0] height;
reg [7:0] idx_x, idx_x_reg;
reg [7:0] idx_y, idx_y_reg;
reg [3:0] strike;


always@(posedge clk_i) begin
    idx_x <= idx_x_reg;
    idx_y <= idx_y_reg;
end

P1_Reg_5_bit i_width(
    .clk(clk_i),
    .rst(rst_i),
    .DataIn(width_i),
    .DataOut(width));
P1_Reg_5_bit i_height(
    .clk(clk_i),
    .rst(rst_i),
    .DataIn(height_i),
    .DataOut(height));
P1_Reg_4_bit i_strike(
    .clk(clk_i),
    .rst(rst_i),
    .DataIn(strike),
    .DataOut(strike_o));
P1_Reg_8_bit i_x(
    .clk(clk_i),
    .rst(rst_i),
    .DataIn(idx_x),
    .DataOut(index_x_o));
P1_Reg_8_bit i_y(
    .clk(clk_i),
    .rst(rst_i),
    .DataIn(idx_y),
    .DataOut(index_y_o));

reg [4:0] width_reg;

reg [7:0] free_index [0:12];
reg space_avail;
reg [1:0] state;

reg [7:0] height_map;
reg [7:0] height_map_reg;
reg [2:0][3:0] get_idx;

reg [2:0] compare;
reg [3:0] best_strip;
reg [7:0] rd_free_idx;

reg [7:0] idx_x_pipe;
reg [7:0] idx_y_pipe;

reg first_loop;
reg first_loop_reg;


integer i;
always@(posedge clk_i) begin
    if (rst_i) begin
        for (i = 0; i < 13; i=i+1) begin
            free_index[i] <= 8'd0;
        end
        state       <= 2'd0;
        space_avail <= 1'b0;
        strike      <= 4'd14;
        first_loop  <= 2'd3;
        rd_free_idx <= 8'd0;
        idx_x_reg   <= 8'd0;
        idx_y_reg   <= 8'd0;
        height_map_reg <= 8'd0;
    end else begin
        state <= first_loop_reg ? 2'd0 : state+1;
        first_loop <= 1'b0;

        case(state)
            2'd0: begin
                idx_y_pipe <= height_map_reg;
                strike <= strike + !space_avail;
                if (space_avail) begin
                    free_index[best_strip] <= rd_free_idx + width_reg;
                end
            end
            2'd1: begin
                idx_x_reg <= space_avail ? rd_free_idx : 128;
                idx_y_reg <= space_avail ? idx_y_pipe : 128;
                space_avail <= free_index[get_idx[0]] + width <= 128;
            end
            2'd2: begin
                space_avail <= (free_index[get_idx[1]] + width <= 128) || space_avail;
            end
            2'd3: begin
                space_avail <= (free_index[get_idx[2]] + width <= 128) || space_avail;
                rd_free_idx <= free_index[best_strip];
                height_map_reg <= height_map;
            end
        endcase
    end
end

always@(posedge clk_i) begin
    compare[0] <= free_index[get_idx[2]] < free_index[get_idx[0]];
    compare[1] <= free_index[get_idx[1]] < free_index[get_idx[0]];
    compare[2] <= free_index[get_idx[2]] < free_index[get_idx[1]];
    
    case({compare[2:1]})
        2'b00: best_strip <= get_idx[0];
        2'b01: best_strip <= compare[2] ? get_idx[2] : get_idx[1];
        2'b10: best_strip <= compare[0] ? get_idx[2] : get_idx[0];
        2'b11: best_strip <= get_idx[2];
    endcase

    first_loop_reg <= first_loop;
    height_map_reg <= height_map;
    width_reg      <= width;
end

always@(*) begin
    case(best_strip)
        0: height_map = 0;
        1: height_map = 8;
        2: height_map = 16;
        3: height_map = 25;
        4: height_map = 32;
        5: height_map = 42;
        6: height_map = 48;
        7: height_map = 59;
        8: height_map = 64;
        9: height_map = 76;
        10: height_map = 80;
        11: height_map = 96;
        default: height_map = 112;
    endcase
    case(height)
        4: get_idx = {4'd7, 4'd7, 4'd9};
        5: get_idx = {4'd5, 4'd5, 4'd7};
        6: get_idx = {4'd3, 4'd3, 4'd5};
        7: get_idx = {4'd1, 4'd0, 4'd3};
        8: get_idx = {4'd2, 4'd1, 4'd0};
        9: get_idx = {4'd4, 4'd4, 4'd2};
        10: get_idx = {4'd6, 4'd6, 4'd4};
        11: get_idx = {4'd8, 4'd8, 4'd6};
        12: get_idx = {4'd8, 4'd8, 4'd8};
        default: get_idx = {4'd10, 4'd11, 4'd12};
    endcase
end

endmodule
