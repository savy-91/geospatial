// Copyright (c) 2020-2021 Navibyte (https://navibyte.com). All rights reserved.
// Use of this source code is governed by a “BSD-3-Clause”-style license that is
// specified in the LICENSE file.
//
// Docs: https://github.com/navibyte/geospatial

import 'package:equatable/equatable.dart';

import 'package:datatools/client_base.dart';
import 'package:datatools/client_http.dart';

import 'package:geodata/model_common.dart';
import 'package:geodata/source_oapi_features.dart';

/*
To test run this from command line: 

dart --no-sound-null-safety example/meta_example.dart https://demo.pygeoapi.io/master
dart --no-sound-null-safety example/meta_example.dart https://www.ldproxy.nrw.de/kataster
dart --no-sound-null-safety example/meta_example.dart https://weather.obs.fmibeta.com

*/

/// A simple example to read metadata from standard OGC API Features services.
void main(List<String> args) async {
  // configure Equatable to apply toString() default impls
  EquatableConfig.stringify = true;

  // loop over all test URLs (from the arguments) and read meta data for each
  for (var baseURL in args) {
    try {
      final meta = await _readMeta(baseURL);
      _printProvider(meta);
    } catch (e, st) {
      print('Calling $baseURL failed: $e');
      print(st);
    }
  }
}

Future<ProviderMeta> _readMeta(String baseURL) async {
  // Create an API client accessing HTTP endpoints.
  final client = HttpApiClient.endpoints([
    Endpoint.url(baseURL),
  ]);

  // Create a feature provider for OGC API Features (OAPIF).
  final provider = FeatureProviderOAPIF.client(client);

  // Read metadata
  return provider.meta();
}

void _printProvider(ProviderMeta meta) {
  print('');
  print('*****');
  print(meta.title);
  if (meta.description != null) print('  ${meta.description}');
  print('  BaseURL: ${meta.links.byRel('self')?.href}');
  print('  API description: ${meta.links.serviceDesc()?.href}');
  print('');
  print('Conformance classes:');
  meta.conformance.forEach((e) => print('  $e'));
  print('');
  print('Collections:');
  for (var coll in meta.collections) {
    _printCollection(coll);
  }
}

void _printCollection(CollectionMeta meta) {
  print('  ${meta.id} (${meta.title})');
  if (meta.description != null) print('    ${meta.description}');
  final extent = meta.extent;
  if (extent != null) {
    print('    extent crs: ${extent.crs.id}');
    for (var bounds in extent.allBounds) {
      print('    spatial bbox min: ${bounds.min.values}');
      print('    spatial bbox max: ${bounds.max.values}');
    }
    for (var interval in extent.allIntervals) {
      if (!interval.isOpen) {
        print('    temporal interval: $interval');
      }
    }
  }
}
