import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/config/app_colors.dart';
import 'shimmer_loading.dart';

/// Route chuyển trang mượt (Fade + Slide nhẹ) kèm khung chờ Shimmer trong frame đầu
/// giúp animation 60fps không bị khựng khi mở màn hình nặng trên máy tầm trung / Web PWA.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  SmoothPageRoute({
    required WidgetBuilder builder,
    bool deferHeavyContent = true,
    super.settings,
  }) : super(
          transitionDuration: const Duration(milliseconds: 220),
          reverseTransitionDuration: const Duration(milliseconds: 170),
          pageBuilder: (context, animation, secondaryAnimation) {
            if (!deferHeavyContent) {
              return builder(context);
            }
            return _DeferredPageBody(builder: builder);
          },
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

class _DeferredPageBody extends StatefulWidget {
  const _DeferredPageBody({required this.builder});

  final WidgetBuilder builder;

  @override
  State<_DeferredPageBody> createState() => _DeferredPageBodyState();
}

class _DeferredPageBodyState extends State<_DeferredPageBody> {
  bool _ready = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Cho phép animation chuyển trang chạy mượt ~110ms trước khi dựng cây widget nặng
    _timer = Timer(const Duration(milliseconds: 110), () {
      if (mounted) {
        setState(() => _ready = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.builder(context);
    }

    return Scaffold(
      backgroundColor: AppColors.adaptiveBackground,
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              minHeight: 2.5,
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            ),
            const Expanded(
              child: SingleChildScrollView(
                physics: NeverScrollableScrollPhysics(),
                child: ShimmerListLoading(itemCount: 4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// IndexedStack lười (Lazy-load) kết hợp hiệu ứng chuyển tab mượt & thanh chờ mảnh ở đỉnh:
/// - Chỉ khởi tạo tab khi người dùng bấm vào lần đầu (tránh gọi đồng loạt 5 tab API lúc mở app).
/// - Giữ nguyên state các tab đã mở để quay lại tức thì.
/// - Hiển thị thanh loading mảnh + hiệu ứng Fade nhẹ khi chuyển mục.
class LazyTabStack extends StatefulWidget {
  const LazyTabStack({
    super.key,
    required this.currentIndex,
    required this.tabBuilders,
  });

  final int currentIndex;
  final List<Widget Function()> tabBuilders;

  @override
  State<LazyTabStack> createState() => _LazyTabStackState();
}

class _LazyTabStackState extends State<LazyTabStack> {
  late final Set<int> _loadedTabs = {widget.currentIndex};
  bool _isSwitching = false;
  bool _showTopProgress = false;
  Timer? _fadeTimer;
  Timer? _progressTimer;

  @override
  void didUpdateWidget(covariant LazyTabStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      HapticFeedback.selectionClick();
      final isFirstLoad = !_loadedTabs.contains(widget.currentIndex);
      if (isFirstLoad) {
        _loadedTabs.add(widget.currentIndex);
      }

      _fadeTimer?.cancel();
      _progressTimer?.cancel();

      setState(() {
        _isSwitching = true;
        _showTopProgress = isFirstLoad;
      });

      _fadeTimer = Timer(const Duration(milliseconds: 25), () {
        if (mounted) {
          setState(() => _isSwitching = false);
        }
      });

      if (isFirstLoad) {
        _progressTimer = Timer(const Duration(milliseconds: 280), () {
          if (mounted) {
            setState(() => _showTopProgress = false);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedOpacity(
          opacity: _isSwitching ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          child: IndexedStack(
            index: widget.currentIndex,
            children: List.generate(widget.tabBuilders.length, (i) {
              if (!_loadedTabs.contains(i)) {
                return const SizedBox.shrink();
              }
              return widget.tabBuilders[i]();
            }),
          ),
        ),
        if (_showTopProgress)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: LinearProgressIndicator(
                minHeight: 2.5,
                color: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
      ],
    );
  }
}
