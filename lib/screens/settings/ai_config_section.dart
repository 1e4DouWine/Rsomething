import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../services/settings_service.dart';
import '../../services/ai_service.dart';

/// AI 配置设置区块
///
/// 可折叠的 AI 模型配置表单，用于设置：
/// - API Base URL（接口地址）
/// - API Key（认证密钥）
/// - 模型名称（使用的 LLM 模型）
///
/// 提供连接测试和配置保存功能。
class AIConfigSection extends StatefulWidget {
  const AIConfigSection({super.key});

  @override
  State<AIConfigSection> createState() => _AIConfigSectionState();
}

class _AIConfigSectionState extends State<AIConfigSection> {
  /// 表单全局 Key（用于验证）
  final _formKey = GlobalKey<FormState>();

  /// API 地址输入控制器
  final _baseUrlController = TextEditingController();

  /// API Key 输入控制器
  final _apiKeyController = TextEditingController();

  /// 模型名称输入控制器
  final _modelNameController = TextEditingController();

  /// 是否正在测试连接
  bool _isTesting = false;

  /// 是否正在加载设置
  bool _isLoading = true;

  /// 是否展开配置面板
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 从设置服务加载当前配置值
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 可点击的头部（切换展开/折叠）
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // AI 图标
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.smart_toy_rounded,
                          color: colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 标题和副标题
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI 模型配置',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '设置大模型 API 参数',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 展开/折叠箭头（带动画旋转）
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 可折叠的配置表单（带交叉淡入动画）
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _buildForm(theme),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建配置表单
  /// 包含三个输入框（API URL、Key、模型名称）和两个按钮（测试连接、保存配置）
  Widget _buildForm(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Divider(color: colorScheme.outline),
            const SizedBox(height: 20),
            // API Base URL
            _buildTextField(
              controller: _baseUrlController,
              label: 'API Base URL',
              hint: 'https://api.openai.com/v1/chat/completions',
              icon: Icons.link_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入API地址';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // API Key
            _buildTextField(
              controller: _apiKeyController,
              label: 'API Key',
              hint: 'sk-...',
              icon: Icons.key_rounded,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入API Key';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // 模型名称
            _buildTextField(
              controller: _modelNameController,
              label: '模型名称',
              hint: 'gpt-4o-mini',
              icon: Icons.psychology_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入模型名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            // 操作按钮行
            Row(
              children: [
                // 测试连接按钮
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : Icon(Icons.wifi_tethering_rounded, size: 18),
                    label: Text(_isTesting ? '测试中...' : '测试连接'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      side: BorderSide(
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // 保存配置按钮
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('保存配置'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建文本输入框
  /// 统一的输入框样式，支持密码遮罩和表单验证
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  /// 测试 AI API 连接
  /// 验证表单后发送测试请求，显示成功/失败提示
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
        final colorScheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? '连接成功！' : '连接失败，请检查配置'),
            backgroundColor: success ? colorScheme.primary : colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  /// 保存 AI 配置
  /// 验证表单后将配置写入设置服务，并更新 AIProvider
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = await SettingsService.getInstance();
    await settings.setBaseUrl(_baseUrlController.text.trim());
    await settings.setApiKey(_apiKeyController.text.trim());
    await settings.setModelName(_modelNameController.text.trim());

    if (mounted) {
      context.read<AIProvider>().updateConfig();
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('配置已保存'),
          backgroundColor: colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
