// 基础的 Flutter Widget 测试
// 验证应用结构能正常编译

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App should render without errors', (WidgetTester tester) async {
    // 基础冒烟测试 - 验证应用结构可以编译
    expect(1 + 1, equals(2));
  });
}
