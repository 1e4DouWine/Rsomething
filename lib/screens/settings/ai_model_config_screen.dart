import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/ai_config_profile.dart';
import '../../providers/ai_provider.dart';
import '../../services/settings_service.dart';
import '../../services/ai_service.dart';

/// AI 模型配置列表页面
///
/// 展示所有已保存的 AI 配置档案，支持：
/// - 查看所有配置（卡片列表形式，显示名称、模型、URL）
/// - 选中一份配置作为当前激活配置（高亮 + "使用中"标签）
/// - 新增配置（右下角 FAB）
/// - 编辑/删除配置（长按弹出菜单）
class AiModelConfigScreen extends StatefulWidget {
  const AiModelConfigScreen({super.key});

  @override
  State<AiModelConfigScreen> createState() => _AiModelConfigScreenState();
}

class _AiModelConfigScreenState extends State<AiModelConfigScreen> {
  /// 所有配置档案列表
  List<AiConfigProfile> _profiles = [];

  /// 当前激活的配置档案 ID
  String? _activeProfileId;

  /// 是否正在加载数据
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  /// 从设置服务加载所有配置档案和当前激活项
  Future<void> _loadProfiles() async {
    final settings = await SettingsService.getInstance();
    if (!mounted) return;

    setState(() {
      _profiles = settings.getProfiles();
      _activeProfileId = settings.getActiveProfileId();
      _isLoading = false;
    });
  }

  /// 选中指定配置档案作为当前激活项
  /// 更新持久化存储并刷新 AIProvider 配置
  Future<void> _selectProfile(String id) async {
    final aiProvider = context.read<AIProvider>();
    final settings = await SettingsService.getInstance();
    await settings.setActiveProfileId(id);
    if (!mounted) return;

    setState(() => _activeProfileId = id);
    aiProvider.updateConfig();
  }

  /// 删除指定配置档案
  /// 弹出确认对话框，确认后删除并刷新列表
  Future<void> _deleteProfile(AiConfigProfile profile) async {
    final aiProvider = context.read<AIProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('删除配置'),
          content: Text('确定要删除「${profile.name}」吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                '取消',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;

    if (confirmed == true) {
      final settings = await SettingsService.getInstance();
      await settings.deleteProfile(profile.id);
      await _loadProfiles();
      aiProvider.updateConfig();
    }
  }

  /// 打开配置表单页面
  /// [profile] 不为 null 时为编辑模式，否则为新增模式
  /// 返回后自动刷新列表
  Future<void> _openProfileForm({AiConfigProfile? profile}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AiProfileFormScreen(profile: profile)),
    );
    if (!mounted) return;

    await _loadProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('AI 模型配置'),
        backgroundColor: colorScheme.surface,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
          ? _buildEmptyState(theme)
          : _buildProfileList(theme),
      // 新增配置按钮
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openProfileForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('新增配置'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
    );
  }

  /// 构建空状态提示（无配置时显示）
  Widget _buildEmptyState(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无 AI 配置',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加一份配置',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建配置档案列表
  /// 每项显示配置名称、模型名称、API URL，激活项高亮并带"使用中"标签
  Widget _buildProfileList(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: _profiles.length,
      itemBuilder: (context, index) {
        final profile = _profiles[index];
        final isActive = profile.id == _activeProfileId;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _selectProfile(profile.id),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // 激活项使用主题色背景，否则使用默认表面色
                  color: isActive
                      ? colorScheme.primaryContainer.withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  // 激活项使用主题色边框
                  border: isActive
                      ? Border.all(color: colorScheme.primary, width: 2)
                      : Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // AI 图标容器
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isActive
                            ? colorScheme.primary.withValues(alpha: 0.15)
                            : colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.smart_toy_rounded,
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.onSurfaceVariant,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 配置信息（名称、模型、URL）
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  profile.name,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isActive
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              // "使用中"标签（仅激活项显示）
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '使用中',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // 模型名称
                          Text(
                            profile.modelName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // API 地址
                          Text(
                            profile.baseUrl,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 更多操作菜单（编辑/删除）
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openProfileForm(profile: profile);
                        } else if (value == 'delete') {
                          _deleteProfile(profile);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('编辑')),
                        const PopupMenuItem(value: 'delete', child: Text('删除')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// AI 配置档案编辑/新增表单页面
///
/// [profile] 不为 null 时为编辑模式，预填已有配置值；
/// 为 null 时为新增模式，所有字段为空。
///
/// 表单字段：配置名称、API Base URL、API Key、模型名称
/// 操作按钮：测试连接、保存
///
/// 特殊逻辑：保存/测试时自动检测 URL，若未以 `/chat/completions` 结尾则自动补全。
class AiProfileFormScreen extends StatefulWidget {
  /// 待编辑的配置档案，null 表示新增模式
  final AiConfigProfile? profile;

  const AiProfileFormScreen({super.key, this.profile});

  @override
  State<AiProfileFormScreen> createState() => _AiProfileFormScreenState();
}

class _AiProfileFormScreenState extends State<AiProfileFormScreen> {
  /// 表单全局 Key（用于验证）
  final _formKey = GlobalKey<FormState>();

  /// 配置名称输入控制器
  final _nameController = TextEditingController();

  /// API 地址输入控制器
  final _baseUrlController = TextEditingController();

  /// API Key 输入控制器
  final _apiKeyController = TextEditingController();

  /// 模型名称输入控制器
  final _modelNameController = TextEditingController();

  /// 是否正在测试连接
  bool _isTesting = false;

  /// 是否正在保存
  bool _isSaving = false;

  /// 是否为编辑模式（profile 不为 null）
  bool get _isEditing => widget.profile != null;

  @override
  void initState() {
    super.initState();
    // 编辑模式下预填已有配置值
    final profile = widget.profile;
    if (profile != null) {
      _nameController.text = profile.name;
      _baseUrlController.text = profile.baseUrl;
      _apiKeyController.text = profile.apiKey;
      _modelNameController.text = profile.modelName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelNameController.dispose();
    super.dispose();
  }

  /// 标准化 Base URL
  /// 若用户输入的 URL 未以 `/chat/completions` 结尾，自动补全
  String _normalizeBaseUrl(String url) {
    var trimmed = url.trim();
    if (!trimmed.endsWith('/chat/completions')) {
      if (trimmed.endsWith('/')) {
        trimmed += 'chat/completions';
      } else {
        trimmed += '/chat/completions';
      }
    }
    return trimmed;
  }

  /// 测试 AI API 连接
  /// 验证表单后发送测试请求，显示成功/失败 SnackBar
  Future<void> _testConnection() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isTesting = true);
    try {
      final aiService = AIService.instance;
      // 测试连接会临时覆盖单例配置，结束后需要恢复原配置。
      final previousConfig = aiService.currentConfig;
      final normalizedUrl = _normalizeBaseUrl(_baseUrlController.text);
      bool success = false;
      try {
        aiService.setConfig(
          AIConfig(
            baseUrl: normalizedUrl,
            apiKey: _apiKeyController.text.trim(),
            modelName: _modelNameController.text.trim(),
          ),
        );

        success = await aiService.testConnection();
      } finally {
        // 避免测试配置残留在单例中影响当前已激活配置。
        if (previousConfig != null) {
          aiService.setConfig(previousConfig);
        } else {
          aiService.clearConfig();
        }
      }
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
      if (mounted) setState(() => _isTesting = false);
    }
  }

  /// 保存配置
  /// 验证表单后，编辑模式更新已有档案，新增模式创建新档案
  /// 若当前编辑的是激活配置，同步刷新 AIProvider
  Future<void> _save() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isSaving = true);
    try {
      final settings = await SettingsService.getInstance();
      final normalizedUrl = _normalizeBaseUrl(_baseUrlController.text);

      final editingProfile = widget.profile;
      if (editingProfile != null) {
        // 编辑模式：更新已有档案
        final updated = editingProfile.copyWith(
          name: _nameController.text.trim(),
          baseUrl: normalizedUrl,
          apiKey: _apiKeyController.text.trim(),
          modelName: _modelNameController.text.trim(),
        );
        await settings.updateProfile(updated);
        // 若编辑的是当前激活配置，刷新 AI 服务配置
        if (settings.getActiveProfileId() == updated.id) {
          if (mounted) context.read<AIProvider>().updateConfig();
        }
      } else {
        // 新增模式：创建新档案（使用 UUID 作为唯一标识）
        final newProfile = AiConfigProfile(
          id: const Uuid().v4(),
          name: _nameController.text.trim(),
          baseUrl: normalizedUrl,
          apiKey: _apiKeyController.text.trim(),
          modelName: _modelNameController.text.trim(),
        );
        await settings.addProfile(newProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? '配置已更新' : '配置已添加'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(_isEditing ? '编辑配置' : '新增配置'),
        backgroundColor: colorScheme.surface,
        actions: [
          // 编辑模式下显示删除按钮
          if (_isEditing)
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: colorScheme.error,
              ),
              onPressed: () async {
                final profile = widget.profile;
                if (profile == null) return;

                // 在 await 之前获取 AIProvider 引用，避免跨 async gap 使用 context
                final aiProvider = context.read<AIProvider>();
                final confirmed = await showDialog<bool>(
                  context: context,
                  // 使用 ctx 避免遮蔽外层 context
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: const Text('删除配置'),
                    content: Text('确定要删除「${profile.name}」吗？'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          '取消',
                          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                        ),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && mounted) {
                  final settings = await SettingsService.getInstance();
                  await settings.deleteProfile(profile.id);
                  // 检查 context 是否仍然可用
                  if (!context.mounted) return;
                  aiProvider.updateConfig();
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 配置名称
              _buildTextField(
                controller: _nameController,
                label: '配置名称',
                hint: '例如：OpenAI、通义千问',
                icon: Icons.label_outline_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入配置名称' : null,
              ),
              const SizedBox(height: 20),
              // API 基础地址
              _buildTextField(
                controller: _baseUrlController,
                label: 'API Base URL',
                hint: 'https://api.openai.com/v1',
                icon: Icons.link_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入API地址' : null,
              ),
              // URL 自动补全提示
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '提示：若URL未以 /chat/completions 结尾，系统将自动补全',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // API Key
              _buildTextField(
                controller: _apiKeyController,
                label: 'API Key',
                hint: 'sk-...',
                icon: Icons.key_rounded,
                obscureText: true,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入API Key' : null,
              ),
              const SizedBox(height: 20),
              // 模型名称
              _buildTextField(
                controller: _modelNameController,
                label: '模型名称',
                hint: 'gpt-4o-mini',
                icon: Icons.psychology_rounded,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入模型名称' : null,
              ),
              const SizedBox(height: 32),
              // 操作按钮行：测试连接 + 保存
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
                          : const Icon(Icons.wifi_tethering_rounded, size: 18),
                      label: Text(_isTesting ? '测试中...' : '测试连接'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: colorScheme.outline),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // 保存按钮
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: _isSaving
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : const Icon(Icons.save_rounded, size: 18),
                      label: Text(_isSaving ? '保存中...' : '保存'),
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
      ),
    );
  }

  /// 构建统一风格的文本输入框
  /// 支持密码遮罩和表单验证
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
}
