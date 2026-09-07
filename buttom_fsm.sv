module buttom_fsm (
    input  logic       clk,    // Clock de 50 MHz
    input  logic       rst_n,  // Reset assincrono, ativo baixo (KEY[0])
    input  logic [3:0] btn,    // Botao de avanco, ativo baixo  (KEY[1])
    output logic       LED_UNLOCK // LED indicando que o cofre foi aberto
);

localparam logic [3:0] btn_azul     = 4'b0001;
localparam logic [3:0] btn_amarelo  = 4'b0010;
localparam logic [3:0] btn_amarelo2 = 4'b0100;
localparam logic [3:0] btn_vermelho = 4'b1000;

typedef enum logic [4:0] {
    INIT        = 5'b00001,
    AZUL_ON     = 5'b00010,
    AMARELO_ON  = 5'b00100,
    AMARELO2_ON = 5'b01000,
    VERMELHO_ON = 5'b10000
} state_t;

state_t state, next_state;

logic [3:0] btn_active;
assign btn_active = ~btn;

logic [3:0] btn_prev;
logic [3:0] btn_rise; // CORREÇÃO: Agora tem 4 bits para capturar qual botão gerou a borda

// CORREÇÃO: Detecta borda de subida individualmente por bit
assign btn_rise = btn_active & ~btn_prev; 

// Juntando a lógica de flip-flops em um único bloco (boas práticas)
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        btn_prev <= 4'b0000;
        state    <= INIT;
    end
    else begin
        btn_prev <= btn_active;
        state    <= next_state;
    end
end

always_comb begin
    next_state = state;  // Default: mantem estado

    unique case (state)
        INIT: begin
            if(btn_rise == btn_azul) 
                next_state = AZUL_ON;
        end

        AZUL_ON: begin
            // CORREÇÃO: Só avalia se DE FATO algum botão foi pressionado
            if (btn_rise != 4'b0000) begin
                if(btn_rise == btn_amarelo)
                    next_state = AMARELO_ON;
                else
                    next_state = INIT; // Errou a senha, volta do inicio
            end
        end

        AMARELO_ON: begin
            if (btn_rise != 4'b0000) begin
                if(btn_rise == btn_amarelo2)
                    next_state = AMARELO2_ON;
                else
                    next_state = INIT;
            end
        end

        AMARELO2_ON: begin
            if (btn_rise != 4'b0000) begin
                if(btn_rise == btn_vermelho)
                    next_state = VERMELHO_ON;
                else
                    next_state = INIT;
            end
        end

        VERMELHO_ON: begin
            // CORREÇÃO: Fica destrancado até qualquer botão ser pressionado novamente
            if (btn_rise != 4'b0000) begin
                next_state = INIT; 
            end
        end

        default: next_state = INIT;
    endcase
end

assign LED_UNLOCK = (state == VERMELHO_ON);

endmodule
