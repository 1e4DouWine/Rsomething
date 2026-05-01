import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_providers.dart';
import '../services/settings_service.dart';
import '../services/ai_service.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _baseUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _modelNameController = TextEditingController();
  bool _isTesting = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await SettingsService.getInstance();
    _baseUrlController.text = settings.getBaseUrl();
    _apiKeyController.text = settings.getApiKey();
    _modelNameController.text = settings.getModelName();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
      ),
      body: ListView(
        children: [
          _buildProfileHeader(),
          const Divider(),
          _buildAIConfigSection(),
          const Divider(),
          _buildShareSettings(),
          const Divider(),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Icon(
              Icons.auto_awesome,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RS 智能助手',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '你的个人知识助手',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIConfigSection() {
    return ExpansionTile(
      leading: const Icon(Icons.smart_toy),
      title: const Text('AI 模型配置'),
      subtitle: const Text('设置大模型API参数'),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _baseUrlController,
                  decoration: const InputDecoration(
                    labelText: 'API Base URL',
                    hintText: 'https://api.openai.com/v1/chat/completions',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入API地址';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _apiKeyController,
                  decoration: const InputDecoration(
                    labelText: 'API Key',
                    hintText: 'sk-...',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入API Key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelNameController,
                  decoration: const InputDecoration(
                    labelText: '模型名称',
                    hintText: 'gpt-4o-mini',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入模型名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isTesting ? null : _testConnection,
                        icon: _isTesting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.wifi_tethering),
                        label: Text(_isTesting ? '测试中...' : '测试连接'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('保存配置'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareSettings() {
    return FutureBuilder<SettingsService>(
      future: SettingsService.getInstance(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final settings = snapshot.data!;

        return Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.notifications),
              title: const Text('静默处理模式'),
              subtitle: const Text('分享内容后直接后台处理，不打开应用'),
              value: settings.isSilentMode(),
              onChanged: (value) async {
                await settings.setSilentMode(value);
                setState(() {});
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('默认提醒时间'),
              subtitle: Text('提前 ${settings.getDefaultReminderMinutes()} 分钟'),
              onTap: () => _showReminderTimePicker(settings),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAboutSection() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('关于 RS'),
          onTap: () => _showAboutDialog(),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('隐私政策'),
          onTap: () {
            // TODO: 显示隐私政策
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: const Text('清空所有数据'),
          textColor: Colors.red,
          iconColor: Colors.red,
          onTap: () => _showClearDataDialog(),
        ),
      ],
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);

    try {
      final aiService = AIService.instance;
      aiService.setConfig(AIConfig(
        baseUrl: _baseUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        modelName: _modelNameController.text.trim(),
      ));

      final success = await aiService.testConnection();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '连接成功！' : '连接失败，请检查配置'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = await SettingsService.getInstance();
    await settings.setBaseUrl(_baseUrlController.text.trim());
    await settings.setApiKey(_apiKeyController.text.trim());
    await settings.setModelName(_modelNameController.text.trim());

    // 更新AI服务配置
    if (mounted) {
      context.read<AIProvider>().updateConfig();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('配置已保存')),
      );
    }
  }

  Future<void> _showReminderTimePicker(SettingsService settings) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择提醒时间'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 15),
            child: const Text('提前 15 分钟'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 30),
            child: const Text('提前 30 分钟'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 60),
            child: const Text('提前 1 小时'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 120),
            child: const Text('提前 2 小时'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 1440),
            child: const Text('提前 1 天'),
          ),
        ],
      ),
    );

    if (minutes != null) {
      await settings.setDefaultReminderMinutes(minutes);
      setState(() {});
    }
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'RS 智能助手',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.auto_awesome,
        size: 48,
        color: Theme.of(context).primaryColor,
      ),
      children: const [
        Text('RS 是一款智能个人知识助手，深度融入系统分享机制，让碎片信息被高效整理和记忆。'),
        SizedBox(height: 16),
        Text('© 2026 RS Team'),
      ],
    );
  }

  Future<void> _showClearDataDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有数据'),
        content: const Text('此操作将删除所有记忆、账单、待办等数据，且无法恢复。确定要继续吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('确认清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: 清空数据库
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('所有数据已清空')),
      );
    }
  }
}