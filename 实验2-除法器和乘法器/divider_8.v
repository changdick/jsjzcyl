`timescale 1ns / 1ps

module divider (
    input  wire       clk,  // ʱ���ź�
    input  wire       rst,  //��λ�źŸߵ�ƽ��Ч
    input  wire [7:0] x,    //������ ԭ��
    input  wire [7:0] y,    // ���� Դ��
    input  wire       start,  //�����ź�
    output wire [7:0] z,    // �� ԭ��
    output wire  [7:0] r,    //���� ԭ��
    output reg        busy  // æ��־�ź�
);
  // ��һ����λ���������������̣�����ר����һ�����λ����������һ�����ڿ�ʼ
    reg shangshang;
    always@(posedge clk or posedge rst) begin
        if(rst)
            shangshang <= 0;
        else if(busy)
            shangshang <= 1;
        else if(cnt_end)
            shangshang <= 0;
        
        
    end
 
     // ��start�ź���Чʱ������x��y��ֵ���Ĵ�������
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
    // task1 ���Ҫ����������Ҫ����������������������мӼ�����Ҫ������ת���Ĺ������ѳ���ԭ���ͽ�ȥ�������y*���� �͡�-y*���� ����һ������������������źžͷֱ����ֱ��ȡ�õġ�y*���� �͡�-y*����
    //      ���Ǹ��򵥵�����߼���·�� ��������wire���������wire 
   
    wire [7:0] divisor_p;
    wire [7:0] divisor_n;
    divisor_complements div2comp(
            .divisor(divisor),
            .divisor_abs(divisor_p),
            .divisor_minus(divisor_n)
     );
     
     // ������cnt�� cnt_end �Ǽ���������ź�
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
     

     
    
     
     
     reg [14:0] remainder;   // ��������
     
     wire op_sel;  //����ѡ���źţ�ֱ�Ӱ󶨲������������λ�����Ϊ1��˵������Ϊ��������������ģ���յ�����Ϣ��Ӧ��������λ�������������յ�����Ϣ��Ӧ������0
     assign op_sel = remainder[14];
    
    // ������ ��������һλ��Ȼ��Ӷ�Ӧ�����֡�
 
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
             
            // ����Ҫ�������λ���������ж�
            
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
