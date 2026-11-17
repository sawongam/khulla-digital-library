// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:khulla/shared/presentation/cubit/library_features_cubit.dart';

/// The library's feature switches, read from a build method.
extension LibraryFeaturesContext on BuildContext {
  /// Whether fines appear in the interface. Rebuilds the caller when the
  /// library turns them on or off, so call it from `build`.
  bool get chargesFines =>
      select<LibraryFeaturesCubit, bool>((cubit) => cubit.state.chargesFines);
}
