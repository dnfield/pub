// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';

import '../io.dart';
import '../sdk.dart';

/// The Dart SDK.
///
/// Unlike other SDKs, this is always available.
class DartSdk extends Sdk {
  String get name => "Dart";
  bool get isAvailable => true;
  String get installMessage => null;
  Version get firstPubVersion => Version.none;

  /// The path to the root directory of the SDK.
  ///
  /// Note that if pub is running from source within the Dart repo (for example
  /// when building Observatory), this will be the repo's "sdk/" directory,
  /// which doesn't look exactly like the built SDK.
  static final String _rootDirectory = () {
    if (runningFromDartRepo) return p.join(dartRepoRoot, 'sdk');

    // The Dart exectuable is in "/path/to/sdk/bin/dart", so two levels up is
    // "/path/to/sdk".
    var aboveExecutable = p.dirname(p.dirname(Platform.resolvedExecutable));
    assert(fileExists(p.join(aboveExecutable, 'version')));
    return aboveExecutable;
  }();

  final Version version = () {
    // Some of the pub integration tests require an SDK version number, but the
    // tests on the bots are not run from a built SDK so this lets us avoid
    // parsing the missing version file.
    var sdkVersion = Platform.environment["_PUB_TEST_SDK_VERSION"];
    if (sdkVersion != null) return new Version.parse(sdkVersion);

    if (!runningFromDartRepo) {
      var version = Platform.version.split(' ').first;
      return new Version.parse(version);
    }

    // When running from the Dart repo, read the canonical VERSION file in
    // tools/. This makes it possible to run pub without having built the SDK
    // first.
    var contents = readTextFile(p.join(dartRepoRoot, "tools/VERSION"));

    parseField(name) {
      var pattern = new RegExp("^$name ([a-z0-9]+)", multiLine: true);
      var match = pattern.firstMatch(contents);
      return match[1];
    }

    var channel = parseField("CHANNEL");
    var major = parseField("MAJOR");
    var minor = parseField("MINOR");
    var patch = parseField("PATCH");
    var prerelease = parseField("PRERELEASE");
    var prereleasePatch = parseField("PRERELEASE_PATCH");

    var version = "$major.$minor.$patch";
    if (channel == "be") {
      // TODO(rnystrom): tools/utils.py includes the svn commit here. Should we?
      version += "-edge";
    } else if (channel == "dev") {
      version += "-dev.$prerelease.$prereleasePatch";
    }

    return new Version.parse(version);
  }();

  String get rootDirectory => _rootDirectory;

  String packagePath(String name) => null;
}
