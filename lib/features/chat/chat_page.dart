import 'package:final_project/model/message.dart';
import 'package:final_project/services/chat_service.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
import 'package:final_project/features/chat/animations/pulsing_dots.dart';
import 'package:final_project/features/chat/animations/typewriter_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _sending = false;
  String? _selectedTag;
  // Track which bot messages have already animated to avoid re-animating.
  final Set<String> _animatedBotIds = <String>{};
  bool _seededAnimated = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      // Determine mode based on selected tag
      String mode = 'meal'; // default mode
      if (_selectedTag != null) {
        mode = _selectedTag!.toLowerCase();
      }

      await _chatService.sendMessage(text, mode: mode);
      _controller.clear();
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: StreamBuilder<List<Message>>(
                stream: _chatService.getMessages(),
                builder: (context, snapshot) {
                  // Seed animated set with existing bot messages so only new ones animate
                  final dataSeed = snapshot.data ?? const <Message>[];
                  if (!_seededAnimated && dataSeed.isNotEmpty) {
                    _animatedBotIds.addAll(
                      dataSeed.where((m) => m.isBot).map((m) => m.id),
                    );
                    _seededAnimated = true;
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading conversation...',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.getTextSecondary(context),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: AppColors.getErrorColor(context),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.getErrorColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data ?? [];

                  // Dedup messages by ID to prevent transient duplicates
                  final uniqueMessages = <String, Message>{};
                  for (final m in data) {
                    uniqueMessages[m.id] = m;
                  }
                  final dedupedData = uniqueMessages.values.toList()
                    ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                  if (dedupedData.isEmpty) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.accent.withValues(
                                              alpha: 0.1,
                                            ),
                                            AppColors.accent.withValues(
                                              alpha: 0.05,
                                            ),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Center(
                                        child: FaIcon(
                                          FontAwesomeIcons.commentDots,
                                          size: 40,
                                          color: AppColors.accent,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      'Start Your Wellness Journey',
                                      style: AppTextStyles.titleMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.getTextPrimary(
                                          context,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ask me about nutrition, workouts, or relaxation tips!',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.getTextTertiary(
                                          context,
                                        ),
                                      ),
                                      textAlign: TextAlign.center,
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
                  // Show latest at bottom: reverse list + reverse listview
                  final messages = dedupedData.reversed.toList(growable: false);
                  final hasTyping =
                      _sending; // show indicator while waiting for AI
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length + (hasTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // While waiting for AI response, render a lightweight
                      // typing indicator bubble at the bottom (index 0).
                      if (hasTyping && index == 0) {
                        return const _TypingIndicatorBubble();
                      }

                      final dataIndex = index - (hasTyping ? 1 : 0);
                      final m = messages[dataIndex];
                      // Animate only for the newest bot message, not while typing,
                      // and only if we haven't animated this message id before.
                      final isNewest = dataIndex == 0;
                      final animateText =
                          isNewest &&
                          m.isBot &&
                          !hasTyping &&
                          !_animatedBotIds.contains(m.id);
                      return _MessageBubble(
                        key: ValueKey(m.id),
                        message: m,
                        animateText: animateText,
                        onTypewriterComplete: animateText
                            ? () {
                                if (!mounted) return;
                                setState(() {
                                  _animatedBotIds.add(m.id);
                                });
                              }
                            : null,
                      );
                    },
                  );
                },
              ),
            ),

            // Modern input section
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mode selector chips
                      Row(
                        children: [
                          Text(
                            'Mode:',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.getTextSecondary(context),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              children: [
                                _quickTag(
                                  'Workout',
                                  FontAwesomeIcons.dumbbell,
                                  'workout',
                                ),
                                _quickTag(
                                  'Meal',
                                  FontAwesomeIcons.utensils,
                                  'meal',
                                ),
                                _quickTag(
                                  'Relax',
                                  FontAwesomeIcons.spa,
                                  'relax',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Input field
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.getHover(context),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                maxLines: null,
                                textInputAction: TextInputAction.newline,
                                style: AppTextStyles.bodyMedium,
                                decoration: InputDecoration(
                                  hintText:
                                      'Ask me anything about your health...',
                                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.getTextTertiary(context),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Send button
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.accent,
                                  AppColors.accent.withValues(alpha: 0.8),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _handleSend,
                              icon: const FaIcon(
                                FontAwesomeIcons.paperPlane,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(String text, IconData icon) {
    return InkWell(
      onTap: () {
        _controller.text = text;
        _focusNode.requestFocus();
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorder(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.getTextSecondary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTag(String label, IconData icon, String value) {
    final selected = _selectedTag == value;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            icon,
            size: 14,
            color: selected ? Colors.white : AppColors.accent,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected
                  ? Colors.white
                  : AppColors.getTextSecondary(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      selected: selected,
      showCheckmark: false,
      backgroundColor: AppColors.getHover(context),
      selectedColor: AppColors.accent,
      side: BorderSide(
        color: selected ? AppColors.accent : AppColors.getBorder(context),
        width: 1.5,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (isSelected) {
        setState(() {
          _selectedTag = isSelected ? value : null;
        });
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool animateText;
  final VoidCallback? onTypewriterComplete;
  const _MessageBubble({
    super.key,
    required this.message,
    this.animateText = false,
    this.onTypewriterComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine && !message.isBot;
    final isBot = message.isBot;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bg = isMine
        ? LinearGradient(
            colors: [
              AppColors.accent,
              AppColors.accent.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final fg = isMine ? Colors.white : AppColors.getTextPrimary(context);

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isMine ? 20 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 20),
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: bg,
            color: isBot
                ? AppColors.getSurface(context)
                : (isMine ? null : AppColors.getSurface(context)),
            borderRadius: radius,
            border: isMine
                ? null
                : Border.all(color: AppColors.getBorder(context), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isMine ? 0.15 : 0.05),
                blurRadius: isMine ? 12 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (isBot) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: FaIcon(
                        FontAwesomeIcons.robot,
                        size: 12,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Health Coach',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              if (isBot && animateText)
                TypewriterText(
                  message.content,
                  textStyle: AppTextStyles.bodyMedium.copyWith(
                    color: fg,
                    height: 1.5,
                  ),
                  onComplete: onTypewriterComplete,
                )
              else
                Text(
                  message.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: fg,
                    height: 1.5,
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                _formatTime(message.timestamp),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isMine
                      ? Colors.white.withValues(alpha: 0.8)
                      : AppColors.getTextTertiary(context),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// Lightweight three-dots typing indicator styled like a bot bubble
class _TypingIndicatorBubble extends StatelessWidget {
  const _TypingIndicatorBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(color: AppColors.getBorder(context), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.smart_toy_rounded,
                      size: 12,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Health Coach',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const PulsingDots(),
            ],
          ),
        ),
      ),
    );
  }
}
