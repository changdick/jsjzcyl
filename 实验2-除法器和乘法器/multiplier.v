`timescale 1ns / 1ps

module multiplier (
    input  wire         clk,
	input  wire         rst,        // high active
	input  wire [31:0]  x,          // multiplicand
	input  wire [31:0]  y,          // multiplier
	input  wire         start,      // 1 - multiplication should begin
	output reg  [63:0]  z,          // product
	output reg          busy        // 1 - performing multiplication; 0 - multiplication ends
);

    // ****************************************************
    // Delete this block of code and write your own
//    reg [31:0] x_r, y_r;
//    always @(posedge clk or posedge rst) begin
//        busy <= rst ? 1'b0 : start;
//        if (start) begin
//            x_r <= x;
//            y_r <= y;
//        end
//    end
//    always @(*) z = $signed(x_r) * $signed(y_r);
    // ****************************************************



//     TODO
    reg [31:0] x_p;  //x 补码
    reg [31:0] x_m; //-x 补码
    reg [6:0] cnt; 
    reg k;
    
    // 储存x正负补码
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            x_p <= 0;
            x_m <= 0; 
        end
        else if(start) begin
            x_p <= x;
            x_m <= ~x+1'b1;
        end
    end
    // 计数器
    always @(posedge clk or posedge rst) begin
          if (rst)
            cnt <= 7'h7f;
        if(start)
            cnt <= 0;
        else if(cnt < 6'd32)
            cnt <= cnt + 1;
    end
    // busy
    always @(posedge clk or posedge rst) begin
        if(start || (cnt >= 0 && cnt < 6'd31))    // 之所以错是因为start信号置1后，busy没有下一周期马上跟成1导致的，只要start成为1，下一周期busy就得是1
            busy = 1'b1;
        else
            busy <= 0;
    end
    //z k
    always@(posedge clk or posedge rst) begin
        if(rst)begin
            z<=0;
            k<=0;
        end
        else if (start)begin
            z[31:0] <= y;
            z[63:32] <= 32'b0;
            k <= 1'b0;
        end
            
        else if(cnt < 6'd32) begin
            case({z[0],k})
                2'b00:;
                2'b01: z[63:32] = z[63:32] + x_p;
                2'b10: z[63:32] = z[63:32] + x_m;
                2'b11:;
            endcase
            k = z[0];
             
            z = {z[63],z[63:1]}; 
        end
    end
    
endmodule
