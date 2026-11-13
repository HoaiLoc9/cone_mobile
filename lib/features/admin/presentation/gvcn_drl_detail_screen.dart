import 'package:flutter/material.dart';

import '../../../core/config/app_colors.dart';
import '../data/admin_models.dart';
import '../data/admin_service.dart';

class GvcnDrlDetailScreen extends StatefulWidget {
  const GvcnDrlDetailScreen({
    super.key,
    required this.service,
    required this.assessmentId,
  });

  final AdminService service;
  final String assessmentId;

  @override
  State<GvcnDrlDetailScreen> createState() => _GvcnDrlDetailScreenState();
}

class _GvcnDrlDetailScreenState extends State<GvcnDrlDetailScreen> {
  late Future<GvcnDrlDetail> _future = widget.service.gvcnDrlDetail(
    widget.assessmentId,
  );
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _noteControllers = {};
  final TextEditingController _rankController = TextEditingController();
  bool _prepared = false;
  bool _saving = false;
  bool _approving = false;

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    _rankController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _prepared = false;
      _future = widget.service.gvcnDrlDetail(widget.assessmentId);
    });
  }

  void _prepareControllers(GvcnDrlDetail detail) {
    if (_prepared) return;
    _rankController.text = detail.gvcnXepLoai;
    for (final row in detail.rows) {
      _scoreControllers[row.key] = TextEditingController(
        text: row.classScore == null ? '' : row.classScore!.toStringAsFixed(1),
      );
      _noteControllers[row.key] = TextEditingController(
        text: detail.adminNotes[row.key] ?? '',
      );
    }
    _prepared = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final scores = <String, double?>{};
      final notes = <String, String>{};
      for (final entry in _scoreControllers.entries) {
        final raw = entry.value.text.trim().replaceAll(',', '.');
        scores[entry.key] = raw.isEmpty ? null : double.tryParse(raw);
      }
      for (final entry in _noteControllers.entries) {
        notes[entry.key] = entry.value.text.trim();
      }
      await widget.service.saveGvcnDrl(
        widget.assessmentId,
        classScores: scores,
        adminNotes: notes,
        gvcnXepLoai: _rankController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã lưu điểm GVCN.')));
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleApprove(GvcnDrlDetail detail) async {
    setState(() => _approving = true);
    try {
      if (detail.item.isApproved) {
        await widget.service.disapproveDrl(widget.assessmentId);
      } else {
        await widget.service.approveDrl(widget.assessmentId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            detail.item.isApproved ? 'Đã gỡ duyệt phiếu.' : 'Đã duyệt phiếu.',
          ),
        ),
      );
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _approving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chấm điểm GVCN',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<GvcnDrlDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateMessage(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          final detail = snapshot.data!;
          _prepareControllers(detail);
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              return ListView(
                padding: EdgeInsets.all(isWide ? 26 : 16),
                children: [
                  _StudentHeader(detail: detail),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _rankController,
                    decoration: const InputDecoration(
                      labelText: 'Xếp loại / ghi chú tổng quan GVCN',
                      prefixIcon: Icon(Icons.workspace_premium_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...detail.rows.map(_criterionCard),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Lưu cột GVCN'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _approving ? null : () => _toggleApprove(detail),
                    icon: Icon(
                      detail.item.isApproved
                          ? Icons.undo_rounded
                          : Icons.verified_outlined,
                    ),
                    label: Text(
                      detail.item.isApproved ? 'Gỡ duyệt' : 'Duyệt phiếu',
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _criterionCard(GvcnDrlCriterion row) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBlue.withValues(alpha: .06),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${row.section}. ${row.title}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          if (row.sourceNote.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              row.sourceNote,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: 'SV: ${_score(row.studentScore)}'),
              _Chip(label: 'PCTSV: ${_score(row.advisorScore)}'),
              if (row.maxScore != null)
                _Chip(label: 'Tối đa: ${_score(row.maxScore)}'),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scoreControllers[row.key],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Điểm GVCN',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _noteControllers[row.key],
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Nhận xét',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
        ],
      ),
    );
  }

  String _score(double? value) =>
      value == null ? '-' : value.toStringAsFixed(1);
}

class _StudentHeader extends StatelessWidget {
  const _StudentHeader({required this.detail});

  final GvcnDrlDetail detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.darkBlue, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${detail.student['code'] ?? ''} • ${detail.student['name'] ?? ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            detail.semester['name'] ?? '',
            style: TextStyle(color: Colors.white.withValues(alpha: .86)),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Pill(label: 'SV: ${_score(detail.studentTotal)}'),
              _Pill(label: 'GVCN: ${_score(detail.classTotal)}'),
              _Pill(label: detail.item.isApproved ? 'Đã duyệt' : 'Chưa duyệt'),
            ],
          ),
        ],
      ),
    );
  }

  String _score(double? value) =>
      value == null ? '-' : value.toStringAsFixed(1);
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.primary.withValues(alpha: .08),
      side: BorderSide.none,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
