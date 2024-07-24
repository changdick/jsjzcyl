`timescale 1ns / 1ps

module divider (
    input  wire       clk,  // 时钟信号
    input  wire       rst,  //复位信号高电平有效
    input  wire [7:0] x,    //被除数 原码
    input  wire [7:0] y,    // 除数 源码
    input  wire       start,  //启动信号
    output wire [7:0] z,    // 商 原码
    output wire  [7:0] r,    //余数 原码
    output reg        busy  // 忙标志信号
);
  // 第一次移位减除数，不会上商，所以专门设一个标记位，让上商晚一个周期开始
    reg shangshang;
    always@(posedge clk or posedge rst) begin
        if(rst)
            shangshang <= 0;
        else if(busy)
            shangshang <= 1;
        else if(cnt_end)
            shangshang <= 0;
        
        
    end
 
     // 当start信号有效时，保存x和y的值到寄存器里面
     reg [7:0] dividend;
     reg [7:0] divisor;
     
	always @(posedge clk or posedge rst) begin
	   if(rst) 
	       divisor <= 8'h00;
	    else if(start) 
	       divisor <= y;
	    else
	       divisor <= divisor;
	end
	
	always @(posedge clk or posedge rst) begin
	   if(rst) 
	       dividend <= 8'h00;
	    else if(start) 
	       dividend <= x;
	    else
	       dividend <= dividend;
	end
	
	   // TODO
    // task1 如果要做除法，需要算出除数的正负补码来进行加减。需要做补码转换的工作，把除数原码送进去，输出【y*】补 和【-y*】补 做成一个器件，输出的两个信号就分别可以直接取用的【y*】补 和【-y*】补
    //      这是个简单的组合逻辑电路， 输入两个wire，输出两个wire 
   
    wire [7:0] divisor_p;
    wire [7:0] divisor_n;
    divisor_complements div2comp(
            .divisor(divisor),
            .divisor_abs(divisor_p),
            .divisor_minus(divisor_n)
     );
     
     // 计数器cnt， cnt_end 是计算结束的信号
     reg [2:0] cnt;
     wire cnt_end;
     assign cnt_end = (cnt == 7);
     always @ (posedge clk or posedge rst) begin
        if(rst) 
            cnt <= 0;
          
        else if(start) 
            cnt <= 0;
        else if(cnt_end)
            cnt <= 0;
        else if(busy)
            cnt <= cnt + 1;
         
     end
     
     always @ (posedge clk or posedge rst) begin
        if(rst) 
            busy <= 0;
        else if(start) 
            busy <= 1;
        else if(cnt_end)
            busy <= 0;
     end     
     

     
    
     
     
     reg [14:0] remainder;   // 部分余数
     
     wire op_sel;  //操作选择信号，直接绑定部分余数的最高位，如果为1，说明余数为负，部分余数的模块收到此信息，应当向左移位并加正数。商收到此信息，应该上商0
     assign op_sel = remainder[14];
    
    // 总是做 “先左移一位，然后加对应的数字”
 
     always @ (posedge clk or posedge rst) begin
        if(rst) 
            remainder <= 0;
        else if(start) 
            remainder <= {8'h00 ,x[6:0]};
        else if(busy && ~cnt_end) begin
            if(op_sel)
                remainder <= {remainder[13:0],1'b0}+{divisor_p,7'b0};
            else
                remainder <= {remainder[13:0],1'b0}+{divisor_n,7'b0};
             
            // 还需要做如果移位次数够的判断
            
        end
//        else if(cnt_end && remainder[13]==1'b1)
//            remainder <= remainder + {divisor_p,6'b0};
        else if(cnt_end)
            if(remainder[14]==1'b1)
                remainder <= remainder + {divisor_p,7'b0};
     end
     
    
     reg[7:0] shang;
     always@(posedge clk or posedge rst) begin
        if(rst)
            shang <= 0;
        else if(start) 
            shang <= 0;
        else 
            if(shangshang&& busy) 
                shang <= {shang[6:0],~op_sel};
     end
     
     assign z = {dividend[7] ^ divisor[7], shang[6:0]};
//     always @(posedge clk or posedge rst) begin
//        if(rst )
//            r <= 0;
//        else
//            r <={dividend[7], remainder[13:7]};
        
//     end
        assign r = {dividend[7], remainder[13:7]};

     
endmodule
