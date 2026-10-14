import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

const showcaseLocales = [Locale('en'), Locale('de')];

const _strings = {
  'en': (title: 'Settings', notifications: 'Notifications', dark: 'Dark mode'),
  'de': (
    title: 'Einstellungen',
    notifications: 'Benachrichtigungen',
    dark: 'Dunkelmodus',
  ),
};

/// App following the platform brightness and locale, used to showcase
/// `testAdaptiveThemedWidgets` and `setLocalizedDeviceVariants`.
class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        fontFamily: 'roboto',
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
        fontFamily: 'roboto',
      ),
      supportedLocales: showcaseLocales,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const _SettingsPage(),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final strings = _strings[languageCode] ?? _strings['en']!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(strings.title)),
      body: ListView(
        children: [
          SwitchListTile(
            value: true,
            onChanged: (_) {},
            title: Text(strings.notifications),
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            value: isDark,
            onChanged: (_) {},
            title: Text(strings.dark),
            secondary: const Icon(Icons.dark_mode),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(languageCode.toUpperCase()),
          ),
        ],
      ),
    );
  }
}
