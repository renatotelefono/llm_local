# llm_local

Progetto per creare un piccolo LLM locale che legge i tarocchi.

## Obiettivo della prima fase
- Solo i 22 Arcani Maggiori
- Ogni carta dritta o rovesciata
- Stesa a tre carte: passato, presente, futuro

## Piano
1. Schede delle 22 carte (significato dritto e rovescio)
2. Programma Python per l'estrazione delle carte
3. Generazione delle letture di esempio (dataset)
4. Fine-tuning di un modello piccolo (es. Qwen 0,5B con LoRA)
5. Test e correzioni
6. Conversione in GGUF e pubblicazione con Ollama
7. Voce (text-to-speech, es. Piper)
