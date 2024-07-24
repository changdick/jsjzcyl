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
 
     // ��start�ź���Чʱ������x��y��ֵ���Ĵ������� ,��չ32λ�������ź�Ӧ�øĳ�32λ
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
    // task1 ���Ҫ����������Ҫ����������������������мӼ�����Ҫ������ת���Ĺ������ѳ���ԭ���ͽ�ȥ�������y*���� �͡�-y*���� ����һ������������������źžͷֱ����ֱ��ȡ�õġ�y*���� �͡�-y*����
    //      ���Ǹ��򵥵�����߼���·���������wire 
   // ��չ32λ�������źŸ�32λ��ת������߼�ҲӦ�ø�
    wire [31:0] divisor_p;
    wire [31:0] divisor_n;
         // ���divisorת�����������ź�
    assign divisor_p = {1'b0 , divisor[30:0]};            //[y*]����
    assign divisor_n = {1'b1, ~divisor[30:0] + 1'b1};  // [-y*]����
    
     
     // ������cnt�� cnt_end �Ǽ���������ź�
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
     

     
    
     
     // ���������������8λ�ģ�Ӧ�ô�15λ����Ϊ��������7λ��ȥ���ڲ���8λ�� ��չ32λ�󣬱�������31λ��ȥ���ٲ�32λ��
     reg [62:0] remainder;   // ��������    
     
     wire op_sel;  //����ѡ���źţ�ֱ�Ӱ󶨲������������λ�����Ϊ1��˵������Ϊ��������������ģ���յ�����Ϣ��Ӧ��������λ�������������յ�����Ϣ��Ӧ������0
     assign op_sel = remainder[62];
    
    // ������ "������һλ��Ȼ��Ӷ�Ӧ������"
 
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
      
             
            // ����Ҫ�������λ���������ж�
            
        end
//        else if(cnt_end && remainder[13]==1'b1)
//            remainder <= remainder + {divisor_p,6'b0};
        else if(cnt_end)
            if(remainder[62]==1'b1)
                remainder <= remainder + {divisor_p,31'b0};
            else
                remainder <= remainder;
     end
     
    // �̼Ĵ��� ��չ��32λ
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
//            //��ʵ����������ȷ�õ�����������ʱ������һ�����⣬busy�ս�����ʱ��Ҳ����cnt_end�Ǹ���������Ͼ͵ô������
            
//        else if (cnt_end && remainder[62]==1'b1) begin
           
//        end
//        else
//            r <={dividend[31], remainder[61:31]};
        
//     end

// ʱ��ת���������ɴ�ĳ�wire,��Ҫ��ԭ��ת�ɲ���
    wire [31:0] r_temp;
    assign r_temp = {dividend[31], remainder[61:31]};
     
    assign r =r_temp;
    // TODO
    

endmodule
