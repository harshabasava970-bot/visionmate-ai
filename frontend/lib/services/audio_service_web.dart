// Web implementation — uses browser's native speechSynthesis API.
// This bypasses autoplay restrictions entirely.
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

void speakWeb(String text, String lang) {
  // Cancel any ongoing speech first
  js.context.callMethod('eval', ['window.speechSynthesis.cancel()']);

  // Create utterance and speak
  final script = '''
    (function() {
      var u = new SpeechSynthesisUtterance(${_jsString(text)});
      u.lang = "$lang";
      u.rate = 1.0;
      u.pitch = 1.0;
      u.volume = 1.0;
      window.speechSynthesis.speak(u);
    })();
  ''';
  js.context.callMethod('eval', [script]);
}

void stopWeb() {
  js.context.callMethod('eval', ['window.speechSynthesis.cancel()']);
}

String _jsString(String text) {
  // Escape single quotes and backslashes for safe JS string
  final escaped = text.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return "'$escaped'";
}
