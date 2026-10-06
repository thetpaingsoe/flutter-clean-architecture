class Config {
  // Debug Mode ON/OFF
  // When you off this mode, it will not show you the debug information
  // in the debug consoles related with the api data fetching.
  static bool isDebugMode = true;

  // Offset & Limit Constants
  static const int limit = 30;
  static const int offset = 0;

  // Offline-first is handled by the repositories (remote -> cache ->
  // bundled asset), so no manual data-source switch is needed.
}
