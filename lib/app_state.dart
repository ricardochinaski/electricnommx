import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fuente de verdad única para el tema de la aplicación.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

/// Notificador global para los marcadores (bookmarks).
final ValueNotifier<List<String>> globalBookmarksNotifier = ValueNotifier<List<String>>([]);

/// Notificador global para la vista de calculadoras (true = lista, false = cuadros/grid).
final ValueNotifier<bool> calculatorViewNotifier = ValueNotifier<bool>(true);

/// Notificador global para las notas rápidas.
final ValueNotifier<List<String>> notesNotifier = ValueNotifier<List<String>>([]);

/// Notificador global para la vista de pliegos (true = lista, false = cuadros/grid).
final ValueNotifier<bool> normsViewNotifier = ValueNotifier<bool>(true);

/// Notificador para seleccionar sub-pestaña desde Inicio (true = RIC, false = RPTD)
final ValueNotifier<bool> normasIsRicNotifier = ValueNotifier<bool>(true);

/// Notificador para seleccionar sub-pestaña desde Inicio (0 = Calculadoras, 1 = Utilidades)
final ValueNotifier<int> herramientasTabNotifier = ValueNotifier<int>(0);

/// Carga los marcadores globales desde SharedPreferences.
Future<void> loadGlobalBookmarks() async {
  final prefs = await SharedPreferences.getInstance();
  globalBookmarksNotifier.value = prefs.getStringList('bookmarks') ?? [];
  calculatorViewNotifier.value = prefs.getBool('calculator_list_view') ?? true;
  normsViewNotifier.value = prefs.getBool('norms_list_view') ?? true;
  notesNotifier.value = prefs.getStringList('quick_notes') ?? [];
}

/// Guarda la preferencia de vista de calculadoras.
Future<void> saveCalculatorViewPreference(bool isListView) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('calculator_list_view', isListView);
  calculatorViewNotifier.value = isListView;
}

/// Guarda la preferencia de vista de pliegos.
Future<void> saveNormsViewPreference(bool isListView) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('norms_list_view', isListView);
  normsViewNotifier.value = isListView;
}

/// Guarda las notas rápidas.
Future<void> saveNotes(List<String> notes) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('quick_notes', notes);
  notesNotifier.value = notes;
}
