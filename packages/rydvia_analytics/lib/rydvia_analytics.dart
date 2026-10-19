enum AnalyticsEvent { welcomeViewed, verificationCompleted, serviceSelected }

abstract interface class AnalyticsSink {
  void record(AnalyticsEvent event);
}

class NoopAnalytics implements AnalyticsSink {
  const NoopAnalytics();
  @override
  void record(AnalyticsEvent event) {}
}
