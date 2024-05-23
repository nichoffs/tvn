# Terminal Voice Navigator

Voice-to-shell program, all in a single shell script.

## Requirements
- `mac`
- `sox` (for `rec`)
- `ollama` with `phi3` installed

## How it Works

1. take mic input from user and save to wav
2. pipe wav to `whisper.cpp` and transcribe to txt
3. concatenate extracted text with system prompt
4. prompt phi using ollama
5. extract command between bash tags
5. execute response as command
