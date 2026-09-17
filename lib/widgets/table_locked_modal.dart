import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/table_session_status.dart';
import '../services/api_service.dart';
import '../utils/table_code.dart';

/// Result of the locked-table gate.
enum TableLockGateResult {
  /// Staff opened the table — customer may order.
  unlocked,

  /// Customer chose to browse menu while waiting (orders still blocked until unlocked).
  previewMenu,

  /// Dismissed / backed out.
  cancelled,
}

/// Web-matching "Table #XX is Currently Locked" modal + unlock request to staff POS.
class TableLockedModal extends StatefulWidget {
  final String tableNumber;
  final String branch;
  final TableSessionStatus initialSession;

  const TableLockedModal({
    super.key,
    required this.tableNumber,
    required this.branch,
    required this.initialSession,
  });

  /// Shows lock modal when table is not active. Returns unlocked if already open.
  static Future<TableLockGateResult?> showIfLocked(
    BuildContext context, {
    required String tableNumber,
    String branch = 'Bulihan',
  }) async {
    final normalized = TableCode.normalize(tableNumber);
    final branchKey = TableCode.branchFromCode(tableNumber) ?? branch;
    final session = await ApiService().fetchTableSession(
      tableNumber: normalized,
      branch: branchKey,
    );

    if (!session.isLocked) {
      return TableLockGateResult.unlocked;
    }

    if (!context.mounted) return TableLockGateResult.cancelled;

    return showDialog<TableLockGateResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => TableLockedModal(
        tableNumber: normalized,
        branch: branchKey,
        initialSession: session,
      ),
    );
  }

  @override
  State<TableLockedModal> createState() => _TableLockedModalState();
}

class _TableLockedModalState extends State<TableLockedModal> {
  late TableSessionStatus _session;
  String _unlockStatus = 'idle'; // idle | pending | unlocked
  bool _requesting = false;
  Timer? _pollTimer;

  String get _displayTable {
    final t = widget.tableNumber;
    // Keep branch codes like B-08 readable; pad pure digits
    if (RegExp(r'^\d+$').hasMatch(t)) return t.padLeft(2, '0');
    return t;
  }

  @override
  void initState() {
    super.initState();
    _session = widget.initialSession;
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) async {
      final session = await ApiService().fetchTableSession(
        tableNumber: widget.tableNumber,
        branch: widget.branch,
      );
      final unlock = await ApiService().getTableUnlockRequestStatus(
        tableNumber: widget.tableNumber,
      );
      if (!mounted) return;

      setState(() {
        _session = session;
        if (unlock == 'pending' || unlock == 'unlocked') {
          _unlockStatus = unlock;
        }
      });

      if (!session.isLocked || unlock == 'unlocked') {
        _pollTimer?.cancel();
        if (mounted) {
          Navigator.of(context).pop(TableLockGateResult.unlocked);
        }
      }
    });
  }

  Future<void> _requestUnlock() async {
    if (_requesting || _unlockStatus == 'pending') return;
    setState(() => _requesting = true);
    try {
      await ApiService().requestTableUnlock(
        tableNumber: widget.tableNumber,
        branch: widget.branch,
      );
      if (!mounted) return;
      setState(() => _unlockStatus = 'pending');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unlock request sent — waiting for staff.'),
          backgroundColor: Color(0xFFF59E0B),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('ApiException: ', '')),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final expired = _session.isExpired;
    final pending = _unlockStatus == 'pending';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1612),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF534434)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF261E15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
              ),
              child: Icon(
                expired ? LucideIcons.clock : LucideIcons.lock,
                color: const Color(0xFFF59E0B),
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              expired
                  ? 'Table #$_displayTable Session Expired'
                  : 'Table #$_displayTable is Currently Locked',
              textAlign: TextAlign.center,
              style: GoogleFonts.domine(
                color: const Color(0xFFFFC174),
                fontWeight: FontWeight.w700,
                fontSize: 20,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              expired
                  ? 'Your dining session has ended. To prevent off-premise spam ordering, please ask your server or cashier to extend the session.'
                  : 'To prevent remote spam ordering from off-premise scans, this table must be opened by staff before placing orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.workSans(
                color: const Color(0xFFD8C3AD),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: pending || _requesting ? null : _requestUnlock,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  disabledBackgroundColor: const Color(0xFF8B6914),
                  foregroundColor: const Color(0xFF3F2000),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: Icon(
                  pending ? LucideIcons.loaderCircle : LucideIcons.lockOpen,
                  size: 18,
                  color: const Color(0xFF3F2000),
                ),
                label: Text(
                  pending
                      ? 'WAITING FOR STAFF…'
                      : (_requesting ? 'SENDING…' : 'REQUEST TABLE UNLOCK'),
                  style: GoogleFonts.workSans(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 0.4,
                    color: const Color(0xFF3F2000),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.of(context).pop(TableLockGateResult.previewMenu),
              child: Text(
                'Preview Menu While Waiting',
                style: GoogleFonts.workSans(
                  color: const Color(0xFFD8C3AD),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
