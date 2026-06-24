import 'package:flutter/material.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_service.dart';
import 'package:sumi_app/features/home_widgets/data/widget_mock_data.dart';
import 'package:sumi_app/features/home_widgets/presentation/widgets/sumi_large_widget_preview.dart';
import 'package:sumi_app/features/home_widgets/presentation/widgets/sumi_medium_widget_preview.dart';
import 'package:sumi_app/features/home_widgets/presentation/widgets/sumi_small_widget_preview.dart';

class WidgetPreviewScreen extends StatefulWidget {
  const WidgetPreviewScreen({super.key});

  @override
  State<WidgetPreviewScreen> createState() => _WidgetPreviewScreenState();
}

class _WidgetPreviewScreenState extends State<WidgetPreviewScreen> {
  final _service = SumiWidgetService();
  bool _updating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Widget Preview',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.primaryText),
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
          const SizedBox(height: 32),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _updating ? null : _updateWidgets,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4F6D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _updating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Update Android Widgets',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Saves mock data and refreshes home screen widgets',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _updateWidgets() async {
    setState(() => _updating = true);
    try {
      await _service.updateAndroidWidgets(SumiWidgetService.mockData());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Widgets updated! Add them from your home screen.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
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
        color: AppColors.secondaryText,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }
}
