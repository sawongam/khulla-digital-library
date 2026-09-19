// Copyright (c) 2026 Khulla Digital Library contributors.
// SPDX-License-Identifier: AGPL-3.0-only

/// The sticker stocks the library keeps on the shelf behind the desk.
///
/// The millimetre sizes are the common thermal-label stocks; the logical
/// pixels are the preview's, scaled so the three sit beside each other at
/// roughly the ratio they have in the hand. The millimetre sizes travel with
/// the enum so the print pipeline can lay out the sheet without a second
/// table of stock dimensions.
enum LabelSize {
  /// Spine labels — barcode and shelf mark only.
  small(width: 190, height: 105, mmWidth: 38, mmHeight: 21),

  /// The default accession sticker: title, barcode, shelf mark.
  medium(width: 252, height: 152, mmWidth: 63, mmHeight: 38),

  /// Property labels for oversized stock, with the library's name.
  large(width: 316, height: 182, mmWidth: 99, mmHeight: 57);

  LabelSize({
    required this.width,
    required this.height,
    required this.mmWidth,
    required this.mmHeight,
  });

  /// The preview's width in logical pixels.
  final double width;

  /// The preview's height in logical pixels.
  final double height;

  /// The stock's width in millimetres, for the print pipeline.
  final int mmWidth;

  /// The stock's height in millimetres, for the print pipeline.
  final int mmHeight;
}
