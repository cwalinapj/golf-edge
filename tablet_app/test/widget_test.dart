import 'package:flutter_test/flutter_test.dart';

import 'package:golf_edge_tablet/app.dart';

void main() {
  testWidgets('renders the Wi-Fi setup shell', (tester) async {
    await tester.pumpWidget(const GolfEdgeApp());

    expect(find.text('Golf Edge'), findsOneWidget);
    expect(find.text('Mevo Wi-Fi'), findsOneWidget);
    expect(find.text('Binding'), findsOneWidget);
    expect(find.text('Scan'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });
}
