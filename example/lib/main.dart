import 'package:flutter/material.dart';
import 'package:flutter_page_scaffold/flutter_page_scaffold.dart';

// ---------------------------------------------------------------------------
// Theme definitions
// ---------------------------------------------------------------------------

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFF165DFF),
    onPrimary: Colors.white,
    secondary: Color(0xFF722ED1),
    onSecondary: Colors.white,
    tertiary: Color(0xFF00B42A),
    error: Color(0xFFF53F3F),
    surface: Colors.white,
    onSurface: Color(0xFF1D2129),
    onSurfaceVariant: Color(0xFF4E5969),
    outline: Color(0xFFE5E6EB),
    outlineVariant: Color(0xFFC9CDD4),
    surfaceContainerHighest: Color(0xFFF2F3F5),
    surfaceContainerHigh: Color(0xFFF7F8FA),
    surfaceContainerLow: Color(0xFFF8F9FA),
  ),
  scaffoldBackgroundColor: const Color(0xFFF8F9FA),
  cardColor: Colors.white,
  dividerColor: const Color(0xFFE5E6EB),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: const ColorScheme.dark(
    primary: Color(0xFF3C7EFF),
    onPrimary: Colors.white,
    secondary: Color(0xFF9B6FE8),
    onSecondary: Colors.white,
    tertiary: Color(0xFF27C346),
    error: Color(0xFFFF4D4F),
    surface: Color(0xFF1E1E2E),
    onSurface: Color(0xFFE8E8ED),
    onSurfaceVariant: Color(0xFF9CA3AF),
    outline: Color(0xFF3A3A4A),
    outlineVariant: Color(0xFF4A4A5A),
    surfaceContainerHighest: Color(0xFF2A2A3A),
    surfaceContainerHigh: Color(0xFF252535),
    surfaceContainerLow: Color(0xFF1A1A2A),
  ),
  scaffoldBackgroundColor: const Color(0xFF141420),
  cardColor: const Color(0xFF1E1E2E),
  dividerColor: const Color(0xFF3A3A4A),
);

final ThemeData sunshineTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: Color(0xFFFF8C00),
    onPrimary: Colors.white,
    secondary: Color(0xFFD4A017),
    onSecondary: Colors.white,
    tertiary: Color(0xFF4CAF50),
    error: Color(0xFFE53935),
    surface: Color(0xFFFFFDF5),
    onSurface: Color(0xFF3E2723),
    onSurfaceVariant: Color(0xFF6D4C41),
    outline: Color(0xFFE8D5B7),
    outlineVariant: Color(0xFFD4B896),
    surfaceContainerHighest: Color(0xFFF5ECD7),
    surfaceContainerHigh: Color(0xFFFAF3E3),
    surfaceContainerLow: Color(0xFFFFF8EC),
  ),
  scaffoldBackgroundColor: const Color(0xFFFFF8EC),
  cardColor: const Color(0xFFFFFDF5),
  dividerColor: const Color(0xFFE8D5B7),
);

// ---------------------------------------------------------------------------
// App entry point
// ---------------------------------------------------------------------------

void main() {
  runApp(const PlaygroundApp());
}

class PlaygroundApp extends StatefulWidget {
  const PlaygroundApp({super.key});

  @override
  State<PlaygroundApp> createState() => _PlaygroundAppState();
}

enum AppTheme { light, dark, sunshine }

class _PlaygroundAppState extends State<PlaygroundApp> {
  AppTheme _currentTheme = AppTheme.light;
  bool _showTitle = true;
  bool _showTabs = true;
  bool _maintainState = true;
  bool _animate = false;
  bool _showCard = true;

  ThemeData get _themeData {
    switch (_currentTheme) {
      case AppTheme.light:
        return lightTheme;
      case AppTheme.dark:
        return darkTheme;
      case AppTheme.sunshine:
        return sunshineTheme;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Page Scaffold Playground',
      debugShowCheckedModeBanner: false,
      theme: _themeData,
      home: Scaffold(
        body: Column(
          children: [
            _ControlBar(
              currentTheme: _currentTheme,
              onThemeChanged: (t) => setState(() => _currentTheme = t),
              showTitle: _showTitle,
              onShowTitleChanged: (v) => setState(() => _showTitle = v),
              showTabs: _showTabs,
              onShowTabsChanged: (v) => setState(() => _showTabs = v),
              maintainState: _maintainState,
              onMaintainStateChanged: (v) => setState(() => _maintainState = v),
              animate: _animate,
              onAnimateChanged: (v) => setState(() => _animate = v),
              showCard: _showCard,
              onShowCardChanged: (v) => setState(() => _showCard = v),
            ),
            Expanded(
              child: MainAreaTemplate(
                title: 'Network Manager',
                description: 'Manage network infrastructure.',
                icon: Icons.router,
                showTitle: _showTitle,
                showTabs: _showTabs,
                maintainState: _maintainState,
                showCard: _showCard,
                tabTransitionDuration: _animate
                    ? const Duration(milliseconds: 200)
                    : null,
                actions: [
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Device'),
                  ),
                ],
                tabs: const [
                  PageTab(
                    label: 'Devices',
                    icon: Icons.table_chart_outlined,
                    child: TableDemoContent(),
                  ),
                  PageTab(
                    label: 'Settings',
                    icon: Icons.settings_outlined,
                    child: SettingsDemoContent(),
                  ),
                  PageTab(
                    label: 'Dashboard',
                    icon: Icons.dashboard_outlined,
                    child: DashboardDemoContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Control Bar (top strip — visibility toggles + theme switcher)
// ---------------------------------------------------------------------------

class _ControlBar extends StatelessWidget {
  final AppTheme currentTheme;
  final ValueChanged<AppTheme> onThemeChanged;
  final bool showTitle;
  final ValueChanged<bool> onShowTitleChanged;
  final bool showTabs;
  final ValueChanged<bool> onShowTabsChanged;
  final bool maintainState;
  final ValueChanged<bool> onMaintainStateChanged;
  final bool animate;
  final ValueChanged<bool> onAnimateChanged;
  final bool showCard;
  final ValueChanged<bool> onShowCardChanged;

  const _ControlBar({
    required this.currentTheme,
    required this.onThemeChanged,
    required this.showTitle,
    required this.onShowTitleChanged,
    required this.showTabs,
    required this.onShowTabsChanged,
    required this.maintainState,
    required this.onMaintainStateChanged,
    required this.animate,
    required this.onAnimateChanged,
    required this.showCard,
    required this.onShowCardChanged,
  });

  static const _themes = [
    (theme: AppTheme.light, label: 'Light'),
    (theme: AppTheme.dark, label: 'Dark'),
    (theme: AppTheme.sunshine, label: 'Sunshine'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Label
          Icon(Icons.widgets_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            'PageScaffold',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 24, color: colorScheme.outline),
          const SizedBox(width: 16),

          // Visibility toggles
          _ToggleChip(
            label: 'Title',
            value: showTitle,
            onChanged: onShowTitleChanged,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Tabs',
            value: showTabs,
            onChanged: onShowTabsChanged,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Keep Alive',
            value: maintainState,
            onChanged: onMaintainStateChanged,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Animate',
            value: animate,
            onChanged: onAnimateChanged,
          ),
          const SizedBox(width: 8),
          _ToggleChip(
            label: 'Card',
            value: showCard,
            onChanged: onShowCardChanged,
          ),

          const Spacer(),

          // Theme switcher
          Text(
            'THEME',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 10),
          for (int i = 0; i < _themes.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            _TabChip(
              label: _themes[i].label,
              selected: currentTheme == _themes[i].theme,
              onTap: () => onThemeChanged(_themes[i].theme),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: value
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.visibility : Icons.visibility_off,
                size: 14,
                color: value
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: value ? FontWeight.w600 : FontWeight.w400,
                  color: value
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Demo Page 1: Table
// ===========================================================================

class TableDemoContent extends StatelessWidget {
  const TableDemoContent({super.key});

  static const _devices = [
    ('Core', 'VLAN-100', 'SW-Core-01', '192.168.1.1', 48, 'L3 Switch'),
    ('Core', 'VLAN-100', 'SW-Core-02', '192.168.1.2', 48, 'L3 Switch'),
    ('Access', 'VLAN-200', 'SW-Access-01', '10.0.10.1', 24, 'L2 Switch'),
    ('Access', 'VLAN-200', 'SW-Access-02', '10.0.10.2', 24, 'L2 Switch'),
    ('DMZ', 'VLAN-300', 'FW-Edge-01', '172.16.0.1', 8, 'Firewall'),
    ('Server', 'VLAN-400', 'SW-Server-01', '10.0.20.1', 48, 'L3 Switch'),
    ('IoT', 'VLAN-500', 'SW-IoT-01', '10.0.30.1', 16, 'L2 Switch'),
    ('WAN', 'VLAN-600', 'RT-WAN-01', '203.0.113.1', 4, 'Router'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Toolbar section
        MainAreaSection(
          label: 'TOOLBAR',
          child: Row(
            children: [
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Device'),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 260,
                height: 36,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search devices...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: colorScheme.outline),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${_devices.length} devices',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Data table section
        MainAreaSection(
          label: 'DATA',
          expanded: true,
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            child: _DeviceTable(devices: _devices),
          ),
        ),

        const SizedBox(height: 12),

        // Pagination section
        MainAreaSection(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing 1-${_devices.length} of ${_devices.length}',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Row(
                children: [
                  _PaginationButton(
                    icon: Icons.chevron_left,
                    enabled: false,
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '1',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                  _PaginationButton(
                    icon: Icons.chevron_right,
                    enabled: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DeviceTable extends StatelessWidget {
  final List<(String, String, String, String, int, String)> devices;

  const _DeviceTable({required this.devices});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    const headers = [
      'Domain',
      'Network',
      'Device Name',
      'IP Address',
      'Ports',
      'Type',
      'Actions',
    ];

    return Column(
      children: [
        // Header row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outline, width: 1),
            ),
          ),
          child: Row(
            children: headers.map((h) {
              return Expanded(
                flex: h == 'Actions' ? 1 : 2,
                child: Text(
                  h,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Data rows
        for (int i = 0; i < devices.length; i++)
          _DeviceRow(device: devices[i], isEven: i.isEven),
      ],
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final (String, String, String, String, int, String) device;
  final bool isEven;

  const _DeviceRow({required this.device, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final cells = [
      device.$1,
      device.$2,
      device.$3,
      device.$4,
      device.$5.toString(),
      device.$6,
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
      decoration: BoxDecoration(
        color: isEven
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          for (final cell in cells)
            Expanded(
              flex: 2,
              child: Text(
                cell,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                _SmallIconButton(
                  icon: Icons.edit_outlined,
                  onTap: () {},
                ),
                const SizedBox(width: 4),
                _SmallIconButton(
                  icon: Icons.delete_outline,
                  onTap: () {},
                  isDestructive: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDestructive;

  const _SmallIconButton({
    required this.icon,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(
          icon,
          size: 16,
          color: isDestructive ? colorScheme.error : colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;

  const _PaginationButton({
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(
        icon,
        size: 18,
        color: enabled ? colorScheme.onSurface : colorScheme.outlineVariant,
      ),
    );
  }
}

// ===========================================================================
// Demo Page 2: Settings
// ===========================================================================

class SettingsDemoContent extends StatefulWidget {
  const SettingsDemoContent({super.key});

  @override
  State<SettingsDemoContent> createState() => _SettingsDemoContentState();
}

class _SettingsDemoContentState extends State<SettingsDemoContent> {
  String _maxFileSize = '100 MB';
  String _retentionDays = '90 days';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Storage limits section
        MainAreaSection(
          label: 'STORAGE LIMITS',
          child: Row(
            children: [
              Expanded(
                child: _SettingsDropdown(
                  label: 'Max Log File Size',
                  value: _maxFileSize,
                  options: const [
                    '50 MB',
                    '100 MB',
                    '200 MB',
                    '500 MB',
                    '1 GB',
                  ],
                  onChanged: (v) => setState(() => _maxFileSize = v),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _SettingsDropdown(
                  label: 'Retention Period',
                  value: _retentionDays,
                  options: const [
                    '30 days',
                    '60 days',
                    '90 days',
                    '180 days',
                    '365 days',
                  ],
                  onChanged: (v) => setState(() => _retentionDays = v),
                ),
              ),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Status section
        MainAreaSection(
          label: 'STATUS',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Disk Usage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '34.2 GB / 100 GB',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: 0.342,
                  minHeight: 10,
                  backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _StatusItem(
                    label: 'System Logs',
                    value: '12.8 GB',
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 32),
                  _StatusItem(
                    label: 'Audit Logs',
                    value: '8.4 GB',
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: 32),
                  _StatusItem(
                    label: 'Alert Logs',
                    value: '13.0 GB',
                    color: colorScheme.tertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _SettingsDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: colorScheme.onSurfaceVariant,
              ),
              dropdownColor: colorScheme.surface,
              items: options
                  .map(
                    (o) => DropdownMenuItem(
                      value: o,
                      child: Text(
                        o,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// Demo Page 3: Dashboard
// ===========================================================================

class DashboardDemoContent extends StatelessWidget {
  const DashboardDemoContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Statistics section
        MainAreaSection(
          label: 'STATISTICS',
          child: Row(
            children: const [
              Expanded(
                child: _StatCard(
                  label: 'Total Devices',
                  value: '128',
                  icon: Icons.devices,
                  trend: '+4 this week',
                  trendPositive: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Online',
                  value: '121',
                  icon: Icons.check_circle_outline,
                  trend: '94.5% uptime',
                  trendPositive: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Warnings',
                  value: '5',
                  icon: Icons.warning_amber_outlined,
                  trend: '-2 from yesterday',
                  trendPositive: true,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'Critical',
                  value: '2',
                  icon: Icons.error_outline,
                  trend: '+1 from yesterday',
                  trendPositive: false,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Recent alerts section
        MainAreaSection(
          label: 'RECENT ALERTS',
          expanded: true,
          child: ListView(
            padding: EdgeInsets.zero,
            children: const [
              _AlertItem(
                severity: _AlertSeverity.critical,
                message: 'SW-Core-01 port Gi0/48 link down',
                timestamp: '2 min ago',
              ),
              _AlertItem(
                severity: _AlertSeverity.critical,
                message: 'FW-Edge-01 CPU utilization above 95%',
                timestamp: '8 min ago',
              ),
              _AlertItem(
                severity: _AlertSeverity.warning,
                message: 'SW-Access-02 memory usage at 82%',
                timestamp: '15 min ago',
              ),
              _AlertItem(
                severity: _AlertSeverity.warning,
                message: 'RT-WAN-01 BGP neighbor flap detected',
                timestamp: '23 min ago',
              ),
              _AlertItem(
                severity: _AlertSeverity.info,
                message: 'SW-Server-01 firmware update available (v4.2.1)',
                timestamp: '1 hour ago',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendPositive;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendPositive,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            trend,
            style: TextStyle(
              fontSize: 12,
              color: trendPositive ? colorScheme.tertiary : colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}

enum _AlertSeverity { critical, warning, info }

class _AlertItem extends StatelessWidget {
  final _AlertSeverity severity;
  final String message;
  final String timestamp;

  const _AlertItem({
    required this.severity,
    required this.message,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color severityColor;
    final IconData severityIcon;
    final String severityLabel;

    switch (severity) {
      case _AlertSeverity.critical:
        severityColor = colorScheme.error;
        severityIcon = Icons.error_outline;
        severityLabel = 'CRITICAL';
      case _AlertSeverity.warning:
        severityColor = colorScheme.secondary;
        severityIcon = Icons.warning_amber_outlined;
        severityLabel = 'WARNING';
      case _AlertSeverity.info:
        severityColor = colorScheme.primary;
        severityIcon = Icons.info_outline;
        severityLabel = 'INFO';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: severityColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: severityColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(severityIcon, size: 18, color: severityColor),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: severityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              severityLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: severityColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
