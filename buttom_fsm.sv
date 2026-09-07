module button_fsm (
    input  logic       clk,    // Clock de 50 MHz
    input  logic       rst_n,  // Reset assincrono, ativo baixo (KEY[0])
    input  logic [3:0] btn,    // Botao de avanco, ativo baixo  (KEY[1])
    output logic       LED_UNLOCK // LED indicando que o cofre foi aberto
);

localparam logic [3:0] btn_azul = 4'b0001;
localparam logic [3:0] btn_amarelo = 4'b0010;
localparam logic [3:0] btn_verde = 4'b0100;
localparam logic [3:0] btn_vermelho = 4'b1000;

typedef enum logic [4:0] {
    INIT = 5'b00001,            // Espera o LED[0] ser pressionado
    AZUL_ON = 5'b00010,        // LED[0] == 1 - Primeiro botão pressionado
    AMARELO_ON = 5'b00100,     // LED[1] == 1 - Segundo botão pressionado
    AMARELO2_ON = 5'b01000,     // LED[1] == 0 - Segundo botão pressionado mais uma vez
    VERMELHO_ON = 5'b10000     // LED[2] == 1 - Terceito botão pressionado
} state_t;

state_t state, next_state;

logic [3:0] btn_active;
assign btn_active = ~btn;

logic [3:0] btn_prev;
logic btn_rise;

assign btn_rise = (btn_active != 4'b0000) && (btn_prev == 4'b0000);

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        btn_prev <= 4'b0000;
    end
    else begin
        btn_prev <= btn_active;
    end
end

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        state <= INIT;
    else
        state <= next_state;
end

always_comb begin
    next_state = state;  // Default: mantem estado se nao houver borda

    if(btn_rise) begin
        unique case (state)
            INIT: begin
                if(btn_active == btn_azul) 
                    next_state = AZUL_ON;
            end

            AZUL_ON: begin
                if(btn_active == btn_amarelo)
                    next_state = AMARELO_ON;
                else
                    next_state = INIT;
            end

            AMARELO_ON: begin
                if(btn_active == btn_amarelo)
                    next_state = AMARELO2_ON;
                else
                    next_state = INIT;
            end

            AMARELO2_ON: begin
                if(btn_active == btn_vermelho)
                    next_state = VERMELHO_ON;
                else
                    next_state = INIT;
            end

            VERMELHO_ON: begin
                next_state = VERMELHO_ON;
            end

            default: next_state = INIT;
        endcase
    end
end

assign LED_UNLOCK = (state == VERMELHO_ON);

endmodule
