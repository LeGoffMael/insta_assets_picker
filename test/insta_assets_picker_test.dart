import 'package:flutter_test/flutter_test.dart';
import 'package:insta_assets_picker/insta_assets_picker.dart';
import 'package:insta_assets_picker/src/insta_assets_crop_controller.dart';

void main() {
  test('Ensure nextCropRatio() loop', () {
    final InstaAssetsCropController controller =
        InstaAssetsCropController(false, const InstaAssetCropDelegate());

    expect(controller.aspectRatio, 1);
    expect(controller.aspectRatioString, '1:1');

    controller.nextCropRatio();

    expect(controller.aspectRatio, 4 / 5);
    expect(controller.aspectRatioString, '4:5');

    controller.nextCropRatio();

    expect(controller.aspectRatio, 1);
    expect(controller.aspectRatioString, '1:1');
  });
}
