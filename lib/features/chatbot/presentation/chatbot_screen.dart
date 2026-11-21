import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../data/chatbot_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key, required this.service});

  final ChatbotService service;

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatbotMessage> _messages = [
    const ChatbotMessage(
      text:
          'Chào bạn! Mình là trợ lý COne. Bạn đang cần tìm hiểu về điểm rèn luyện, hoạt động hay danh hiệu Sinh viên 5 tốt nào?',
      isUser: false,
    ),
  ];

  static const _quickPrompts = [
    'Cách xét Sinh viên 5 tốt',
    'Gợi ý hoạt động tăng ĐRL',
    'Thang điểm xếp loại ĐRL',
    'Cách gửi minh chứng bù',
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send([String? presetQuestion]) async {
    final question = (presetQuestion ?? _controller.text).trim();
    if (question.isEmpty || _isSending) {
      return;
    }
    setState(() {
      _messages.add(ChatbotMessage(text: question, isUser: true));
      if (presetQuestion == null) _controller.clear();
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final rawAnswer = await widget.service.ask(question);
      final polished = _polishBotAnswer(rawAnswer);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatbotMessage(text: polished, isUser: false));
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatbotMessage(text: error.message, isUser: false));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const ChatbotMessage(
            text:
                'Hiện mình chưa kết nối được tới máy chủ trợ lý. Bạn thử lại sau ít phút nhé.',
            isUser: false,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
        _scrollToBottom();
      }
    }
  }

  /// Làm mượt câu trả lời thô từ hệ thống để giọng điệu tự nhiên hơn
  String _polishBotAnswer(String raw) {
    var text = raw.replaceAll('\r\n', '\n').trim();
    if (text.startsWith('Thông tin ghi nhận trên hệ thống COFER:')) {
      text = text.replaceFirst(
        'Thông tin ghi nhận trên hệ thống COFER:',
        'Mình tìm thấy thông tin trên hệ thống COFER cho bạn như sau:',
      );
    }
    // Gom nhiều khoảng trắng thừa trên cùng một dòng
    text = text
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r' {2,}'), ' ').trimRight())
        .join('\n');
    // Gom quá nhiều dòng trống liên tiếp
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveAppBarBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trợ lý COne',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: AppColors.adaptiveTextPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Sẵn sàng hỗ trợ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.adaptiveTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.adaptiveBorder, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isSending && index == _messages.length) {
                    return const _Bubble(
                      text: 'Mình đang tìm thông tin cho bạn...',
                      isUser: false,
                      isTyping: true,
                    );
                  }
                  final message = _messages[index];
                  return _Bubble(text: message.text, isUser: message.isUser);
                },
              ),
            ),

            // Gợi ý câu hỏi nhanh khi mới mở chat
            if (_messages.length <= 1 && !_isSending)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: _quickPrompts.map((prompt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _send(prompt),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.adaptiveCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.adaptiveBorder),
                          ),
                          child: Text(
                            prompt,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.adaptiveTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // Khung nhập câu hỏi
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: BoxDecoration(
                color: AppColors.adaptiveCard,
                border: Border(
                  top: BorderSide(color: AppColors.adaptiveBorder),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.adaptiveTextPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Hỏi bất cứ điều gì về COne...',
                        hintStyle: TextStyle(
                          color: AppColors.adaptiveTextSecondary,
                          fontSize: 13.5,
                        ),
                        filled: true,
                        fillColor: AppColors.adaptiveCardSubtle,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: AppColors.adaptiveBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: BorderSide(color: AppColors.adaptiveBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 46,
                    height: 46,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: _isSending ? null : () => _send(),
                      child: const Icon(Icons.send_rounded, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.text,
    required this.isUser,
    this.isTyping = false,
  });

  final String text;
  final bool isUser;
  final bool isTyping;

  @override
  Widget build(BuildContext context) {
    final textColor = isUser ? Colors.white : AppColors.adaptiveTextPrimary;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.82,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.adaptiveCard,
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isUser ? const Radius.circular(5) : null,
            bottomLeft: isUser ? null : const Radius.circular(5),
          ),
          border: isUser ? null : Border.all(color: AppColors.adaptiveBorder),
        ),
        child: isUser
            ? Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              )
            : _FormattedMessageText(
                text: text,
                baseColor: textColor,
                isMuted: isTyping,
              ),
      ),
    );
  }
}

/// Hiển thị nội dung Chatbot sạch đẹp: tự động chuyển **in đậm**, *in nghiêng*,
/// tiêu đề ### và gạch đầu dòng thành văn bản có định dạng — không bao giờ lộ dấu * thô.
class _FormattedMessageText extends StatelessWidget {
  const _FormattedMessageText({
    required this.text,
    required this.baseColor,
    this.isMuted = false,
  });

  final String text;
  final Color baseColor;
  final bool isMuted;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trimRight();
      if (line.trim().isEmpty) {
        if (widgets.isNotEmpty) {
          widgets.add(const SizedBox(height: 6));
        }
        continue;
      }

      // Tiêu đề markdown (# / ## / ###)
      var isHeading = false;
      final headingMatch = RegExp(r'^#{1,4}\s+').firstMatch(line.trimLeft());
      if (headingMatch != null) {
        isHeading = true;
        line = line.trimLeft().substring(headingMatch.end);
      }

      // Gạch đầu dòng (- hoặc * hoặc •)
      var isBullet = false;
      final bulletMatch = RegExp(r'^[-*•]\s+').firstMatch(line.trimLeft());
      if (!isHeading && bulletMatch != null) {
        isBullet = true;
        line = line.trimLeft().substring(bulletMatch.end);
      }

      final baseStyle = TextStyle(
        color: isMuted ? AppColors.adaptiveTextSecondary : baseColor,
        fontSize: isHeading ? 14.5 : 13.8,
        height: 1.48,
        fontWeight: isHeading ? FontWeight.w800 : FontWeight.w500,
        fontStyle: isMuted ? FontStyle.italic : FontStyle.normal,
      );

      final richText = Text.rich(
        TextSpan(
          style: baseStyle,
          children: _parseInlineMarkdown(line, baseStyle),
        ),
      );

      if (isBullet) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 8),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(child: richText),
              ],
            ),
          ),
        );
      } else {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(bottom: isHeading ? 4 : 3),
            child: richText,
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  List<InlineSpan> _parseInlineMarkdown(String input, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*');
    var lastEnd = 0;

    for (final match in pattern.allMatches(input)) {
      if (match.start > lastEnd) {
        final plain = input.substring(lastEnd, match.start).replaceAll('*', '');
        if (plain.isNotEmpty) {
          spans.add(TextSpan(text: plain));
        }
      }
      final boldText = match.group(1);
      final italicText = match.group(2);
      if (boldText != null) {
        spans.add(
          TextSpan(
            text: boldText.replaceAll('*', ''),
            style: baseStyle.copyWith(fontWeight: FontWeight.w800),
          ),
        );
      } else if (italicText != null) {
        spans.add(
          TextSpan(
            text: italicText.replaceAll('*', ''),
            style: baseStyle.copyWith(fontStyle: FontStyle.italic),
          ),
        );
      }
      lastEnd = match.end;
    }

    if (lastEnd < input.length) {
      final remaining = input.substring(lastEnd).replaceAll('*', '');
      if (remaining.isNotEmpty) {
        spans.add(TextSpan(text: remaining));
      }
    }

    if (spans.isEmpty) {
      spans.add(TextSpan(text: input.replaceAll('*', '')));
    }
    return spans;
  }
}
