`timescale 1ns / 1ps

// `define BLK_LEN  4
// `define BLK_SIZE (`BLK_LEN*32)

module ICache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU  对cpu是只读的
    input  wire         inst_rreq,      // 来自CPU的取指请求
    input  wire [31:0]  inst_addr,      // 来自CPU的取指地址
    output reg          inst_valid,     // 输出给CPU的指令有效信号（读指令命中）
    output reg  [31:0]  inst_out,       // 输出给CPU的指令
    // Interface to Read Bus
    input  wire         mem_rrdy,       // 主存就绪信号（高电平表示主存可接收ICache的读请求）
    output reg  [ 3:0]  mem_ren,        // 输出给主存的读使能信号
    output reg  [31:0]  mem_raddr,      // 输出给主存的读地址
    input  wire         mem_rvalid,     // 来自主存的数据有效信号
    input  wire [`BLK_SIZE-1:0] mem_rdata   // 来自主存的读数据
);

`ifdef ENABLE_ICACHE    /******** 不要修改此行代码 ********/

// author 220110430
// 经计算，由于cache1kB， 主存32kb，主存直接映射到cache分成32个区，所以区号（tag）编32个，用5bit就可以
// 经计算，cache是1kB，每个块是4个字（32位=1字），所以64个块， 块号编码要6bit。一个块里面4个字，本实验数据单元均为32位字，所以块内地址编码2bit
// 经计算, 主存地址需要的三个内容：区号（tag）、块号、块内地址分别是5、6、2，总共用上13位， 主存地址32位，好像只需要用低13位。
// 经计算， cache一个块是4*32bit = 128bit，实际要做扩展，加上valid位和区号（tag）用于验证是否命中（即用于生产hit信号），所以1+5+128实际134bit，作为一个cache块。这样的134bit的cache块，放在cache存储体里面。
// 因此，cache存储体那边，写入写出信号，位宽134bit。 用于访问cache存储体的，其实是cache的块地址不含块内地址。也就是主存的块号的6bit
// [31:0]  inst_addr, cpu送来的主存地址    [1:0]-块内地址  [7:2]-块号（块地址）  [12:8]-区号(tag)，  【31：8】都可以理解成区号，但是接入给到cache块当tag域的是5bit

// @author 220110430
// 运行的逻辑：用块号作为cache存储体的寻址，从cache存储体取出cache块。再用mux选择，以块内偏移地址（2bit）作为选择信号，选择cache数据块中的某一个数据单元作为输出data。 同时cache块的高6位分别是valid位
// 以及tag，用于和主存的区号(tag)生成hit信号。 这些都是组合逻辑完成  

// 2024/6/5 
    wire [4:0] tag_from_cpu   = inst_addr[14:10];    // 主存地址的TAG
    wire [1:0] offset         = inst_addr[3:2];    // 32位字偏移量
    wire       valid_bit      = cache_line_r[133];    // Cache行的有效位
    wire [4:0] tag_from_cache = cache_line_r[132:128];    // Cache行的TAG

    // 定义ICache状态机的状态变量
    reg [1:0] current_state;        // 现态
    reg [1:0] next_state;           // 次态
    localparam IDLE = 2'b00;
    localparam TAG_CHECK = 2'b01;
    localparam REFILL = 2'b11;

    // 生成hit信号
    wire hit = (tag_from_cache == tag_from_cpu) && valid_bit && (current_state == TAG_CHECK);

    always @(*) begin
        inst_valid = hit;
//        inst_out   = /* TODO: 根据字偏移，选择Cache行中的某个32位字输出指令 */;
        case (offset) 
            2'b00:    inst_out = cache_line_r[31:0];
            2'b01:    inst_out = cache_line_r[63:32];
            2'b10:    inst_out = cache_line_r[95:64];
            2'b11:    inst_out = cache_line_r[127:96];
        endcase
            
    end
    
    // @author 220110430
    // 此处的ICache写入信号与写入数据，发生在REFILL状态，且接收到 mem_rvalid 信号为1时， 同时men_rdata送来了128位数据的时候，这两数据有效的这一个posedge，就是写入cache的机会。
    // 因此，可以直接让men_rvalid接入cache_we作为写使能信号。而写入的内容，就是当时输出的那个cache块，和数据形成新的cache块再写入。一个是有效位置1，一个是数据放到数据块。
    
    // ！！ 由于intr_addr这个是个以字节为单位的，当我们要实现以字为单位的寻址，所以我们应该把所有来自主存地址的inst[x：y]改成 inst_addr[x+2:y+2]
    // !!! 我们在未命中的时候，送去给主存取的地址，不一定是块的第一个数据单元的地址。但是主存返回4单元数据块给我们的时候，一定是以我们送去的地址作为第一个数据单元的地址，取4个。
    // 因此，送去取数据的地址，要把最后4位设置成0！！
    
   
    wire       cache_we     = mem_rvalid;     // ICache存储体的写使能信号
    wire [5:0] cache_index  = inst_addr[9:4];     // 主存地址的Cache索引 / ICache存储体的地址           经上面计算，6bit
    wire [133:0] cache_line_w = {1'b1, tag_from_cpu, mem_rdata};     // 待写入ICache的Cache行
    wire [133:0] cache_line_r;                  // 从ICache读出的Cache行   这里读写cache块就是一整个cache块，包括valid位、tag段和数据块,

    // ICache存储体：Block MEM IP核
    blk_mem_gen_1 U_isram (
        .clka   (cpu_clk),
        .wea    (cache_we),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r)
    );

    //  编写状态机现态的更新逻辑
    always @(posedge cpu_clk or posedge cpu_rst ) begin
        if(cpu_rst) 
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // TODO: 编写状态机的状态转移逻辑
    always@(*) begin
        case(current_state)
            IDLE:              if(inst_rreq)   next_state = TAG_CHECK;       else next_state = IDLE;
            TAG_CHECK:         if(hit)        next_state = IDLE;             else next_state = REFILL;
            REFILL:            if(mem_rvalid) next_state = TAG_CHECK;             else next_state = REFILL;
        endcase
    end


    // TODO: 生成状态机的输出信号
    reg need_mem_read;
    always@(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst) begin
            mem_ren <= 0;
            mem_raddr <= 32'hffffffff;
            need_mem_read = 1;
        end
        else if(current_state == REFILL && mem_rrdy && need_mem_read) begin
            mem_ren <= 4'b1111;
            mem_raddr <= {inst_addr[31:4],4'b00};  //!!!!! 本来直接把cpu过来的主存地址发出去就错了！！！
            need_mem_read <= 0;
        end
        else if(current_state == IDLE) begin
            mem_ren <= 0;
            need_mem_read <= 1;           // 每次回到了IDLE状态都可以认为是一次完整的结束，那么需要读内存的信号复位回1
         end
         else begin
            mem_ren <= 0;        
         end
        
           
    end

    /******** 不要修改以下代码 ********/
`else

    localparam IDLE  = 2'b00;
    localparam STAT0 = 2'b01;
    localparam STAT1 = 2'b11;
    reg [1:0] state, nstat;

    always @(posedge cpu_clk or posedge cpu_rst) begin
        state <= cpu_rst ? IDLE : nstat;
    end

    always @(*) begin
        case (state)
            IDLE:    nstat = inst_rreq ? (mem_rrdy ? STAT1 : STAT0) : IDLE;
            STAT0:   nstat = mem_rrdy ? STAT1 : STAT0;
            STAT1:   nstat = mem_rvalid ? IDLE : STAT1;
            default: nstat = IDLE;
        endcase
    end

    always @(posedge cpu_clk or posedge cpu_rst) begin
        if (cpu_rst) begin
            inst_valid <= 1'b0;
            mem_ren    <= 4'h0;
        end else begin
            case (state)
                IDLE: begin
                    inst_valid <= 1'b0;
                    mem_ren    <= (inst_rreq & mem_rrdy) ? 4'hF : 4'h0;
                    mem_raddr  <= inst_rreq ? inst_addr : 32'h0;
                end
                STAT0: begin
                    mem_ren    <= mem_rrdy ? 4'hF : 4'h0;
                end
                STAT1: begin
                    mem_ren    <= 4'h0;
                    inst_valid <= mem_rvalid ? 1'b1 : 1'b0;
                    inst_out   <= mem_rvalid ? mem_rdata[31:0] : 32'h0;
                end
                default: begin
                    inst_valid <= 1'b0;
                    mem_ren    <= 4'h0;
                end
            endcase
        end
    end

`endif

endmodule
