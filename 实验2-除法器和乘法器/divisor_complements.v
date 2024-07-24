`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/05/23 17:07:40
// Design Name: 
// Module Name: divisor_complements
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module divisor_complements(

    input wire [7:0] divisor,          // ������ԭ��
    output [7:0] divisor_abs,              // �����ľ���ֵ�Ĳ���
    output [7:0] divisor_minus             // �����ľ���ֵ�ĸ����Ĳ���
    );
    
    // ���divisorת�����������ź�
    assign divisor_abs = {1'b0 , divisor[6:0]};            //[y*]����
    assign divisor_minus = {1'b1, ~divisor[6:0] + 1'b1};  // [-y*]����
    
    
endmodule
