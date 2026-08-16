import 'package:flutter/material.dart';

/// Fizyka przewijania, która "zatrzaskuje" listę na kolejnych elementach
/// o stałej szerokości [itemExtent] — daje efekt karuzeli w poziomej liście.
class SnapScrollPhysics extends ScrollPhysics {
  const SnapScrollPhysics({required this.itemExtent, super.parent});

  final double itemExtent;

  @override
  SnapScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnapScrollPhysics(
      itemExtent: itemExtent,
      parent: buildParent(ancestor),
    );
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final page = position.pixels / itemExtent;
    final targetPage = velocity.abs() > tolerance.velocity
        ? (velocity > 0 ? page.ceilToDouble() : page.floorToDouble())
        : page.roundToDouble();
    final target = (targetPage * itemExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((target - position.pixels).abs() < tolerance.distance) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  bool get allowImplicitScrolling => false;
}
