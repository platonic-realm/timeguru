import 'package:flutter/material.dart';

class ResponsiveUtils {
  static MediaQueryData? _mediaQuery;
  static double? _screenWidth;
  static double? _screenHeight;
  static double? _aspectRatio;
  static bool _initialized = false;

  static void init(BuildContext context) {
    if (_initialized) return; // Prevent multiple initializations
    
    try {
      _mediaQuery = MediaQuery.of(context);
      _screenWidth = _mediaQuery!.size.width;
      _screenHeight = _mediaQuery!.size.height;
      _aspectRatio = _screenWidth! / _screenHeight!;
      _initialized = true;
    } catch (e) {
      // Fallback to default values if initialization fails
      _screenWidth = 800.0;
      _screenHeight = 600.0;
      _aspectRatio = 1.33;
      _initialized = true;
    }
  }

  // Safe getters with fallbacks
  static double get screenWidth => _screenWidth ?? 800.0;
  static double get screenHeight => _screenHeight ?? 600.0;
  static double get aspectRatio => _aspectRatio ?? 1.33;
  static bool get isPortrait => (screenHeight > screenWidth);
  static bool get isLandscape => (screenWidth > screenHeight);

  // Responsive breakpoints
  static bool get isMobile => screenWidth < 600;
  static bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  static bool get isDesktop => screenWidth >= 1200;
  static bool get isSmallScreen => screenWidth < 400;
  static bool get isLargeScreen => screenWidth >= 1200;

  // Dynamic sizing based on screen dimensions
  static double getScaledSize(double baseSize) {
    if (isSmallScreen) return baseSize * 0.8;
    if (isMobile) return baseSize * 0.9;
    if (isTablet) return baseSize * 1.1;
    if (isLargeScreen) return baseSize * 1.3;
    return baseSize;
  }

  // Responsive padding and margins
  static EdgeInsets getResponsivePadding({
    double horizontal = 16.0,
    double vertical = 16.0,
    double smallScreenMultiplier = 0.8,
    double largeScreenMultiplier = 1.2,
  }) {
    if (isSmallScreen) {
      return EdgeInsets.symmetric(
        horizontal: horizontal * smallScreenMultiplier,
        vertical: vertical * smallScreenMultiplier,
      );
    }
    if (isLargeScreen) {
      return EdgeInsets.symmetric(
        horizontal: horizontal * largeScreenMultiplier,
        vertical: vertical * largeScreenMultiplier,
      );
    }
    return EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);
  }

  // Responsive spacing
  static double getResponsiveSpacing(double baseSpacing) {
    if (isSmallScreen) return baseSpacing * 0.7;
    if (isMobile) return baseSpacing * 0.85;
    if (isTablet) return baseSpacing * 1.1;
    if (isLargeScreen) return baseSpacing * 1.4;
    return baseSpacing;
  }

  // Responsive font sizes
  static double getResponsiveFontSize(double baseSize) {
    if (isSmallScreen) return baseSize * 0.85;
    if (isMobile) return baseSize * 0.9;
    if (isTablet) return baseSize * 1.05;
    if (isLargeScreen) return baseSize * 1.2;
    return baseSize;
  }

  // Responsive icon sizes
  static double getResponsiveIconSize(double baseSize) {
    if (isSmallScreen) return baseSize * 0.8;
    if (isMobile) return baseSize * 0.9;
    if (isTablet) return baseSize * 1.05;
    if (isLargeScreen) return baseSize * 1.15;
    return baseSize;
  }

  // Responsive card heights
  static double getResponsiveCardHeight(double baseHeight) {
    if (isSmallScreen) return baseHeight * 0.8;
    if (isMobile) return baseHeight * 0.9;
    if (isTablet) return baseHeight * 1.05;
    if (isLargeScreen) return baseHeight * 1.1;
    return baseHeight;
  }

  // Responsive grid configurations
  static int getResponsiveGridColumns() {
    if (isSmallScreen) return 2;
    if (isMobile) return 2;
    if (isTablet) return 3;
    if (isLargeScreen) return 4;
    return 3;
  }

  static double getResponsiveGridAspectRatio() {
    if (isSmallScreen) return 1.8;
    if (isMobile) return 2.0;
    if (isTablet) return 2.5;
    if (isLargeScreen) return 3.0;
    return 2.5;
  }

  // Responsive summary heights
  static double getResponsiveSummaryHeight() {
    final baseHeight = screenHeight * 0.35;
    if (isSmallScreen) return baseHeight.clamp(250.0, 350.0);
    if (isMobile) return baseHeight.clamp(280.0, 380.0);
    if (isTablet) return baseHeight.clamp(320.0, 420.0);
    if (isLargeScreen) return baseHeight.clamp(350.0, 450.0);
    return baseHeight.clamp(280.0, 400.0);
  }

  // Responsive container heights
  static double getResponsiveContainerHeight(double baseHeight) {
    if (isSmallScreen) return baseHeight * 0.8;
    if (isMobile) return baseHeight * 0.9;
    if (isTablet) return baseHeight * 1.0;
    if (isLargeScreen) return baseHeight * 1.1;
    return baseHeight;
  }

  // Responsive border radius
  static double getResponsiveBorderRadius(double baseRadius) {
    if (isSmallScreen) return baseRadius * 0.8;
    if (isMobile) return baseRadius * 0.9;
    if (isTablet) return baseRadius * 1.0;
    if (isLargeScreen) return baseRadius * 1.1;
    return baseRadius;
  }

  // Responsive elevation
  static double getResponsiveElevation(double baseElevation) {
    if (isSmallScreen) return baseElevation * 0.8;
    if (isMobile) return baseElevation * 0.9;
    if (isTablet) return baseElevation * 1.0;
    if (isLargeScreen) return baseElevation * 1.1;
    return baseElevation;
  }

  // Check if content might overflow
  static bool mightOverflow(double contentHeight, double availableHeight) {
    return contentHeight > availableHeight;
  }

  // Get safe content height
  static double getSafeContentHeight(double maxHeight, double padding) {
    return maxHeight - (padding * 2);
  }

  // Responsive text styles
  static TextStyle getResponsiveTextStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: getResponsiveFontSize(fontSize),
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Responsive button styles
  static ButtonStyle getResponsiveButtonStyle({
    double? padding,
    double? borderRadius,
    double? elevation,
  }) {
    return ElevatedButton.styleFrom(
      padding: EdgeInsets.all(padding ?? getResponsiveSpacing(16)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? getResponsiveBorderRadius(8),
        ),
      ),
      elevation: elevation ?? getResponsiveElevation(2),
    );
  }

  // Reset initialization (useful for testing or hot reload)
  static void reset() {
    _initialized = false;
    _mediaQuery = null;
    _screenWidth = null;
    _screenHeight = null;
    _aspectRatio = null;
  }
}
