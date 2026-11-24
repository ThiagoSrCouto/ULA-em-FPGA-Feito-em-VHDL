# ULA de 4 Bits em VHDL para FPGA Xilinx Spartan-3A Starter Kit

Este repositório reúne os arquivos-fonte em **VHDL** de uma **Unidade Lógica e Aritmética (ULA) de 4 bits** projetada para a placa **FPGA Xilinx Spartan-3A Starter Kit**. O circuito realiza operações lógicas e aritméticas em complemento de 2 e utiliza **multiplexação temporal** nas chaves de entrada para contornar a quantidade limitada de pinos físicos disponíveis no kit, exibindo tanto os resultados quanto as _flags_ de sinalização nos **8 LEDs** da placa.

---

## Operação na Placa e Conjunto de Instruções

Como a configuração completa exige 12 bits (`Sel`, `A` e `B`) e apenas quatro chaves físicas estão disponíveis, a captura dos dados ocorre em **quatro etapas sequenciais** comandadas pelo botão `btn` e sinalizadas visualmente pelos LEDs:

1. **Escolha da Operação (`etapa = 0`):** Com `leds[7:4]` indicando `0001`, o usuário define o código da instrução (`Sel[2:0]`) nas quatro chaves (`keys[3:0]`).
2. **Carga do Primeiro Operando (`etapa = 1`):** Ao pressionar `btn`, o código é armazenado e `leds[7:4]` passa a exibir `0010`, aguardando os 4 bits do operando `A` em complemento de 2.
3. **Carga do Segundo Operando (`etapa = 2`):** No acionamento seguinte do botão, `leds[7:4]` sinaliza `0100` para a leitura dos 4 bits do operando `B`.
4. **Visualização do Resultado e Reinício (`etapa = 3`):** Os quatro LEDs superiores (`leds[7:4]`) exibem as _flags_ de status (`FO`, `FC`, `FN` e `FZ`), enquanto os inferiores (`leds[3:0]`) apresentam o valor calculado (`Y`). Um novo toque no botão zera os registradores de forma síncrona e reinicia o ciclo.

A partir dos três bits menos significativos do seletor (`Sel[2:0]`), a unidade executa oito operações distintas:
- `000` — **Adição:** Soma com sinal em complemento de 2 (`A + B`);
- `001` — **Subtração:** Diferença com sinal em complemento de 2 (`A - B`);
- `010` — **AND:** Produto lógico bit a bit (`A ∧ B`);
- `011` — **OR:** Soma lógica bit a bit (`A ∨ B`);
- `100` — **XOR:** Ou-exclusivo bit a bit (`A ⊕ B`);
- `101` — **Deslocamento Aritmético:** Multiplica ou divide `A` por potências de 2 (`A × 2^B`), deslocando à esquerda (`B > 0`) ou à direita com preservação de sinal (`B < 0`);
- `110` — **Comparação com Sinal:** Indica a relação de ordem entre os operandos em codificação _one-hot_: `0100` (`A > B`), `0010` (`A = B`) ou `0001` (`A < B`);
- `111` — **Divisão Inteira:** Calcula o quociente com sinal (`A / B`) por subtrações sucessivas, retornando `1111` como sinalização de erro caso `B = 0`.

---

## Organização dos Arquivos e Arquitetura

O projeto combina lógica combinacional e controle síncrono sob um _clock_ global de **50 MHz** (período de `20 ns`), distribuído entre os seguintes arquivos:

- **`Controlador.vhd` (`Controlador`):** Módulo principal (_Top-Level_) que instancia os subcomponentes, detecta bordas de subida do botão já filtrado, gerencia a máquina de estados de quatro etapas e controla a multiplexação das chaves (`keys[3:0]`) e dos LEDs (`leds[7:0]`).
- **`debouncer.vhd` (`debouncer`):** Circuito de condicionamento do botão físico (`btn`), combinando dois _flip-flops_ em cascata (prevenção de metaestabilidade) a um temporizador de `500 ms` (`25.000.000` ciclos de _clock_) para suprimir oscilações mecânicas (_bounce_).
- **`ULA.vhd` (`ULA`):** Unidade puramente combinacional que estende os operandos de 4 para 5 bits (com e sem sinal), decodifica as oito operações selecionadas por `Sel[2:0]` e atualiza as _flags_ de _Overflow_ (`FO`), _Carry/Borrow_ (`FC`), Negativo (`FN`) e Zero (`FZ`).
- **`Controlador.ucf`:** Arquivo de mapeamento físico de pinos e restrições elétricas (`LVCMOS33` e `PULLDOWN` interno em `btn`) para a placa FPGA Xilinx Spartan-3A Starter Kit (`clk` em `E12`, `btn` em `T15`, `keys[3:0]` em `V8..T9` e `leds[7:0]` em `R20..W21`).
