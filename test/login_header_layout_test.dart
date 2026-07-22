import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallconnect_stall_owner/widgets/login_header.dart';

void main() {
  // The logo lockup must be centred and must not reflow when the PNG decodes.
  // Giving Image.asset only a height makes it lay out at zero width until the
  // image loads, which shifts the whole row sideways on the first frames.
  testWidgets('logo lockup is centred and stable before the image decodes',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 3216);
    tester.view.devicePixelRatio = 3.2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoginHeader())),
    );

    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final mark = tester.getRect(find.byType(Image));
    final wordmark = tester.getRect(find.byType(RichText).first);
    final lockup = mark.expandToInclude(wordmark);

    // Laid out at its declared size without waiting on the decode.
    expect(mark.width, 46.0);
    expect(mark.height, 56.0);

    // Lockup sits on the horizontal centre of the screen.
    expect(lockup.center.dx, closeTo(screenWidth / 2, 0.5));

    // Mark leads the wordmark and they do not overlap.
    expect(mark.right, lessThanOrEqualTo(wordmark.left));

    // Nothing runs off the edge of the screen.
    expect(lockup.left, greaterThanOrEqualTo(0));
    expect(lockup.right, lessThanOrEqualTo(screenWidth));
  });

  testWidgets('lockup stays on screen on a narrow device', (tester) async {
    tester.view.physicalSize = const Size(720, 1280);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: LoginHeader())),
    );

    final screenWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    final lockup = tester
        .getRect(find.byType(Image))
        .expandToInclude(tester.getRect(find.byType(RichText).first));

    expect(lockup.left, greaterThanOrEqualTo(0));
    expect(lockup.right, lessThanOrEqualTo(screenWidth));
    expect(lockup.center.dx, closeTo(screenWidth / 2, 0.5));
  });
}
