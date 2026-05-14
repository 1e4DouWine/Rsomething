import 'package:flutter/material.dart';

abstract final class AdaptiveLayout {
  static const double navigationRailBreakpoint = 600;
  static const double contentMaxWidth = 720;
  static const double sheetMaxWidth = 640;
  static const double dialogMaxWidth = 560;
  static const double compactButtonBreakpoint = 360;

  static bool usesNavigationRail(double width) {
    return width >= navigationRailBreakpoint;
  }

  static double horizontalPaddingForWidth(double width) {
    if (width < 360) return 16;
    if (width < 600) return 20;
    if (width < 840) return 24;
    return 32;
  }

  static EdgeInsets pageInsetsForWidth(
    double width, {
    double top = 16,
    double bottom = 0,
  }) {
    final horizontal = horizontalPaddingForWidth(width);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }

  static EdgeInsets listInsetsForWidth(
    double width, {
    double top = 0,
    double bottom = 100,
  }) {
    final horizontal = horizontalPaddingForWidth(width);
    return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
  }
}

class AdaptiveContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const AdaptiveContent({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.maxWidth = AdaptiveLayout.contentMaxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class AdaptiveSliverBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;

  const AdaptiveSliverBox({
    super.key,
    required this.child,
    this.padding,
    this.maxWidth = AdaptiveLayout.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectivePadding =
        padding ??
        EdgeInsets.symmetric(
          horizontal: AdaptiveLayout.horizontalPaddingForWidth(screenWidth),
        );

    return SliverPadding(
      padding: effectivePadding,
      sliver: SliverToBoxAdapter(
        child: AdaptiveContent(maxWidth: maxWidth, child: child),
      ),
    );
  }
}

class AdaptiveSliverList extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final double itemSpacing;

  const AdaptiveSliverList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.maxWidth = AdaptiveLayout.contentMaxWidth,
    this.itemSpacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final effectivePadding =
        padding ?? AdaptiveLayout.listInsetsForWidth(screenWidth);

    return SliverPadding(
      padding: effectivePadding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return AdaptiveContent(
              maxWidth: maxWidth,
              child: Padding(
                padding: EdgeInsets.only(bottom: itemSpacing),
                child: itemBuilder(context, index),
              ),
            );
          },
          childCount: itemCount,
          addAutomaticKeepAlives: false,
        ),
      ),
    );
  }
}

class AdaptiveButtonGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;

  const AdaptiveButtonGroup({
    super.key,
    required this.children,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < AdaptiveLayout.compactButtonBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1) SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        );
      },
    );
  }
}

class AdaptiveSheetFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const AdaptiveSheetFrame({
    super.key,
    required this.child,
    this.maxWidth = AdaptiveLayout.sheetMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class AdaptiveDialogFrame extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double maxWidth;
  final double maxHeightFactor;

  const AdaptiveDialogFrame({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.maxWidth = AdaptiveLayout.dialogMaxWidth,
    this.maxHeightFactor = 0.85,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
        maxHeight: size.height * maxHeightFactor,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
