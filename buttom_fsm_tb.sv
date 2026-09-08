`timescale 1ns/1ps

module buttom_fsm_tb;
    logic       clk;
    logic       rst_n;
    logic [3:0] btn;
    logic [3:0] leds;
    logic       unlocked;

    button_fsm dut (
        .clk   (clk),
        .rst_n (rst_n),
        .btn   (btn),
        .leds  (leds),
        .LED_UNLOCK (unlocked)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    task press_button(input logic [3:0] btn_val, input int hold_cycles);
        @(negedge clk);
        btn = ~btn_val;                    // Pressiona (ativo baixo)
        repeat (hold_cycles) @(posedge clk);
        @(negedge clk);
        btn = 4'b1111;                    // Solta
        repeat (3) @(posedge clk);     // Aguarda estabilizar
    endtask

    task check_state(input logic [4:0] expected, input string msg);
        @(negedge clk);
        if (leds === expected)
            $display("[PASS] %s | unlocked = %b", msg, unlocked);
        else
            $display("[FAIL] %s | esperado = %b, obtido = %b", msg, expected, unlocked);
    endtask

    initial begin
        // Dump de formas de onda para visualizacao no GTKWave
        $dumpfile("button_fsm.vcd");
        $dumpvars(0, button_fsm_tb);

        // Condicao inicial
        rst_n = 1'b1;
        btn   = 4'b1111;  // tudo solto

        $display("\n=== Teste 1: Reset ===");
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);
        check_state(5'b00001, "Apos reset -> INIT");

        $display("\n=== Teste 2: Ciclo completo de estados ===");
        press_button(4'b0001, 5);
        check_state(5'b00010, "1 aperto -> AZUL_ON");

        press_button(4'b0010, 5);
        check_state(5'b00100, "2 apertos -> AMARELO_ON");

        press_button(4'b0010, 5);
        check_state(5'b01000, "3 apertos -> AMARELO_OFF");

        press_button(4'b1000, 5);
        check_state(5'b10000, "4 apertos -> VERMELHO_ON (Aberto)");

        $display("\n=== Teste 3: Qualquer botao apos aberto reseta ===");
        press_button(4'b0001, 5); 
        check_state(5'b00001, "Botao pressionado -> INIT");

        $display("\n=== Teste 4: Sequencia errada ===");
        press_button(4'b0001, 5); // Certo
        press_button(4'b1000, 5); // Errado (Botao 3 ao inves de 1)
        check_state(5'b00001, "Sequencia errada -> Volta pro INIT");
        $finish;
    end

endmodule
