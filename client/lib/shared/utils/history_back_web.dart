import 'dart:html' as html;

/// Walks the browser cursor back one entry. Returns true so callers can skip
/// declarative fallback navigation. The popstate fired here is what go_router's
/// RouteInformationProvider listens to in order to rebuild the new top route.
bool historyBack() {
  html.window.history.back();
  return true;
}
