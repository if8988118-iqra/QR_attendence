import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeCtrl,
      builder: (context, _) {
        final cs = Theme.of(context).colorScheme;
        return Scaffold(
          appBar: AppBar(title: const Text('Appearance')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark mode'),
                secondary: const Icon(Icons.dark_mode),
                value: themeCtrl.dark,
                onChanged: themeCtrl.setDark,
              ),
              const Divider(),
              const SizedBox(height: 8),
              const Text('Colour theme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(palettes.length, (i) {
                  final p = palettes[i];
                  final selected = themeCtrl.paletteIndex == i;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => themeCtrl.setPalette(i),
                    child: Container(
                      width: 104,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? cs.primary : Colors.grey.shade400,
                          width: selected ? 3 : 1,
                        ),
                      ),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _dot(p.primary),
                            _dot(p.accent),
                            _dot(p.background, border: true),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(p.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12)),
                        if (selected)
                          Icon(Icons.check_circle, size: 16, color: cs.primary),
                      ]),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text('Font style',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(fontNames.length, (i) {
                  return ChoiceChip(
                    label: Text(
                      fontNames[i],
                      style: i == 0 ? null : GoogleFonts.getFont(fontNames[i]),
                    ),
                    selected: themeCtrl.fontIndex == i,
                    onSelected: (_) => themeCtrl.setFont(i),
                  );
                }),
              ),
              const SizedBox(height: 24),
              Text('Font size: ${(themeCtrl.fontScale * 100).round()}%',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Row(children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    min: 0.8,
                    max: 1.5,
                    divisions: 7,
                    value: themeCtrl.fontScale,
                    label: '${(themeCtrl.fontScale * 100).round()}%',
                    onChanged: themeCtrl.setScale,
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 26)),
              ]),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Preview',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 6),
                      Text('Attendance marked: present',
                          style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 10),
                      FilledButton(
                          onPressed: () {}, child: const Text('Sample button')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Default par wapas jayein'),
                onPressed: themeCtrl.reset,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dot(Color c, {bool border = false}) => Container(
        width: 22,
        height: 22,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: border ? Border.all(color: Colors.grey) : null,
        ),
      );
}
