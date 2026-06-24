import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sumi_app/features/home_widgets/data/interfaces/widget_service.dart';
import 'package:sumi_app/features/home_widgets/data/sumi_widget_service.dart';

final widgetServiceProvider = Provider<WidgetService>((ref) {
  return SumiWidgetService();
});
