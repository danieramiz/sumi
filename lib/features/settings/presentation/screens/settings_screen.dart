import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:sumi_app/app/theme.dart';
import 'package:sumi_app/core/storage/preferences_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _language;
  late bool _scrollMode;
  late bool _notifications;
  SortOrder _sortOrder = SortOrder.lastUpdated;

  static const _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'pt-br', 'label': 'Português (BR)'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'it', 'label': 'Italiano'},
    {'code': 'ja', 'label': '日本語'},
    {'code': 'ko', 'label': '한국어'},
    {'code': 'zh', 'label': '中文'},
    {'code': 'ru', 'label': 'Русский'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'vi', 'label': 'Tiếng Việt'},
  ];

  @override
  void initState() {
    super.initState();
    final prefs = PreferencesService.instance;
    _language = prefs.language;
    _scrollMode = prefs.readerScrollMode;
    _notifications = prefs.notificationsEnabled;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              leading: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.subtle,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: AppColors.primaryText,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              title: Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LANGUAGE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Chapters will be fetched in your preferred language.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Column(
                        children: _languages.map((lang) {
                          final code = lang['code']!;
                          final label = lang['label']!;
                          final selected = code == _language;
                          return _languageTile(code, label, selected);
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'NOTIFICATIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: SwitchListTile(
                        value: _notifications,
                        onChanged: (v) {
                          setState(() => _notifications = v);
                          final prefs = PreferencesService.instance;
                          prefs.notificationsEnabled = v;
                          prefs.save();
                          HomeWidget.saveWidgetData<bool>(
                              'notifications_enabled', v);
                          if (v) {
                            const MethodChannel('sumi_widget_background')
                                .invokeMethod('requestNotificationPermission');
                          }
                        },
                        title: const Text(
                          'New chapter notifications',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.primaryText,
                          ),
                        ),
                        subtitle: const Text(
                          'Get notified when new chapters are released',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        activeColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'READER',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _scrollMode,
                            onChanged: (v) {
                              setState(() => _scrollMode = v);
                              final prefs = PreferencesService.instance;
                              prefs.readerScrollMode = v;
                              prefs.save();
                            },
                            title: const Text(
                              'Vertical scroll reader',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppColors.primaryText,
                              ),
                            ),
                            subtitle: const Text(
                              'Show all pages in a single scroll',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.secondaryText,
                              ),
                            ),
                            activeColor: AppColors.accent,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'SORT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryText,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Column(
                        children: [
                          _sortTile(
                            SortOrder.lastUpdated,
                            Icons.update_rounded,
                            'Last Updated',
                          ),
                          _sortTile(
                            SortOrder.title,
                            Icons.sort_by_alpha_rounded,
                            'Title A-Z',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _languageTile(String code, String label, bool selected) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          setState(() => _language = code);
          final prefs = PreferencesService.instance;
          prefs.language = code;
          await prefs.save();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded,
                    color: AppColors.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sortTile(SortOrder order, IconData icon, String label) {
    final selected = _sortOrder == order;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () async {
          setState(() => _sortOrder = order);
          final prefs = PreferencesService.instance;
          prefs.sortOrder = order;
          await prefs.save();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.secondaryText, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.primaryText,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_rounded,
                    color: AppColors.accent, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
