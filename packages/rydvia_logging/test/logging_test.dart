import 'package:test/test.dart';
import 'package:rydvia_logging/rydvia_logging.dart';

void main() {
  test('only event type and timestamp reach logging sink', () {
    Map<String, String>? record;
    SafeLogger(
      (event) => record = event,
    ).record(OperationalEvent.authRequestFailed);
    expect(record!.keys, unorderedEquals(['event', 'timestamp']));
    expect(record!['event'], 'authRequestFailed');
    expect(DateTime.parse(record!['timestamp']!).isUtc, isTrue);
  });
}
