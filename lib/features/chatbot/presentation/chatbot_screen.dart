import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/services/locale_service.dart';
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

  late final List<ChatbotMessage> _messages = [
    ChatbotMessage(
      text: tr(
        'Chào bạn! Mình là trợ lý COne. Bạn đang cần tìm hiểu về điểm rèn luyện, hoạt động hay danh hiệu Sinh viên 5 tốt nào?',
        'Hi there! I\'m the COne AI Assistant. How can I help you with conduct scores, activities, or the 5-Good Student award today?',
      ),
      isUser: false,
    ),
  ];

  List<String> get _quickPrompts => LocaleService.instance.isEnglish
      ? const [
          '📊 How is my conduct score this semester?',
          '🎯 What missing criteria do I need for Good rank?',
          '🎪 Suggest activities to boost my conduct score',
          'How to apply for the 5-Good Student award?',
          'How to submit activity evidence?',
        ]
      : const [
          '📊 Điểm rèn luyện của mình kỳ này thế nào?',
          '🎯 Mình còn thiếu tiêu chí nào để lên loại Tốt?',
          '🎪 Gợi ý hoạt động phong trào phù hợp để cộng điểm',
          'Cách đăng ký danh hiệu SV5T?',
          'Quy trình nộp minh chứng?',
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
          ChatbotMessage(
            text: tr(
              'Hiện mình chưa kết nối được tới máy chủ trợ lý. Bạn thử lại sau ít phút nhé.',
              'Unable to connect to the assistant server right now. Please try again in a few minutes.',
            ),
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
                  tr('Trợ lý COne', 'COne Assistant'),
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
                      tr('Sẵn sàng hỗ trợ', 'Ready to help'),
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
                    return _Bubble(
                      text: tr(
                        'Mình đang tìm thông tin cho bạn...',
                        'Looking up the best answer for you...',
                      ),
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
                        hintText: tr(
                          'Hỏi bất cứ điều gì về COne...',
                          'Ask anything about COne...',
                        ),
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
    final hasTable = !isUser && RegExp(r'^\s*\|.+\|\s*$', multiLine: true).hasMatch(text);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (hasTable ? 0.94 : 0.82),
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

/// Hiển thị nội dung Chatbot sạch đẹp: tự động chuyển bảng Markdown, link [text](url),
/// **in đậm**, *in nghiêng*, tiêu đề ### và gạch đầu dòng — không bao giờ lộ dấu * thô.
class _FormattedMessageText extends StatelessWidget {
  const _FormattedMessageText({
    required this.text,
    required this.baseColor,
    this.isMuted = false,
  });

  final String text;
  final Color baseColor;
  final bool isMuted;

  bool _isTableLine(String line) {
    final t = line.trim();
    return t.startsWith('|') && t.endsWith('|') && t.length > 2;
  }

  bool _isTableSeparator(String line) {
    return RegExp(r'^\|[\s\-:|]+\|$').hasMatch(line.trim());
  }

  List<String> _splitTableCells(String line) {
    final t = line.trim();
    final inner = t.substring(1, t.length - 1);
    return inner.split('|').map((c) => c.trim()).toList();
  }

  Widget _buildMarkdownTable(List<String> rawLines) {
    final rows = <List<String>>[];
    int headerRowIndex = -1;

    for (final raw in rawLines) {
      if (_isTableSeparator(raw)) {
        if (rows.isNotEmpty && headerRowIndex == -1) {
          headerRowIndex = 0;
        }
        continue;
      }
      rows.add(_splitTableCells(raw));
    }

    if (rows.isEmpty) return const SizedBox.shrink();
    final colCount = rows.fold<int>(0, (m, r) => r.length > m ? r.length : m);
    if (colCount == 0) return const SizedBox.shrink();

    final isDark = AppColors.isDark;
    final headerBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final zebraBg = isDark
        ? Colors.white.withValues(alpha: 0.03)
        : const Color(0xFFF8FAFC);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.adaptiveCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adaptiveBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder.symmetric(
            inside: BorderSide(color: AppColors.adaptiveBorder, width: 0.7),
          ),
          children: [
            for (var r = 0; r < rows.length; r++)
              TableRow(
                decoration: BoxDecoration(
                  color: r == headerRowIndex
                      ? headerBg
                      : (r.isEven ? zebraBg : Colors.transparent),
                ),
                children: [
                  for (var c = 0; c < colCount; c++)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(
                            fontSize: 12.2,
                            height: 1.35,
                            fontWeight: r == headerRowIndex
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: baseColor,
                          ),
                          children: _parseInlineMarkdown(
                            c < rows[r].length ? rows[r][c] : '',
                            TextStyle(
                              fontSize: 12.2,
                              height: 1.35,
                              fontWeight: r == headerRowIndex
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: baseColor,
                            ),
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

      // 1. Gom nhóm bảng Markdown liên tiếp
      if (_isTableLine(line)) {
        final tableLines = <String>[line];
        while (i + 1 < lines.length && _isTableLine(lines[i + 1])) {
          i++;
          tableLines.add(lines[i].trimRight());
        }
        if (tableLines.length >= 2) {
          widgets.add(_buildMarkdownTable(tableLines));
          continue;
        }
      }

      // 2. Tiêu đề markdown (# / ## / ###)
      var isHeading = false;
      final headingMatch = RegExp(r'^#{1,4}\s+').firstMatch(line.trimLeft());
      if (headingMatch != null) {
        isHeading = true;
        line = line.trimLeft().substring(headingMatch.end);
      }

      // 3. Gạch đầu dòng (- hoặc * hoặc •)
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
    final pattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)|\*\*(.+?)\*\*|\*(.+?)\*');
    var lastEnd = 0;

    for (final match in pattern.allMatches(input)) {
      if (match.start > lastEnd) {
        final plain = input.substring(lastEnd, match.start).replaceAll('*', '');
        if (plain.isNotEmpty) {
          spans.add(TextSpan(text: plain));
        }
      }
      final linkLabel = match.group(1);
      final linkUrl = match.group(2);
      final boldText = match.group(3);
      final italicText = match.group(4);

      if (linkLabel != null && linkUrl != null) {
        final targetUri = Uri.tryParse(linkUrl.trim());
        spans.add(
          TextSpan(
            text: linkLabel.replaceAll('*', ''),
            style: baseStyle.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
            recognizer: targetUri == null
                ? null
                : (TapGestureRecognizer()
                  ..onTap = () {
                    launchUrl(targetUri, mode: LaunchMode.externalApplication);
                  }),
          ),
        );
      } else if (boldText != null) {
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
