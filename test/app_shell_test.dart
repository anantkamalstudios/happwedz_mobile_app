// Regression test for the root app-shell Stack in `MyApp.build`'s
// `MaterialApp.builder`.
//
// That Stack used to be written as:
//
//     Stack(children: [
//       if (child != null) child,
//       const ConnectivityOverlay(),
//       MandatoryUpdateGate(navigatorKey: rootNavigatorKey),
//     ])
//
// Flutter matches multi-child lists by index and runtime type. The moment
// `child` flipped to null the list went from three entries to two, both
// overlays moved slot, and the whole Navigator subtree was deactivated in one
// pass — which trips
//
//     'package:flutter/src/widgets/framework.dart': Failed assertion:
//     '_dependents.isEmpty': is not true.
//
// thrown while building the root Overlay, naming this Stack as the
// error-causing widget.
//
// The property that prevents it is simply: the shell always has exactly three
// slots, whatever `builder` is handed. This reproduces the original shape
// rather than importing MyApp, because MyApp's AuthGate needs a live session
// and the bug is in the Stack's structure, not in what fills it.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shell exactly as `MyApp` builds it today.
Widget _shell(Widget? child) => Stack(
      children: [
        KeyedSubtree(
          key: const ValueKey('app.navigator'),
          child: child ?? const SizedBox.shrink(),
        ),
        const SizedBox(key: ValueKey('app.connectivityOverlay')),
        const SizedBox(key: ValueKey('app.updateGate')),
      ],
    );

/// The shape that caused the crash, kept so the test proves the difference
/// rather than merely asserting the current code agrees with itself.
Widget _oldShell(Widget? child) => Stack(
      children: [
        if (child != null) child,
        const SizedBox(key: ValueKey('app.connectivityOverlay')),
        const SizedBox(key: ValueKey('app.updateGate')),
      ],
    );

int _slotCount(WidgetTester tester) {
  final stack = tester.widget<Stack>(find.byType(Stack));
  return stack.children.length;
}

void main() {
  testWidgets('shell keeps three slots whether or not builder passes a child', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _shell(const Text('navigator')),
      ),
    );
    expect(_slotCount(tester), 3);
    expect(find.text('navigator'), findsOneWidget);

    // The rebuild that used to re-slot every sibling.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _shell(null),
      ),
    );
    expect(_slotCount(tester), 3, reason: 'a null child must not shrink the shell');
    expect(tester.takeException(), isNull);

    // ...and back again.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _shell(const Text('navigator')),
      ),
    );
    expect(_slotCount(tester), 3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the overlays keep their slot identity across a null child', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _shell(const Text('navigator')),
      ),
    );

    final connectivityBefore =
        tester.element(find.byKey(const ValueKey('app.connectivityOverlay')));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _shell(null),
      ),
    );

    final connectivityAfter =
        tester.element(find.byKey(const ValueKey('app.connectivityOverlay')));

    // Same Element instance means the subtree was updated in place rather
    // than deactivated and rebuilt — which is the whole point.
    expect(identical(connectivityBefore, connectivityAfter), isTrue);
  });

  testWidgets('the old conditional-child shape did re-slot its siblings', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _oldShell(const Text('navigator')),
      ),
    );
    expect(_slotCount(tester), 3);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: _oldShell(null),
      ),
    );

    // The list really does shrink — this is the condition that let Flutter
    // tear down the Navigator subtree in the same pass as its dependents.
    expect(_slotCount(tester), 2);
  });
}
