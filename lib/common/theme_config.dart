import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThemeConfig {
  static ThemeData midnightLight = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: Color(0xff00296b),
      primaryContainer: Color(0xffa0c2ed),
      secondary: Color(0xffd26900),
      secondaryContainer: Color(0xffffd270),
      tertiary: Color(0xff5c5c95),
      tertiaryContainer: Color(0xffc8dbf8),
      appBarColor: Color(0xffc8dcf8),
      error: null,
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData midnightDark = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: Color(0xffb1cff5),
      primaryContainer: Color(0xff3873ba),
      secondary: Color(0xffffd270),
      secondaryContainer: Color(0xffd26900),
      tertiary: Color(0xffc9cbfc),
      tertiaryContainer: Color(0xff535393),
      appBarColor: Color(0xff00102b),
      error: null,
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData redBlueLight = FlexThemeData.light(
    colors: const FlexSchemeColor(
      primary: Color(0xff1145a4),
      primaryContainer: Color(0xff9fb4da),
      secondary: Color(0xffb61d1d),
      secondaryContainer: Color(0xffe1a4a4),
      tertiary: Color(0xff376bca),
      tertiaryContainer: Color(0xffcfdbf2),
      appBarColor: Color(0xffcfdbf2),
      error: Color(0xffb00020),
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData redBlueDark = FlexThemeData.dark(
    colors: const FlexSchemeColor(
      primary: Color(0xffbbcae5),
      primaryContainer: Color(0xff577cbf),
      secondary: Color(0xffe9bfbf),
      secondaryContainer: Color(0xffcb6060),
      tertiary: Color(0xffdde5f5),
      tertiaryContainer: Color(0xff7297d9),
      appBarColor: Color(0xffdde5f5),
      error: null,
    ),
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData indigoLight = FlexThemeData.light(
    scheme: FlexScheme.indigo,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData indigoDart = FlexThemeData.dark(
    scheme: FlexScheme.indigo,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData hippieBlueLight = FlexThemeData.light(
    scheme: FlexScheme.hippieBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData hippieBlueDart = FlexThemeData.dark(
    scheme: FlexScheme.hippieBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData brandBlueLight = FlexThemeData.light(
    scheme: FlexScheme.brandBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData brandBlueDart = FlexThemeData.dark(
    scheme: FlexScheme.brandBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData deepBlueLight = FlexThemeData.light(
    scheme: FlexScheme.deepBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData deepBlueDart = FlexThemeData.dark(
    scheme: FlexScheme.deepBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData sakuraLight = FlexThemeData.light(
    scheme: FlexScheme.sakura,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData sakuraDart = FlexThemeData.dark(
    scheme: FlexScheme.sakura,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData moneyLight = FlexThemeData.light(
    scheme: FlexScheme.money,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData moneyDart = FlexThemeData.dark(
    scheme: FlexScheme.money,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData blackWhiteLight = FlexThemeData.light(
    scheme: FlexScheme.blackWhite,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  static ThemeData blackWhiteDart = FlexThemeData.dark(
    scheme: FlexScheme.blackWhite,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
    ),
    visualDensity: FlexColorScheme.comfortablePlatformDensity,
    useMaterial3: true,
    swapLegacyOnMaterial3: true,
    // To use the Playground font, add GoogleFonts package and uncomment
    // fontFamily: GoogleFonts.notoSans().fontFamily,
  );

  late ThemeData dark;
  late ThemeData light;
  late String key;
  ThemeConfig({
    required this.key,
    required ThemeData dark,
    required ThemeData light,
  }) {
    var lighticon = IconThemeData(color: light.primaryColor);
    var textstyle = TextStyle(color: light.primaryColor);

    this.dark = dark.copyWith(
      popupMenuTheme: PopupMenuThemeData(
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 30.sp,
          ),
        ),
        menuPadding: EdgeInsets.zero,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
    );

    this.light = light.copyWith(
      iconTheme: lighticon,
      appBarTheme: AppBarTheme(
        iconTheme: lighticon,
        titleTextStyle: textstyle.copyWith(fontSize: 34.w),
        backgroundColor:
            light.appBarTheme.backgroundColor?.withValues(alpha: .4),
      ),
      textTheme: light.textTheme.copyWith(
        titleLarge: textstyle,
        titleMedium: textstyle,
        titleSmall: textstyle,
        bodyLarge: textstyle,
        bodyMedium: textstyle,
        bodySmall: textstyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          side: WidgetStatePropertyAll(
            BorderSide(width: 1.w),
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: light.scaffoldBackgroundColor,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            color: light.primaryColor,
            fontSize: 30.sp,
          ),
        ),
        menuPadding: EdgeInsets.zero,
      ),
      dialogTheme: DialogTheme(
        backgroundColor: light.scaffoldBackgroundColor,
        titleTextStyle: TextStyle(color: light.primaryColor, fontSize: 34.sp),
        contentTextStyle:
            TextStyle(color: light.primaryColorLight, fontSize: 28.sp),
      ),
    );
  }

  static List<ThemeConfig> themes = [
    ThemeConfig(
      key: 'deepBlue',
      dark: deepBlueDart,
      light: deepBlueLight,
    ),
    ThemeConfig(
      key: 'blackWhite',
      dark: blackWhiteDart,
      light: blackWhiteLight,
    ),
    ThemeConfig(
      key: 'midnight',
      dark: midnightDark,
      light: midnightLight,
    ),
    ThemeConfig(
      key: 'redBlue',
      dark: redBlueDark,
      light: redBlueLight,
    ),
    ThemeConfig(
      key: 'indigo',
      dark: indigoDart,
      light: indigoLight,
    ),
    ThemeConfig(
      key: 'hippieBlue',
      dark: hippieBlueDart,
      light: hippieBlueLight,
    ),
    ThemeConfig(
      key: 'brandBlue',
      dark: brandBlueDart,
      light: brandBlueLight,
    ),
    ThemeConfig(
      key: 'sakura',
      dark: sakuraDart,
      light: sakuraLight,
    ),
    ThemeConfig(
      key: 'money',
      dark: moneyDart,
      light: moneyLight,
    ),
  ];
}
