import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? maxWidth;
  final double? maxHeight;
  final bool enableOverflowProtection;
  final bool enableResponsiveScaling;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth,
    this.maxHeight,
    this.enableOverflowProtection = true,
    this.enableResponsiveScaling = true,
  });

  @override
  Widget build(BuildContext context) {
    // Initialize responsive utilities
    ResponsiveUtils.init(context);
    
    Widget wrappedChild = child;
    
    // Apply responsive scaling if enabled
    if (enableResponsiveScaling) {
      wrappedChild = _applyResponsiveScaling(wrappedChild);
    }
    
    // Apply overflow protection if enabled
    if (enableOverflowProtection) {
      wrappedChild = _applyOverflowProtection(wrappedChild);
    }
    
    // Apply responsive padding
    if (padding != null) {
      wrappedChild = Padding(
        padding: ResponsiveUtils.getResponsivePadding(
          horizontal: padding!.horizontal,
          vertical: padding!.vertical,
        ),
        child: wrappedChild,
      );
    }
    
    // Apply size constraints
    if (maxWidth != null || maxHeight != null) {
      wrappedChild = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? double.infinity,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: wrappedChild,
      );
    }
    
    return wrappedChild;
  }

  Widget _applyResponsiveScaling(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: constraints.maxWidth,
              maxHeight: constraints.maxHeight,
            ),
            child: child,
          ),
        );
      },
    );
  }

  Widget _applyOverflowProtection(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxWidth: constraints.maxWidth,
            ),
            child: IntrinsicHeight(
              child: child,
            ),
          ),
        );
      },
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final double? borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? boxShadow;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.borderRadius,
    this.backgroundColor,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    
    return Card(
      elevation: elevation ?? ResponsiveUtils.getResponsiveElevation(2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          borderRadius ?? ResponsiveUtils.getResponsiveBorderRadius(12),
        ),
        side: border != null ? BorderSide(
          color: border!.top.color,
          width: border!.top.width,
        ) : BorderSide.none,
      ),
      color: backgroundColor,
      shadowColor: Theme.of(context).colorScheme.shadow,
      child: Padding(
        padding: padding ?? ResponsiveUtils.getResponsivePadding(),
        child: child,
      ),
    );
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final double? borderRadius;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.border,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    
    return Container(
      width: width,
      height: height,
      padding: padding ?? ResponsiveUtils.getResponsivePadding(),
      margin: margin,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius != null 
            ? BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(borderRadius!))
            : null,
        border: border,
        boxShadow: boxShadow,
        gradient: gradient,
      ),
      child: child,
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final double? height;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    required this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.height,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    
    return Text(
      text,
      style: ResponsiveUtils.getResponsiveTextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: height,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    
    return Icon(
      icon,
      size: ResponsiveUtils.getResponsiveIconSize(size),
      color: color,
    );
  }
}

class ResponsiveSpacing extends StatelessWidget {
  final double size;
  final bool isHorizontal;

  const ResponsiveSpacing(
    this.size, {
    super.key,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    ResponsiveUtils.init(context);
    
    final responsiveSize = ResponsiveUtils.getResponsiveSpacing(size);
    
    if (isHorizontal) {
      return SizedBox(width: responsiveSize);
    } else {
      return SizedBox(height: responsiveSize);
    }
  }
}
