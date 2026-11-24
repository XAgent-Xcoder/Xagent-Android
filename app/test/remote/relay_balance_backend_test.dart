// Phase B 预留口子的声明层测试：RelayBalanceBackend 的 `is` 判定与 RelayUser.avatarUrl。
// 取不到余额/头像时这些口子必须保持 no-op，不能改变任何既有行为。
//
//   flutter test test/remote/relay_balance_backend_test.dart

import 'package:dsh_app/remote/relay/relay_backend.dart';
import 'package:dsh_app/state/balance_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeBalanceRelay extends UnavailableRelayBackend implements RelayBalanceBackend {
  @override
  Future<DeepSeekBalance?> balance() async => null;
}

void main() {
  test('is check distinguishes balance-capable backends', () {
    expect(_FakeBalanceRelay(), isA<RelayBalanceBackend>());
    expect(const UnavailableRelayBackend(), isNot(isA<RelayBalanceBackend>()));
  });

  test('RelayUser carries an optional avatarUrl', () {
    final withAvatar = RelayUser(id: 'x', displayName: 'd', avatarUrl: 'https://a/b.png');
    expect(withAvatar.avatarUrl, 'https://a/b.png');
    final without = RelayUser(id: 'x', displayName: 'd');
    expect(without.avatarUrl, isNull);
  });
}
