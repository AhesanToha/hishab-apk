import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'store.dart';

/// Donut chart drawn from the same monthSpend map the Budget screen uses.
class DonutChart extends StatelessWidget {
  final Map<String, int> data; // category -> amount
  final int total;
  const DonutChart({super.key, required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 210,
      child: Row(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _DonutPainter(data, total),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('মোট খরচ',
                        style: TextStyle(color: Color(0xFFD7E6EB), fontSize: 12)),
                    Text(formatTaka(total),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: data.entries.map((e) {
                final info = categoryInfo(e.key, false);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                          width: 10, height: 10,
                          decoration: BoxDecoration(
                              color: Color(info.color),
                              borderRadius: BorderRadius.circular(3))),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(e.key,
                              style: const TextStyle(
                                  color: Color(0xFFD7E6EB), fontSize: 13))),
                      Text(formatTaka(e.value),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final Map<String, int> data;
  final int total;
  _DonutPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    if (total <= 0 || data.isEmpty) {
      final p = Paint()
        ..color = const Color(0xFF1E3A45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26;
      canvas.drawCircle(center, radius, p);
      return;
    }
    var start = -math.pi / 2;
    for (final e in data.entries) {
      final sweep = (e.value / total) * math.pi * 2;
      final p = Paint()
        ..color = Color(categoryInfo(e.key, false).color)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 26
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius), start, sweep, false, p);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.data != data || old.total != total;
}

/// 7-day grouped bar chart, aggregated from entries in [AppState.last7Days].
class WeekBarChart extends StatelessWidget {
  final List<({DateTime day, int income, int expense})> days;
  const WeekBarChart({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    final maxV = days.fold<int>(
        1000,
        (m, d) => math.max(m, math.max(d.income, d.expense)));
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: days.map((d) {
              final inH = (d.income / maxV) * 110;
              final outH = (d.expense / maxV) * 110;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                            width: 9, height: math.max(inH, 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFF00D9A3),
                                borderRadius: BorderRadius.circular(3))),
                        const SizedBox(width: 3),
                        Container(
                            width: 9, height: math.max(outH, 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFF5A4E),
                                borderRadius: BorderRadius.circular(3))),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text('${d.day.day}/${d.day.month}',
                        style: const TextStyle(
                            color: Color(0xFFD7E6EB), fontSize: 10)),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Legend(color: Color(0xFF00D9A3), label: 'আয়'),
            SizedBox(width: 16),
            _Legend(color: Color(0xFFFF5A4E), label: 'খরচ'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Color(0xFFD7E6EB), fontSize: 12)),
        ],
      );
}
