import 'package:flutter/material.dart';
import 'package:sumi_app/features/widgets/data/widget_mock_data.dart';
import 'package:sumi_app/features/widgets/presentation/widgets/sumi_large_widget_preview.dart';
import 'package:sumi_app/features/widgets/presentation/widgets/sumi_medium_widget_preview.dart';
import 'package:sumi_app/features/widgets/presentation/widgets/sumi_small_widget_preview.dart';

class WidgetPreviewScreen extends StatelessWidget {
  const WidgetPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Widget Preview',
          style: TextStyle(
            color: Color(0xFF111111),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF111111)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'Small Widget'),
          const SizedBox(height: 12),
          Center(
            child: SumiSmallWidgetPreview(entry: WidgetMockData.smallEntry),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Medium Widget'),
          const SizedBox(height: 12),
          Center(
            child: SumiMediumWidgetPreview(entry: WidgetMockData.mediumEntry),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'Large Widget'),
          const SizedBox(height: 12),
          Center(
            child: SumiLargeWidgetPreview(entry: WidgetMockData.largeEntry),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF8A8A8A),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
