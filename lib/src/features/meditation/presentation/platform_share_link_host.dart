import 'package:flutter/widgets.dart';

import '../domain/passage_share.dart';

/// Receives Flutter's built-in Android App Link routes above [MaterialApp].
///
/// The activity is `singleTop`. A cold start is [PlatformDispatcher.defaultRouteName].
/// A link while the app is open arrives as [WidgetsBindingObserver.didPushRouteInformation].
/// This host is registered first so it can accept a `?ref=` link before MaterialApp
/// tries to push that URL as a named route.
class PlatformShareLinkHost extends StatefulWidget {
  const PlatformShareLinkHost({super.key, required this.child});

  final Widget child;

  static PlatformShareLinkHostState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<PlatformShareLinkHostState>();
  }

  @override
  State<PlatformShareLinkHost> createState() => PlatformShareLinkHostState();
}

class PlatformShareLinkHostState extends State<PlatformShareLinkHost>
    with WidgetsBindingObserver {
  final List<VoidCallback> _listeners = [];

  /// Decoded `ref` from the latest link, such as `1 Cor 13:4-7`.
  String? latestRef;

  void addListener(VoidCallback listener) => _listeners.add(listener);

  void removeListener(VoidCallback listener) => _listeners.remove(listener);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _listeners.clear();
    super.dispose();
  }

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) async {
    final ref = PassageShareLink.refFromUri(routeInformation.uri);
    if (ref == null) return false;
    latestRef = ref;
    for (final listener in List<VoidCallback>.of(_listeners)) {
      listener();
    }
    return true;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
