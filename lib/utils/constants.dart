import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

var theme = FlexThemeData.light(
  scheme: FlexScheme.blue,
  surfaceMode: FlexSurfaceMode.highScaffoldLowSurface,
  blendLevel: 9,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 10,
    blendOnColors: false,
    fabUseShape: true,
    fabSchemeColor: SchemeColor.primary,
    inputDecoratorRadius: 12,
  ),
  useMaterial3ErrorColors: true,
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  swapLegacyOnMaterial3: true,
);

var darkTheme = FlexThemeData.dark(
  scheme: FlexScheme.blue,
  surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
  blendLevel: 15,
  subThemesData: const FlexSubThemesData(
    blendOnLevel: 20,
    fabUseShape: true,
    appBarBackgroundSchemeColor: SchemeColor.background,
    fabSchemeColor: SchemeColor.primary,
    inputDecoratorRadius: 12,
  ),
  useMaterial3ErrorColors: true,
  visualDensity: FlexColorScheme.comfortablePlatformDensity,
  useMaterial3: true,
  swapLegacyOnMaterial3: true,
);

final Widget brokenMagnifyingGlassSvg = SvgPicture.asset(
  "assets/images/broken_magnifying_glass.svg",
  semanticsLabel: "Broken Magnifying Glass",
);
