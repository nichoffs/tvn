#!/usr/bin/env bash

# Start recording silently
rec -b 16 -r 16000 mic_input.wav gain -3 > /dev/null 2>&1 &

# Wait for user to press Enter to stop recording
read -p "Recording... Press ENTER to finish."

# Kill the recording process
pkill -P $$ rec

# Check for existence of recorded file and exit if not found
[ -f "mic_input.wav" ] || { echo "Recording failed: WAV file not found."; exit 1; }

# Move and process the recording
mv mic_input.wav ./lib/whisper.cpp/mic_input.wav
cd ./lib/whisper.cpp || exit 1
./main -otxt mic_input.wav -of ../../transcription > /dev/null 2>&1
cd - > /dev/null

# Check for transcription and exit if failed
[ -f "./transcription.txt" ] || { echo "Transcription failed: Output file not found."; exit 1; }

# Prepare and send payload to model, handle response
cat ./prompts/DEFAULT.txt ./transcription.txt > ./final_prompt.txt
JSON_PAYLOAD=$(jq -nc --arg model "phi3" --arg prompt "$(cat ./final_prompt.txt)" '{model: $model, prompt: $prompt, stream: false}')
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d "$JSON_PAYLOAD" http://localhost:11434/api/generate)
COMMAND=$(echo $RESPONSE | jq -r '.response' | awk '/```bash/{flag=1;next}/```/{flag=0}flag')

# Exit if no command was extracted
[ -n "$COMMAND" ] || { echo "No command extracted. Response may be empty or incorrect."; exit 1; }

# Clean up
rm transcription.txt final_prompt.txt ./lib/whisper.cpp/mic_input.wav

# Save and execute the command
echo "$COMMAND" > req.sh
chmod +x req.sh
if [ -s req.sh ]; then
    . ./req.sh  # Source the command script
else
    echo "req.sh is empty. Check the command extraction logic."
    exit 1
fi

