import 'dart:typed_data';

/// E-01：PCM16 小端 → WAV（RIFF/WAVE header，fmt tag 1）。
class WavCodec {
  WavCodec._();

  /// 生成 16-bit PCM WAV 字节。
  static Uint8List pcm16ToWav(
    Uint8List pcm, {
    int sampleRate = 24000,
    int channels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcm.length;
    final totalSize = 44 + dataSize;

    final wav = BytesBuilder();
    void writeString(String s) => wav.add(s.codeUnits);
    void writeU32(int v) => wav.add([
          v & 0xFF,
          (v >> 8) & 0xFF,
          (v >> 16) & 0xFF,
          (v >> 24) & 0xFF,
        ]);
    void writeU16(int v) => wav.add([v & 0xFF, (v >> 8) & 0xFF]);

    writeString('RIFF');
    writeU32(totalSize - 8);
    writeString('WAVE');
    writeString('fmt ');
    writeU32(16);
    writeU16(1); // PCM
    writeU16(channels);
    writeU32(sampleRate);
    writeU32(byteRate);
    writeU16(blockAlign);
    writeU16(bitsPerSample);
    writeString('data');
    writeU32(dataSize);
    wav.add(pcm);
    return wav.toBytes();
  }
}
