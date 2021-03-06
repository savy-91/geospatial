// Copyright (c) 2020-2021 Navibyte (https://navibyte.com). All rights reserved.
// Use of this source code is governed by a “BSD-3-Clause”-style license that is
// specified in the LICENSE file.
//
// Docs: https://github.com/navibyte/geospatial

part of 'base.dart';

/// A function to calculate bounds for some object like a geometry.
typedef CalculateBounds<T extends Point> = Bounds<T> Function();

/// A base interface for bounds (aka a bounding box in 2D).
abstract class Bounds<T extends Point> extends Geometry
    implements _Coordinates, CoordinateFactory<Bounds> {
  const Bounds();

  /// Create bounds with required (and non-empty) [min] and [max] points.
  factory Bounds.of({required T min, required T max}) = BoundsBase;

  /// Return an [empty] bounds that does not intersect with any other bounds.
  static Bounds empty() => _emptyBounds;

  /// Minimum point of bounds.
  T get min;

  /// Maximum point of bounds.
  T get max;

  @override
  Bounds get bounds => this;

  @override
  int get dimension => 1;

  @override
  int get coordinateDimension =>
      math.min(min.coordinateDimension, max.coordinateDimension);

  @override
  int get spatialDimension =>
      math.min(min.spatialDimension, max.spatialDimension);

  @override
  bool get is3D => min.is3D && max.is3D;

  @override
  bool get hasM => min.hasM && max.hasM;

  /// Returns true if this bounds intesects with [other] bounds in 2D.
  ///
  /// Only X ja Y are compared on intersection calculation.
  ///
  /// If this bounds or [other] bounds is empty, then always return false.
  bool intersects2D(Bounds other) {
    if (isEmpty || other.isEmpty) return false;
    return !(min.x > other.max.x ||
        max.x < other.min.x ||
        min.y > other.max.y ||
        max.y < other.min.y);
  }

  /// Returns true if this bounds intesects with [other] bounds.
  ///
  /// X ja Y are always compared on intersection calculation. Z is compared only
  /// if this and [other] bounds has 3D coordinates. M is compared only if this
  /// and [other] bounds has M coordinate values.
  ///
  /// If this bounds or [other] bounds is empty, then always return false.
  bool intersects(Bounds other) {
    if (isEmpty || other.isEmpty) return false;
    if (min.x > other.max.x ||
        max.x < other.min.x ||
        min.y > other.max.y ||
        max.y < other.min.y) {
      return false;
    }
    if (is3D && other.is3D && min.z > other.max.z || max.z < other.min.z) {
      return false;
    }
    if (hasM && other.hasM && min.m > other.max.m || max.m < other.min.m) {
      return false;
    }
    return true;
  }

  /// Returns true if this bounds intesects with [point] in 2D.
  ///
  /// Only X ja Y are compared on intersection calculation.
  ///
  /// If this bounds or [point] is empty, then always return false.
  bool intersectsPoint2D(Point point) {
    if (isEmpty || point.isEmpty) return false;
    return !(min.x > point.x ||
        max.x < point.x ||
        min.y > point.y ||
        max.y < point.y);
  }

  /// Returns true if this bounds intesects with [point].
  ///
  /// X ja Y are always compared on intersection calculation. Z is compared only
  /// if this bounds and [point] has 3D coordinates. M is compared only if this
  /// bounds and [point] has M coordinate values.
  ///
  /// If this bounds or [point] is empty, then always return false.
  bool intersectsPoint(Point point) {
    if (isEmpty || point.isEmpty) return false;
    if (min.x > point.x ||
        max.x < point.x ||
        min.y > point.y ||
        max.y < point.y) {
      return false;
    }
    if (is3D && point.is3D && min.z > point.z || max.z < point.z) {
      return false;
    }
    if (hasM && point.hasM && min.m > point.m || max.m < point.m) {
      return false;
    }
    return true;
  }
}

/// An immutable bounds with min and max points for limits.
@immutable
class BoundsBase<T extends Point> extends Bounds<T> with EquatableMixin {
  /// Create bounds with required (and non-empty) [min] and [max] points.
  const BoundsBase({required T min, required T max})
      : _min = min,
        _max = max;

  final T _min, _max;

  @override
  List<Object?> get props => [_min, _max];

  @override
  bool get isEmpty => false;

  @override
  T get min => _min;

  @override
  T get max => _max;

  @override
  Bounds newFrom(Iterable<num> coords, {int? offset, int? length}) {
    CoordinateFactory.checkCoords(4, coords, offset: offset, length: length);
    final start = offset ?? 0;
    final len = length ?? coords.length;
    final pointLen = len ~/ 2;
    return BoundsBase(
        min: min.newFrom(coords, offset: start, length: pointLen),
        max: max.newFrom(coords, offset: start + pointLen, length: pointLen));
  }
}

/// [Bounds] with values calculated when first needed if not initialized.
class _LazyBounds<T extends Point> extends Bounds<T> {
  /// Bounds with nullable [bounds] and a mechanism to [calculate] as needed.
  ///
  /// You must provide either [bounds] or [calculate], both of them cannot be
  /// null.
  _LazyBounds(Bounds<T>? bounds, CalculateBounds<T>? calculate)
      : _bounds = _validate<T>(bounds, calculate),
        _calculate = calculate;

  /// Initially unset bounds, but with a mechanism to [calculate] it as needed.
  factory _LazyBounds.calculate(CalculateBounds<T> calculate) =>
      _LazyBounds(null, calculate);

  static Bounds<T>? _validate<T extends Point>(
      Bounds<T>? bounds, final CalculateBounds<T>? calculate) {
    if (bounds == null && calculate == null) {
      throw ArgumentError('You must provide either bounds or calculate!');
    }
    return bounds;
  }

  Bounds<T>? _bounds;

  final CalculateBounds<T>? _calculate;

  Bounds<T> _ensureBounds() => _bounds ??= _calculate!.call();

  @override
  bool get isEmpty => false;

  @override
  T get min => _ensureBounds().min;

  @override
  T get max => _ensureBounds().max;

  @override
  Bounds newFrom(Iterable<num> coords, {int? offset, int? length}) =>
      _ensureBounds().newFrom(coords, offset: offset, length: length);

  @override
  bool operator ==(Object other) => _ensureBounds() == other;

  @override
  int get hashCode => _ensureBounds().hashCode;
}

const _emptyBounds = _EmptyBounds();

@immutable
class _EmptyBounds extends Bounds {
  const _EmptyBounds();

  @override
  bool get isEmpty => true;

  @override
  bool get isNotEmpty => false;

  @override
  Point get min => Point.empty();

  @override
  Point get max => Point.empty();

  @override
  Bounds newFrom(Iterable<num> coords, {int? offset, int? length}) => this;
}
