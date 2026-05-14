import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/models/ai_config_profile.dart';
import 'package:flutter_app/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const secureStorageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final secureValues = <String, String>{};

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureValues.clear();
    SettingsService.resetForTesting();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, (call) async {
          final rawArguments = call.arguments;
          final arguments = rawArguments is Map
              ? Map<String, Object?>.from(rawArguments)
              : <String, Object?>{};
          final key = arguments['key'] as String?;

          switch (call.method) {
            case 'read':
              return key == null ? null : secureValues[key];
            case 'write':
              if (key != null) {
                secureValues[key] = arguments['value'] as String? ?? '';
              }
              return null;
            case 'delete':
              if (key != null) secureValues.remove(key);
              return null;
            case 'deleteAll':
              secureValues.clear();
              return null;
            case 'containsKey':
              return key != null && secureValues.containsKey(key);
            case 'readAll':
              return secureValues;
            case 'isProtectedDataAvailable':
              return true;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    SettingsService.resetForTesting();
  });

  test('concurrent getInstance calls return one initialized service', () async {
    final services = await Future.wait(
      List.generate(8, (_) => SettingsService.getInstance()),
    );

    final first = services.first;
    expect(services.every((service) => identical(service, first)), isTrue);
    expect(first.getProfiles(), hasLength(1));
    expect(first.getActiveProfile()?.id, 'default');
    expect(first.isSilentMode(), isFalse);
  });

  test('profile api keys are stored only in secure storage', () async {
    final service = await SettingsService.getInstance();

    await service.saveProfiles([
      AiConfigProfile(
        id: 'custom',
        name: '测试配置',
        baseUrl: 'https://api.example.com/v1/chat/completions',
        apiKey: 'secret-key',
        modelName: 'example-model',
      ),
    ]);

    final prefs = await SharedPreferences.getInstance();
    final profilesJson = prefs.getString('ai_config_profiles');
    expect(profilesJson, isNotNull);

    final profiles = json.decode(profilesJson ?? '[]') as List<dynamic>;

    expect(secureValues['ai_profile_api_key_custom'], 'secret-key');
    expect(profilesJson, isNot(contains('secret-key')));
    expect(profiles.single, isA<Map>());
    expect(service.getProfiles().single.apiKey, 'secret-key');
  });

  test('malformed profile storage does not break initialization', () async {
    SharedPreferences.setMockInitialValues({
      'ai_config_profiles': '{bad json',
      'ai_active_profile_id': 'missing',
    });
    SettingsService.resetForTesting();

    final service = await SettingsService.getInstance();

    expect(service.getProfiles(), isEmpty);
    expect(service.getActiveProfile(), isNull);
  });
}
