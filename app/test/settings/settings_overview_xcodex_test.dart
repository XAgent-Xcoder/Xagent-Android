// The settings hub's overview card on a phone with the on-device runtime that
// is still signed out (no DeepSeek account, no key): the card no longer offers
// the DeepSeek sign-in, it offers the xcodex account entry and opens the remote
// hosts screen where the xcodex device sign-in and QR pairing live.
//
//   flutter test test/settings/settings_overview_xcodex_test.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dsh_app/remote/relay/relay_backend.dart';
import 'package:dsh_app/remote/secret_store.dart';
import 'package:dsh_app/runtime/runtime_bridge.dart';
import 'package:dsh_app/runtime/runtime_state.dart';
import 'package:dsh_app/state/account_state.dart';
import 'package:dsh_app/state/balance_state.dart' show DeepSeekBalance;
import 'package:dsh_app/state/connection_state.dart';
import 'package:dsh_app/state/hosts_state.dart';
import 'package:dsh_app/state/settings_state.dart';
import 'package:dsh_app/ui/remote/remote_screen.dart';
import 'package:dsh_app/ui/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../account/support.dart' show FixedAccount;
import '../phone/support.dart' show FixedActiveHost, FixedHosts;
import '../shell/golden_harness.dart';

const _bundled = 'r5-dsh0.2.1-rc.2-node24.22.1-ubuntu24.04.5-b3f6c96ee2f2';
const _missing = RuntimeStatus(phase: RuntimePhase.notInstalled, bundledVersion: _bundled, abi: 'arm64-v8a');

/// A relay (xcodex) account frozen at a given state.
class _FixedRelayAccount extends RelayAccountController {
  _FixedRelayAccount(this.initial);

  final RelayAccountState initial;

  @override
  Future<RelayAccountState> build() async => initial;
}

/// A relay backend that reports a balance (the Phase B seam).
class _FakeBalanceRelay extends UnavailableRelayBackend implements RelayBalanceBackend {
  _FakeBalanceRelay(this._balance);

  final DeepSeekBalance? _balance;

  @override
  Future<DeepSeekBalance?> balance() async => _balance;
}

/// Answers avatar loads with a solid 1×1 PNG so [Image.network] never reaches the network.
class _OfflineImages extends HttpOverrides {
  /// 1×1 black PNG.
  static final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

  @override
  HttpClient createHttpClient(SecurityContext? context) => _FakeHttpClient();
}

class _FakeHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async => _FakeRequest();

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest();

  @override
  dynamic noSuchMethod(Invocation invocation) => Future.value(_FakeRequest());
}

class _FakeRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async => _FakeResponse();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeResponse extends Stream<List<int>> implements HttpClientResponse {
  final Stream<List<int>> _bytes;

  _FakeResponse() : _bytes = Stream<List<int>>.value(_OfflineImages.bytes);

  @override
  StreamSubscription<List<int>> listen(void Function(List<int> event)? onData,
      {Function? onError, void Function()? onDone, bool? cancelOnError}) =>
      _bytes.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);

  @override
  int get statusCode => 200;

  @override
  int get contentLength => _OfflineImages.bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

List<Override> _overrides({
  RuntimeStatus runtime = _missing,
  HostRef host = HostRef.local,
  HostLinkPhase link = HostLinkPhase.connected,
  AppSettings settings = const AppSettings(loaded: true),
  RelayAccountState? relay,
  RelayBackend? relayBackend,
}) => [
  localRuntimeProvider.overrideWith(() => FakeRuntime(LocalRuntimeState(loaded: true, status: runtime))),
  settingsProvider.overrideWith(() => FakeSettings(settings)),
  accountProvider.overrideWith(() => FixedAccount(const AccountState(phase: AccountPhase.signedOut))),
  activeHostProvider.overrideWith(() => FixedActiveHost(host)),
  hostsProvider.overrideWith(FixedHosts.new),
  hostLinkStatusProvider.overrideWith((ref, host) => Stream.value(HostLinkStatus(link))),
  networkKicksProvider.overrideWithValue(const Stream.empty()),
  secretStoreProvider.overrideWithValue(MemorySecretStore()),
  if (relay != null) relayAccountProvider.overrideWith(() => _FixedRelayAccount(relay)),
  if (relayBackend != null) relayBackendProvider.overrideWithValue(relayBackend),
];

Future<void> _pump(WidgetTester tester, List<Override> overrides) async {
  usePhoneSurface(tester);
  await tester.pumpWidget(
    goldenApp(
      home: const Scaffold(body: SettingsOverview()),
      brightness: Brightness.light,
      overrides: overrides,
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  testWidgets('local, signed out: the card offers xcodex, not DeepSeek', (tester) async {
    await _pump(tester, _overrides());
    expect(find.text('登录 xcodex 账号'), findsOneWidget);
    expect(find.text('登录 DeepSeek 账号'), findsNothing);
    expect(find.text('或填写 API Key'), findsNothing);
    expect(find.text('使用浏览器授权登录'), findsOneWidget);
  });

  testWidgets('local, signed out: tapping opens the remote hosts screen', (tester) async {
    await _pump(tester, _overrides());
    await tester.tap(find.text('登录 xcodex 账号'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(RemoteScreen), findsOneWidget);
  });

  testWidgets('runtime installed, local, signed out: still the xcodex entry', (tester) async {
    await _pump(tester, _overrides(runtime: runningStatus));
    expect(find.text('登录 xcodex 账号'), findsOneWidget);
    expect(find.text('登录 DeepSeek 账号'), findsNothing);
  });

  testWidgets('xcodex signed in: the card shows the account, not a sign-in entry', (tester) async {
    await _pump(
      tester,
      _overrides(
        relay: const RelayAccountState(available: true, server: 'agent.xcodex.vip', user: RelayUser(id: 'xc1', displayName: 'Joseph')),
      ),
    );
    expect(find.text('登录 xcodex 账号'), findsNothing);
    expect(find.text('使用浏览器授权登录'), findsNothing);
    expect(find.text('Joseph'), findsOneWidget);
  });

  testWidgets('xcodex with a balance: the card shows the balance line and avatar', (tester) async {
    await HttpOverrides.runWithHttpOverrides(
      () => _pumpAndExpectBalanceAndAvatar(tester),
      _OfflineImages(),
    );
  });

  testWidgets('xcodex avatar shows even without a balance backend', (tester) async {
    await HttpOverrides.runWithHttpOverrides(
      () => _pumpAndExpectAvatarOnly(tester),
      _OfflineImages(),
    );
  });
}

Future<void> _pumpAndExpectBalanceAndAvatar(WidgetTester tester) async {
  await _pump(
    tester,
    _overrides(
      relay: const RelayAccountState(
        available: true,
        server: 'agent.xcodex.vip',
        user: RelayUser(id: 'xc1', displayName: 'Joseph', avatarUrl: 'https://avatar.example/j.png'),
      ),
      relayBackend: _FakeBalanceRelay(const DeepSeekBalance(currency: 'CNY', total: 42.5)),
    ),
  );
  expect(find.text('余额 ¥42.50'), findsOneWidget);
  expect(find.byType(ClipOval), findsOneWidget);
}

Future<void> _pumpAndExpectAvatarOnly(WidgetTester tester) async {
  await _pump(
    tester,
    _overrides(
      relay: const RelayAccountState(
        available: true,
        server: 'agent.xcodex.vip',
        user: RelayUser(id: 'xc1', displayName: 'Joseph', avatarUrl: 'https://avatar.example/j.png'),
      ),
      relayBackend: const UnavailableRelayBackend(),
    ),
  );
  expect(find.byType(ClipOval), findsOneWidget);
  expect(find.text('余额 ¥42.50'), findsNothing);
  expect(find.text('已登录'), findsOneWidget);
}

