`timescale 1ns / 1ps

// `define BLK_LEN  4
// `define BLK_SIZE (`BLK_LEN*32)

module ICache(
    input  wire         cpu_clk,
    input  wire         cpu_rst,        // high active
    // Interface to CPU  ��cpu��ֻ����
    input  wire         inst_rreq,      // ����CPU��ȡָ����
    input  wire [31:0]  inst_addr,      // ����CPU��ȡָ��ַ
    output reg          inst_valid,     // �����CPU��ָ����Ч�źţ���ָ�����У�
    output reg  [31:0]  inst_out,       // �����CPU��ָ��
    // Interface to Read Bus
    input  wire         mem_rrdy,       // ��������źţ��ߵ�ƽ��ʾ����ɽ���ICache�Ķ�����
    output reg  [ 3:0]  mem_ren,        // ���������Ķ�ʹ���ź�
    output reg  [31:0]  mem_raddr,      // ���������Ķ���ַ
    input  wire         mem_rvalid,     // ���������������Ч�ź�
    input  wire [`BLK_SIZE-1:0] mem_rdata   // ��������Ķ�����
);

`ifdef ENABLE_ICACHE    /******** ��Ҫ�޸Ĵ��д��� ********/

// author 220110430
// �����㣬����cache1kB�� ����32kb������ֱ��ӳ�䵽cache�ֳ�32�������������ţ�tag����32������5bit�Ϳ���
// �����㣬cache��1kB��ÿ������4���֣�32λ=1�֣�������64���飬 ��ű���Ҫ6bit��һ��������4���֣���ʵ�����ݵ�Ԫ��Ϊ32λ�֣����Կ��ڵ�ַ����2bit
// ������, �����ַ��Ҫ���������ݣ����ţ�tag������š����ڵ�ַ�ֱ���5��6��2���ܹ�����13λ�� �����ַ32λ������ֻ��Ҫ�õ�13λ��
// �����㣬 cacheһ������4*32bit = 128bit��ʵ��Ҫ����չ������validλ�����ţ�tag��������֤�Ƿ����У�����������hit�źţ�������1+5+128ʵ��134bit����Ϊһ��cache�顣������134bit��cache�飬����cache�洢�����档
// ��ˣ�cache�洢���Ǳߣ�д��д���źţ�λ��134bit�� ���ڷ���cache�洢��ģ���ʵ��cache�Ŀ��ַ�������ڵ�ַ��Ҳ��������Ŀ�ŵ�6bit
// [31:0]  inst_addr, cpu�����������ַ    [1:0]-���ڵ�ַ  [7:2]-��ţ����ַ��  [12:8]-����(tag)��  ��31��8���������������ţ����ǽ������cache�鵱tag�����5bit

// @author 220110430
// ���е��߼����ÿ����Ϊcache�洢���Ѱַ����cache�洢��ȡ��cache�顣����muxѡ���Կ���ƫ�Ƶ�ַ��2bit����Ϊѡ���źţ�ѡ��cache���ݿ��е�ĳһ�����ݵ�Ԫ��Ϊ���data�� ͬʱcache��ĸ�6λ�ֱ���validλ
// �Լ�tag�����ں����������(tag)����hit�źš� ��Щ��������߼����  

// 2024/6/5 
    wire [4:0] tag_from_cpu   = inst_addr[14:10];    // �����ַ��TAG
    wire [1:0] offset         = inst_addr[3:2];    // 32λ��ƫ����
    wire       valid_bit      = cache_line_r[133];    // Cache�е���Чλ
    wire [4:0] tag_from_cache = cache_line_r[132:128];    // Cache�е�TAG

    // ����ICache״̬����״̬����
    reg [1:0] current_state;        // ��̬
    reg [1:0] next_state;           // ��̬
    localparam IDLE = 2'b00;
    localparam TAG_CHECK = 2'b01;
    localparam REFILL = 2'b11;

    // ����hit�ź�
    wire hit = (tag_from_cache == tag_from_cpu) && valid_bit && (current_state == TAG_CHECK);

    always @(*) begin
        inst_valid = hit;
//        inst_out   = /* TODO: ������ƫ�ƣ�ѡ��Cache���е�ĳ��32λ�����ָ�� */;
        case (offset) 
            2'b00:    inst_out = cache_line_r[31:0];
            2'b01:    inst_out = cache_line_r[63:32];
            2'b10:    inst_out = cache_line_r[95:64];
            2'b11:    inst_out = cache_line_r[127:96];
        endcase
            
    end
    
    // @author 220110430
    // �˴���ICacheд���ź���д�����ݣ�������REFILL״̬���ҽ��յ� mem_rvalid �ź�Ϊ1ʱ�� ͬʱmen_rdata������128λ���ݵ�ʱ������������Ч����һ��posedge������д��cache�Ļ��ᡣ
    // ��ˣ�����ֱ����men_rvalid����cache_we��Ϊдʹ���źš���д������ݣ����ǵ�ʱ������Ǹ�cache�飬�������γ��µ�cache����д�롣һ������Чλ��1��һ�������ݷŵ����ݿ顣
    
    // ���� ����intr_addr����Ǹ����ֽ�Ϊ��λ�ģ�������Ҫʵ������Ϊ��λ��Ѱַ����������Ӧ�ð��������������ַ��inst[x��y]�ĳ� inst_addr[x+2:y+2]
    // !!! ������δ���е�ʱ����ȥ������ȡ�ĵ�ַ����һ���ǿ�ĵ�һ�����ݵ�Ԫ�ĵ�ַ���������淵��4��Ԫ���ݿ�����ǵ�ʱ��һ������������ȥ�ĵ�ַ��Ϊ��һ�����ݵ�Ԫ�ĵ�ַ��ȡ4����
    // ��ˣ���ȥȡ���ݵĵ�ַ��Ҫ�����4λ���ó�0����
    
   
    wire       cache_we     = mem_rvalid;     // ICache�洢���дʹ���ź�
    wire [5:0] cache_index  = inst_addr[9:4];     // �����ַ��Cache���� / ICache�洢��ĵ�ַ           ��������㣬6bit
    wire [133:0] cache_line_w = {1'b1, tag_from_cpu, mem_rdata};     // ��д��ICache��Cache��
    wire [133:0] cache_line_r;                  // ��ICache������Cache��   �����дcache�����һ����cache�飬����validλ��tag�κ����ݿ�,

    // ICache�洢�壺Block MEM IP��
    blk_mem_gen_1 U_isram (
        .clka   (cpu_clk),
        .wea    (cache_we),
        .addra  (cache_index),
        .dina   (cache_line_w),
        .douta  (cache_line_r)
    );

    //  ��д״̬����̬�ĸ����߼�
    always @(posedge cpu_clk or posedge cpu_rst ) begin
        if(cpu_rst) 
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // TODO: ��д״̬����״̬ת���߼�
    always@(*) begin
        case(current_state)
            IDLE:              if(inst_rreq)   next_state = TAG_CHECK;       else next_state = IDLE;
            TAG_CHECK:         if(hit)        next_state = IDLE;             else next_state = REFILL;
            REFILL:            if(mem_rvalid) next_state = TAG_CHECK;             else next_state = REFILL;
        endcase
    end


    // TODO: ����״̬��������ź�
    reg need_mem_read;
    always@(posedge cpu_clk or posedge cpu_rst) begin
        if(cpu_rst) begin
            mem_ren <= 0;
            mem_raddr <= 32'hffffffff;
            need_mem_read = 1;
        end
        else if(current_state == REFILL && mem_rrdy && need_mem_read) begin
            mem_ren <= 4'b1111;
            mem_raddr <= {inst_addr[31:4],4'b00};  //!!!!! ����ֱ�Ӱ�cpu�����������ַ����ȥ�ʹ��ˣ�����
            need_mem_read <= 0;
        end
        else if(current_state == IDLE) begin
            mem_ren <= 0;
            need_mem_read <= 1;           // ÿ�λص���IDLE״̬��������Ϊ��һ�������Ľ�������ô��Ҫ���ڴ���źŸ�λ��1
         end
         else begin
            mem_ren <= 0;        
         end
        
           
    end

    /******** ��Ҫ�޸����´��� ********/
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
