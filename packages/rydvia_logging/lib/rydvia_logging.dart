enum OperationalEvent {
  startup,
  authRequestFailed,
  sessionExpired,
  serviceFetchFailed,
  unexpectedFailure,
}

/// No arbitrary messages or metadata: credentials and PII cannot enter this API.
class SafeLogger {
  const SafeLogger(this.sink);
  final void Function(Map<String, String>) sink;
  void record(OperationalEvent event) => sink(
    Map.unmodifiable({
      'event': event.name,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    }),
  );
}
