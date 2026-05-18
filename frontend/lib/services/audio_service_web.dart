// Web implementation — uses browser's native speechSynthesis API.
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void speakWeb(String text, String lang) {
  // Cancel any ongoing speech
  html.window.speechSynthesis?.cancel();

  final utterance = html.SpeechSynthesisUtterance(text);
  utterance.lang = lang;
  utterance.rate = 1.0;
  utterance.pitch = 1.0;
  utterance.volume = 1.0;

  html.window.speechSynthesis?.speak(utterance);
}

void stopWeb() {
  html.window.speechSynthesis?.cancel();
}
