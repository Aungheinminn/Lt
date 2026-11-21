class Language {
  const Language(this.code, this.name, this.nativeName);

  final String code;
  final String name;
  final String nativeName;

  String get label => name == nativeName ? name : '$name · $nativeName';
}

const pinnedLanguageCodes = ['en', 'my'];

const languages = <Language>[
  Language('en', 'English', 'English'),
  Language('my', 'Burmese', 'မြန်မာ'),
  Language('ar', 'Arabic', 'العربية'),
  Language('bn', 'Bengali', 'বাংলা'),
  Language('zh', 'Chinese', '中文'),
  Language('nl', 'Dutch', 'Nederlands'),
  Language('fil', 'Filipino', 'Filipino'),
  Language('fr', 'French', 'Français'),
  Language('de', 'German', 'Deutsch'),
  Language('hi', 'Hindi', 'हिन्दी'),
  Language('id', 'Indonesian', 'Bahasa Indonesia'),
  Language('it', 'Italian', 'Italiano'),
  Language('ja', 'Japanese', '日本語'),
  Language('km', 'Khmer', 'ខ្មែរ'),
  Language('ko', 'Korean', '한국어'),
  Language('lo', 'Lao', 'ລາວ'),
  Language('ms', 'Malay', 'Bahasa Melayu'),
  Language('pt', 'Portuguese', 'Português'),
  Language('ru', 'Russian', 'Русский'),
  Language('es', 'Spanish', 'Español'),
  Language('ta', 'Tamil', 'தமிழ்'),
  Language('th', 'Thai', 'ไทย'),
  Language('tr', 'Turkish', 'Türkçe'),
  Language('uk', 'Ukrainian', 'Українська'),
  Language('ur', 'Urdu', 'اردو'),
  Language('vi', 'Vietnamese', 'Tiếng Việt'),
];

Language languageFor(String code) =>
    languages.firstWhere((l) => l.code == code, orElse: () => languages.first);
