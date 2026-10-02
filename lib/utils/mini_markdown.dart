import 'package:flutter/material.dart';

/// Renderer markdown sangat kecil untuk balasan asisten:
/// **tebal** dan daftar berawalan "- " / "* " (jadi "•").
/// Sengaja tanpa dependency; heading/tabel/kode tidak didukung
/// (system prompt melarang asisten memakainya).
TextSpan miniMarkdown(String teks, TextStyle dasar) {
  final children = <InlineSpan>[];
  final baris = teks.split('\n');

  for (var i = 0; i < baris.length; i++) {
    var line = baris[i];
    final bullet = RegExp(r'^\s*[-*•]\s+').firstMatch(line);
    if (bullet != null) {
      line = '•  ${line.substring(bullet.end)}';
    }

    final bagian = line.split('**');
    for (var j = 0; j < bagian.length; j++) {
      if (bagian[j].isEmpty) continue;
      // bagian ganjil berada di dalam sepasang **...**
      final tebal = j.isOdd && j < bagian.length - 1;
      children.add(TextSpan(
        text: tebal || j.isEven ? bagian[j] : '**${bagian[j]}',
        style: tebal ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ));
    }
    if (i < baris.length - 1) children.add(const TextSpan(text: '\n'));
  }

  return TextSpan(style: dasar, children: children);
}
