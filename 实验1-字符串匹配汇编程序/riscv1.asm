.data
	str1:   .string "abcdefghijklmnop"
	str2:   .string "ijkd"

.macro push %a
	addi	sp, sp, -4
	sw 		%a, 0(sp) 
.end_macro

.macro pop %a
	lw 		%a, 0(sp) 
	addi	sp, sp, 4
.end_macro


.macro print %reg, %mode
    ori   a0, %reg, 0
    ori   a7, zero, %mode
    ecall
.end_macro


.text
MAIN:
    # 先准备参数，传参给a0和a1
    lui  a0, 0x10010
    lui  a1, 0x10010
    addi a1, a1, 17
    jal  ra, FIND_SUBSTRING      # Call a sub-routine.
    
    print a0 1 
    ori  a7, zero, 10        # Set system call number(10 for termination).
    ecall                    # This program terminates here. 这两句表示退出程序，必须有这两句。没有的话运行到打印后，我们认为程序出口到了，但是我实际上没有设置这个程序出口，就顺序往下运行了，就出错

# a0 返回值  
# 母串固定长度16， 子串固定长度4
# 只需要传两个参数到函数，只需要母串和子串的地址,分别用a0和a1来接收这两个参数 ，a2来存放pos，匹配不成功是-1.匹配成功就是下标
# i-a3  j-a4 i+j->a5 str[i+j]->a6  pattern[j]->a7  返回值pos先放着
# 知道j的值，要从子串基地址a1 先算出偏移量为j的地址 ，char占1个字节所以直接加j 
# str[i+j]的地址->s2 取出pattern[j]的地址->s3
# 母串的长度（16）放在s0 子串长度4 放在s1

# 使用的寄存器 a0 a1（参数和返回） a2 a3 a4 a5 a6 a7 s0(常数用于b指令) s1(存常数用于b指令) s2(&str[i+j]) s3（&pattern[j]） s4(存常数3用于b指令) 
FIND_SUBSTRING:
    
    push ra                 # 保护现场
    push s0
    push s1
    push s2
    push s3
    push s4
    push a2
    push a3
    push a4
    push a5
    push a6
    push a7
   
    addi s0, zero, 16
    addi s1, zero, 4
    addi s4, zero, 3
    addi a3, zero, 0         # i = 0
    addi a2, zero, -1        # pos默认-1
LOOP1:
    bge a3, s0, EXIT1        # 比较i与16的大小，判断是否退出循环
    addi a4, zero, 0         # j = 0
    LOOP2:
    bge a4, s1, EXIT2
    add a5, a3, a4           # i+j
    add s2, a0, a5           # &str[i+j]
    add s3, a1, a4           # &pattern[j]
    lb a6, 0(s2)             # str[i+j]
    lb a7, 0(s3)             # pattern[j]
    bne a6, a7, EXIT2        # 比较str[i+j]与 pattern[j]是否相等，如果不相等，这一次匹配就结束了，内层循环直接结束
    beq a4, s4, ELIF         # 比较j 是否是3， 如果是3，说明匹配成功，直接跳到ELIF，ELIF会保存i的值到a2，直接返回。如不是3，则内层循环继续进行
    addi a4, a4, 1           # j++
    jal zero LOOP2           # 跳转到LOOP2
    ELIF:
    add a2, a3, zero         # 如果运行到这句，就意味着匹配成功pos已经确定,是函数的出口，直接保存到a2寄存器，因此ELIF直接跳出外层循环
    jal zero, EXIT1          
    
    EXIT2:
    
    addi a3, a3, 1           # i++
    jal zero, LOOP1          # 此句跳转到LOOP1处
EXIT1:
    # 此时外层循环结束，寄存器a2里面要么是-1（匹配失败），要么是正确的匹配下标，但是希望用a0传回返回值
    add a0, a2, zero
    pop a7
    pop a6
    pop a5
    pop a4
    pop a3
    pop a2
    pop s4
    pop s3
    pop s2
    pop s1
    pop s0
    pop ra                   # 恢复现场
    jalr zero, 0(ra)         # The sub-routine returns.
    
 

