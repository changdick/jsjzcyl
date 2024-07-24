`timescale 1ns / 1ps

module divider (
    input  wire         clk,
    input  wire         rst,        // high active
    input  wire [31:0]  x,          // dividend
    input  wire [31:0]  y,          // divisor
    input  wire         start,      // 1 - division should begin
    output wire  [31:0]  z,          // quotient
    output wire  [31:0]  r,          // remainder
    output reg          busy        // 1 - performing division; 0 - division ends
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
//    always @(*) z = {x_r[31] ^ y_r[31], x_r[30:0] / y_r[30:0]};
//    always @(*) r = {x_r[31], x_r[30:0] % y_r[30:0]};
    // ****************************************************

    reg shangshang;
    always@(posedge clk or posedge rst) begin
        if(rst)
            shangshang <= 0;
        else if(cnt_end)
            shangshang <= 0;
        else if(busy)
            shangshang <= 1;
       
        
        
    end
 
     // 当start信号有效时，保存x和y的值到寄存器里面 ,扩展32位，这俩信号应该改成32位
     reg [31:0] dividend;
     reg [31:0] divisor;
     // d
	always @(posedge clk or posedge rst) begin
	   if(rst) 
	       divisor <= 0;
	    else if(start) 
	       divisor <= y;
	    else
	       divisor <= divisor;
	end
	
	always @(posedge clk or posedge rst) begin
	   if(rst) 
	       dividend <= 0;
	    else if(start) 
	       dividend <= x;
	    else
	       dividend <= dividend;
	end
	
	   // TODO
    // task1 如果要做除法，需要算出除数的正负补码来进行加减。需要做补码转换的工作，把除数原码送进去，输出【y*】补 和【-y*】补 做成一个器件，输出的两个信号就分别可以直接取用的【y*】补 和【-y*】补
    //      这是个简单的组合逻辑电路，输出两个wire 
   // 扩展32位，这两信号改32位，转补码的逻辑也应该改
    wire [31:0] divisor_p;
    wire [31:0] divisor_n;
         // 完成divisor转成两个补码信号
    assign divisor_p = {1'b0 , divisor[30:0]};            //[y*]补码
    assign divisor_n = {1'b1, ~divisor[30:0] + 1'b1};  // [-y*]补码
    
     
     // 计数器cnt， cnt_end 是计算结束的信号
     reg [5:0] cnt;
     wire cnt_end;
     assign cnt_end = (cnt == 31);
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
     

     
    
     
     // 存出部分余数，对8位的，应该存15位，因为被除数送7位上去，在补高8位。 扩展32位后，被除数送31位上去，再补32位。
     reg [62:0] remainder;   // 部分余数    
     
     wire op_sel;  //操作选择信号，直接绑定部分余数的最高位，如果为1，说明余数为负，部分余数的模块收到此信息，应当向左移位并加正数。商收到此信息，应该上商0
     assign op_sel = remainder[62];
    
    // 总是做 "先左移一位，然后加对应的数字"
 
     always @ (posedge clk or posedge rst) begin
        if(rst) 
            remainder <= 0;
        else if(start) 
            remainder <= {32'h00000000 ,x[30:0]};
        else if(busy && ~cnt_end) begin
            if(op_sel)
                remainder <= {remainder[61:0],1'b0}+{divisor_p,31'b0};
            else
                remainder <= {remainder[61:0],1'b0}+{divisor_n,31'b0};
      
             
            // 还需要做如果移位次数够的判断
            
        end
//        else if(cnt_end && remainder[13]==1'b1)
//            remainder <= remainder + {divisor_p,6'b0};
        else if(cnt_end)
            if(remainder[62]==1'b1)
                remainder <= remainder + {divisor_p,31'b0};
            else
                remainder <= remainder;
     end
     
    // 商寄存器 扩展到32位
     reg[31:0] shang;
     always@(posedge clk or posedge rst) begin
        if(rst)
            shang <= 0;
        else if(start) 
            shang <= 0;
        else 
            if(shangshang&& busy) 
                shang <= {shang[30:0],~op_sel};
     end
     
     assign z = {dividend[31] ^ divisor[31], shang[30:0]};
//     always @(posedge clk or posedge rst) begin
//        if(rst )
//            r <= 0;
//            //其实本来可以正确得到余数，就是时序上有一点问题，busy刚结束的时候，也就是cnt_end那个脉冲后，马上就得存好余数
            
//        else if (cnt_end && remainder[62]==1'b1) begin
           
//        end
//        else
//            r <={dividend[31], remainder[61:31]};
        
//     end

// 时序转不过来，干脆改成wire,还要从原码转成补码
    wire [31:0] r_temp;
    assign r_temp = {dividend[31], remainder[61:31]};
     
    assign r =r_temp;
    // TODO
    

endmodule
