import 'package:final_project/model/message.dart';
import 'package:final_project/services/chat_service.dart';
import 'package:final_project/utils/app_colors.dart';
import 'package:final_project/utils/text_styles.dart';
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
  bool _sending = false;
  String? _selectedTag;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await _chatService.sendMessage(text);
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final data = snapshot.data ?? [];
                  if (data.isEmpty) {
                    return Center(
                      child: Text(
                        'Say hi to your coach',
                        style: AppTextStyles.bodyMedium,
                      ),
                    );
                  }
                  // Show latest at bottom: reverse list + reverse listview
                  final messages = data.reversed.toList(growable: false);
                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      return _MessageBubble(message: m);
                    },
                  );
                },
              ),
            ),

            // Input bar
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Theme.of(context).brightness == Brightness.dark
                      ? Border.all(color: Theme.of(context).dividerColor)
                      : null,
                  boxShadow: Theme.of(context).brightness == Brightness.dark
                      ? []
                      : [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).dividerColor.withOpacity(0.7),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _quickTag('Workout'),
                        _quickTag('Meal'),
                        _quickTag('Relax'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            minLines: 1,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            style: AppTextStyles.input,
                            decoration: InputDecoration(
                              hintText: 'Type your message... ',
                              hintStyle: AppTextStyles.hint,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          width: 44,
                          child: ElevatedButton(
                            onPressed: _sending ? null : _handleSend,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: const CircleBorder(),
                            ),
                            child: _sending
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const FaIcon(FontAwesomeIcons.paperPlane, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickTag(String label) {
    final selected = _selectedTag == label;
    return FilterChip(
      label: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: selected
              ? Colors.white
              : Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: selected,
      showCheckmark: true,
      checkmarkColor: Colors.white,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: AppColors.accent,
      side: BorderSide(
        color: selected ? AppColors.accent : Theme.of(context).dividerColor,
        width: 1,
      ),
      shape: const StadiumBorder(),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (value) {
        setState(() {
          _selectedTag = value
              ? label
              : (_selectedTag == label ? null : _selectedTag);
        });
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isMine ? AppColors.accent : Theme.of(context).cardColor;
    final fg = isMine ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final border = isMine
        ? null
        : Border.all(color: Theme.of(context).dividerColor, width: 1);
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: border,
            boxShadow: [
              if (!isMine)
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black45
                      : AppColors.divider.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: AppTextStyles.bodyLarge.copyWith(color: fg),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: AppTextStyles.bodySmall.copyWith(
                  color: isMine ? Colors.white70 : AppColors.textLight,
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
