import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

/// Usage inside any build() method:
///   context.tr('English text', 'اردو متن')
extension Tr on BuildContext {
  String tr(String en, String ur) =>
      watch<LanguageProvider>().isUrdu ? ur : en;

  bool get isUrdu => watch<LanguageProvider>().isUrdu;
}
