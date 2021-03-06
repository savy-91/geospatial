// Copyright (c) 2020-2021 Navibyte (https://navibyte.com). All rights reserved.
// Use of this source code is governed by a “BSD-3-Clause”-style license that is
// specified in the LICENSE file.
//
// Docs: https://github.com/navibyte/geospatial

import 'dart:convert';

import 'package:attributes/entity.dart';

import '../../base.dart';
import '../../geo.dart';
import '../../feature.dart';
import '../factory.dart';

/// The default GeoJSON factory instace assuming geographic CRS80 coordinates.
///
/// Result type candidates for point objects: [GeoPoint2], [GeoPoint3].
const geoJSON = GeoJsonFactory<GeoPoint>(
  pointFactory: geoPointFactory,
  boundsFactory: geoBoundsFactory,
);

/// The default GeoJSON factory instace assuming projected coordinates.
///
/// Result type candidates for point objects: [Point2], [Point3].
const geoJSONProjected = GeoJsonFactory<Point>(
  pointFactory: projectedPointFactory,
  boundsFactory: anyBoundsFactory,
);

/// The default [CreateFeature] forwarding directly to Feature.view() factory.
///
/// This factory omits [jsonObject] parameter.
Feature<T> _defaultFeatureFactory<T extends Geometry>(
        {dynamic? id,
        required Map<String, dynamic> properties,
        T? geometry,
        Bounds? bounds,
        Map<String, dynamic>? jsonObject}) =>
    Feature<T>.view(
        id: id, properties: properties, geometry: geometry, bounds: bounds);

/// A geospatial object factory capable of parsing GeoJSON data from json.
///
/// The implementation expects JSON objects to be compatible with objects
/// generated by the standard `json.decode()`.
///
/// Methods geometry(), feature(), featureSeries() and featureCollections()
/// accepts data object to be either a String (containing valid GeoJSON) or
/// object tree generated by the standard `json.decode()`.
///
/// See [The GeoJSON Format - RFC 7946](https://tools.ietf.org/html/rfc7946).
class GeoJsonFactory<PointType extends Point>
    extends GeoFactoryBase<PointType> {
  const GeoJsonFactory(
      {required PointFactory<PointType> pointFactory,
      required CreateBounds<PointType> boundsFactory,
      CreateFeature featureFactory = _defaultFeatureFactory})
      : super(
          pointFactory: pointFactory,
          boundsFactory: boundsFactory,
          featureFactory: featureFactory,
        );

  Map<String, dynamic> _ensureDecodedMap(dynamic data) {
    if (data is String) {
      try {
        data = json.decode(data);
      } catch (e) {
        throw FormatException('Unknown encoding for GeoJSON ($e).');
      }
    }
    if (data is Map<String, dynamic>) {
      return data;
    }
    throw FormatException('Unknown encoding for GeoJSON.');
  }

  Iterable _ensureDecodedList(dynamic data) {
    if (data is String) {
      try {
        data = json.decode(data);
      } catch (e) {
        throw FormatException('Unknown encoding for GeoJSON ($e).');
      }
    }
    if (data is Iterable) {
      return data;
    }
    throw FormatException('Unknown encoding for GeoJSON.');
  }

  @override
  T geometry<T extends Geometry>(dynamic data) {
    // expects data of Map<String, dynamic> as returned by json.decode()
    final json = _ensureDecodedMap(data);
    var geom;
    switch (json['type']) {
      case 'Point':
        geom = point(json['coordinates']);
        break;
      case 'LineString':
        geom = lineString(json['coordinates']);
        break;
      case 'Polygon':
        geom = polygon(json['coordinates']);
        break;
      case 'MultiPoint':
        geom = multiPoint(json['coordinates']);
        break;
      case 'MultiLineString':
        geom = multiLineString(json['coordinates']);
        break;
      case 'MultiPolygon':
        geom = multiPolygon(json['coordinates']);
        break;
      case 'GeometryCollection':
        geom = geometryCollection(json['geometries']);
        break;
    }
    if (geom is T) {
      return geom;
    }
    throw FormatException('Not valid GeoJSON geometry.');
  }

  @override
  Feature<T> feature<T extends Geometry>(dynamic data) {
    // expects data of Map<String, dynamic> as returned by json.decode()
    final json = _ensureDecodedMap(data);
    if (json['type'] != 'Feature') {
      throw FormatException('Not valid GeoJSON Feature.');
    }

    // parse id as FeatureId or null
    // - id read from GeoJSON is null : null as id
    // - id read from GeoJSON is int : wrap on Identifier
    // - otherwise : convert read value to String and wrap on Identifier
    // (GeoJSON allows num and String types for ids)
    final idJson = json['id'];
    final id = idJson != null
        ? Identifier.from(idJson is int ? idJson : idJson.toString())
        : null;

    // parse optional geometry for this feature
    final geomJson = json['geometry'];
    final geom = geomJson != null ? geometry<T>(geomJson) : null;

    // parse optional bbox
    // (bbox is not required on GeoJSON and not on Feature either)
    final bboxJson = json['bbox'];
    final bbox = bboxJson != null ? bounds(bboxJson) : null;

    // create a feature using the factory function
    return featureFactory<T>(
      // nullable id
      id: id,

      // map of properties may be missing on GeoJSON, but for a feature
      // non-null map (even empty) is required
      properties: json['properties'] ?? {},

      // nullable geometry object
      geometry: geom,

      // nullable bounds object
      bounds: bbox,

      // the JSON Object from source data provided as-is
      // (this lets custom feature factories to parse properties not known by
      //  the JSON specification)
      jsonObject: json,
    );
  }

  @override
  BoundedSeries<Feature<T>> featureSeries<T extends Geometry>(dynamic data) {
    // expects data of List as returned by json.decode()
    final json = _ensureDecodedList(data);
    return BoundedSeries<Feature<T>>.from(
        json.map<Feature<T>>((f) => feature<T>(f)));
  }

  @override
  FeatureCollection<Feature<T>> featureCollection<T extends Geometry>(
      dynamic data) {
    // expects data of Map<String, dynamic> as returned by json.decode()
    final json = _ensureDecodedMap(data);

    if (json['type'] == 'Feature') {
      // just single feature, not collection, but return as a collection anyway
      return FeatureCollection<Feature<T>>.of(
        features: BoundedSeries<Feature<T>>.from([feature<T>(json)]),
      );
    } else {
      // excepting a collection
      if (json['type'] != 'FeatureCollection') {
        throw FormatException('Not valid GeoJSON FeatureCollection.');
      }

      // parse optional bbox
      // (bbox is not required on GeoJSON and not on FeatureCollection either)
      final bboxJson = json['bbox'];
      final bbox = bboxJson != null ? bounds(bboxJson) : null;

      // create a feature collection
      return FeatureCollection<Feature<T>>.of(
        // required series of features (allowed to be empty)
        features: featureSeries<T>(json['features']),

        // nullable bounds object
        bounds: bbox,
      );
    }
  }
}
