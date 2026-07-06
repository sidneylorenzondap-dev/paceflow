export async function generateTTS(text: string): Promise<string> {
  // Mock TTS service for the MVP
  // In a real scenario, this might call Google Cloud TTS and return an audio buffer or URL.
  // For now, we just pass the text back to the Flutter client which has native TTS.
  console.log(`[TTS Service] Generating audio for: "${text}"`);
  return JSON.stringify({ action: 'PLAY_TTS', text });
}
