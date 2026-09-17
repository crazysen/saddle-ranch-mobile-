import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/auth_provider.dart';
import '../providers/order_session_provider.dart';
import '../services/api_service.dart';
import '../theme/apple_theme.dart';

class _ChatMessage {
  final String id;
  final bool isUser;
  final String text;
  final String time;

  _ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.time,
  });
}

/// AI Chatbot Concierge Modal matching Web AIChatbot.tsx 1:1 in functionality and design
class AiChatbotModal extends StatefulWidget {
  final String currentBranch;

  const AiChatbotModal({super.key, required this.currentBranch});

  static Future<void> show(BuildContext context) {
    final branch = context.read<OrderSessionProvider>().branch;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AiChatbotModal(currentBranch: branch),
    );
  }

  @override
  State<AiChatbotModal> createState() => _AiChatbotModalState();
}

class _AiChatbotModalState extends State<AiChatbotModal> {
  final ApiService _api = ApiService();
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final List<_ChatMessage> _messages = [];
  final Map<String, String> _typedTextMap = {};
  String? _typingMessageId;
  Timer? _typewriterTimer;

  bool _isAiThinking = false;
  List<Product> _cachedProducts = [];
  String? _copiedCode;

  final _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _loadLiveProducts();
    _initWelcomeMessage();
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadLiveProducts() async {
    try {
      final products = await _api.fetchProducts();
      if (mounted) {
        setState(() => _cachedProducts = products);
      }
    } catch (_) {}
  }

  void _initWelcomeMessage() {
    const welcome = 'Welcome to Saddle Ranch! 🤠 How can I assist you today? Select an option below for locations, hours, menu prices, or special promos.';
    final msg = _ChatMessage(
      id: 'welcome-${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text: welcome,
      time: _timeFormat.format(DateTime.now()),
    );
    _messages.add(msg);
    _startTypewriter(msg.id, welcome);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startTypewriter(String messageId, String fullText) {
    _typewriterTimer?.cancel();
    int currentLength = 0;
    _typingMessageId = messageId;
    _typedTextMap[messageId] = '';

    _typewriterTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      currentLength += 3;
      if (currentLength >= fullText.length) {
        currentLength = fullText.length;
        timer.cancel();
        if (mounted) {
          setState(() {
            _typingMessageId = null;
            _typedTextMap[messageId] = fullText;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _typedTextMap[messageId] = fullText.substring(0, currentLength);
          });
        }
      }
      _scrollToBottom();
    });
  }

  String _getLocationsResponse() {
    return '📍 **Saddle Ranch Roadhouse Locations in Cavite**:\n\n'
        '• **Bulihan Branch** (Main):\n'
        '  Block 26 Lot 17, Anahaw St, Silang, Cavite\n'
        '  *(Near Aguinaldo Highway & Silang border)*\n\n'
        '• **Dasmariñas Branch**:\n'
        '  8X23+Q75, Governor\'s Dr, San Agustin I, Dasmariñas, 4114 Cavite\n'
        '  *(Along Governor\'s Drive commercial row)*';
  }

  String _getHoursResponse() {
    return '🕒 **Operating Hours**:\n\n'
        '• **Bulihan Branch**: Mon - Sun (11:00 AM - 11:00 PM)\n'
        '• **Dasmariñas Branch**: Mon - Sun (10:00 AM - 10:00 PM)\n\n'
        '✨ *Both branches accept Dine-in, Pick-up, and Online Delivery daily!*';
  }

  String _getPromosResponse() {
    return '🎉 **Current Discounts & Special Offers**:\n\n'
        '• **FREE Delivery** across the Bulihan service area.\n'
        '• **10% Student Discount** (Present valid student ID upon arrival/pickup).\n'
        '• **20% Senior Citizen & PWD Discount** (Regulatory discount on personal portion).\n'
        '• Use promo code `WELCOME50` for **₱50.00 OFF** online orders over ₱500.00!\n\n'
        '💡 *Tap any promo code below to copy it instantly for checkout.*';
  }

  Future<String> _getVouchersResponse() async {
    try {
      final user = context.read<AuthProvider>().user;
      if (user == null) {
        return '🔐 **Customer Sign-In Required**\n\n'
            'Sign in to your Saddle Ranch account to claim account vouchers, including your **₱50.00 OFF** first-order welcome gift!\n\n'
            'Available store codes you can use right now:\n'
            '• `WELCOME50` — **₱50.00 OFF** (Min spend ₱500.00)\n'
            '• `SADDLE10` — **10% OFF** (Min spend ₱200.00)\n'
            '• `BULIHANFREE` — **15% OFF** (Bulihan Branch, Min spend ₱500.00)\n'
            '• `DASMAFEAST` — **₱100.00 OFF** (Dasma Branch, Min spend ₱750.00)';
      }

      final vouchers = await _api.fetchCustomerVouchers();
      if (vouchers.isNotEmpty) {
        final buffer = StringBuffer('🎁 **Your Customer Account Vouchers**:\n\n');
        for (final v in vouchers) {
          final discount = v.discountType == 'percentage'
              ? '${v.value.toStringAsFixed(0)}% OFF'
              : '₱${v.value.toStringAsFixed(2)} OFF';
          final branchStr = v.branch != 'all' ? ' (${v.branch} Branch)' : '';
          buffer.writeln('• Code: `${v.code}` — **$discount**$branchStr (Min. spend ₱${v.minSpend.toStringAsFixed(2)})');
        }
        buffer.writeln('\n💡 *Tap any code to copy and apply at checkout!*');
        return buffer.toString();
      }
    } catch (_) {}

    return '🎁 **Available Store Vouchers**:\n\n'
        '• `WELCOME50` — **₱50.00 OFF** (Min spend ₱500.00)\n'
        '• `SADDLE10` — **10% OFF** (Min spend ₱200.00)\n'
        '• `BULIHANFREE` — **15% OFF** (Bulihan Branch, Min spend ₱500.00)\n'
        '• `DASMAFEAST` — **₱100.00 OFF** (Dasma Branch, Min spend ₱750.00)\n\n'
        '💡 *Tap any code to copy it!*';
  }

  Future<String> _getPricesResponse({String? filterKeyword}) async {
    List<Product> products = _cachedProducts;
    if (products.isEmpty) {
      try {
        products = await _api.fetchProducts();
        _cachedProducts = products;
      } catch (_) {}
    }

    final branch = widget.currentBranch;
    final branchName = branch == 'Bulihan' ? 'Bulihan Branch' : 'Dasmariñas Branch';

    if (products.isNotEmpty) {
      var displayList = products.where((p) => p.isActive).toList();
      if (filterKeyword != null && filterKeyword.isNotEmpty) {
        final kw = filterKeyword.toLowerCase();
        final matches = displayList.where((p) =>
            p.name.toLowerCase().contains(kw) ||
            p.description.toLowerCase().contains(kw) ||
            (p.category != null && p.category!.toLowerCase().contains(kw))).toList();
        if (matches.isNotEmpty) {
          displayList = matches;
        }
      }

      final topItems = displayList.take(10).toList();
      final buffer = StringBuffer('🥩 **Featured Menu & Prices ($branchName)**:\n\n');
      for (final p in topItems) {
        final price = p.priceForBranch(branch);
        buffer.writeln('• **${p.name}**: ₱${price.toStringAsFixed(2)}');
      }
      buffer.writeln('\n🍴 *Browse the Menu tab for our full selection of sizzling platters, sides, and drinks!*');
      return buffer.toString();
    }

    return '🥩 **Featured Menu Specialties & Prices ($branchName)**:\n\n'
        '• **Sizzling Pork Sisig**: ₱180.00\n'
        '• **Sizzling Pork T-Bone Steak**: ₱250.00\n'
        '• **Sizzling Porterhouse Steak**: ₱320.00\n'
        '• **Sizzling Chicken Steak**: ₱190.00\n'
        '• **Sizzling Gambas**: ₱220.00';
  }

  Future<String> _generateSmartResponse(String userText) async {
    final q = userText.toLowerCase().trim();

    if (RegExp(r'\b(hi|hello|hey|good\s+morning|good\s+afternoon|good\s+evening|howdy|sup)\b').hasMatch(q)) {
      return 'Howdy partner! 🤠 Welcome to Saddle Ranch Roadhouse. Are you looking for our sizzling steaks, branch locations, operating hours, or special vouchers today?';
    }

    if (RegExp(r'\b(location|address|where|branch|branches|bulihan|dasma|silang|directions)\b').hasMatch(q)) {
      return _getLocationsResponse();
    }

    if (RegExp(r'\b(hour|hours|time|open|close|closing|schedule|operating)\b').hasMatch(q)) {
      return _getHoursResponse();
    }

    if (RegExp(r'\b(promo|promos|discount|discounts|student|senior|pwd|sale|offer|offers)\b').hasMatch(q)) {
      return _getPromosResponse();
    }

    if (RegExp(r'\b(voucher|vouchers|coupon|coupons|code|codes|welcome50|saddle10)\b').hasMatch(q)) {
      return await _getVouchersResponse();
    }

    if (RegExp(r'\b(price|prices|menu|cost|steak|sisig|pork|beef|chicken|burger|food|dish|pasta|drinks|platter|t-bone|porterhouse)\b').hasMatch(q)) {
      String? keyword;
      if (q.contains('steak')) {
        keyword = 'steak';
      } else if (q.contains('sisig')) {
        keyword = 'sisig';
      } else if (q.contains('chicken')) {
        keyword = 'chicken';
      } else if (q.contains('pork')) {
        keyword = 'pork';
      } else if (q.contains('burger')) {
        keyword = 'burger';
      }
      return await _getPricesResponse(filterKeyword: keyword);
    }

    if (RegExp(r'\b(qr|table|dine\s*in|in\s*house|unlock|locked|waiter|bell)\b').hasMatch(q)) {
      return '📱 **In-House QR Table Ordering**:\n\n'
          '• Simply scan the QR code located on your dining table.\n'
          '• If your table is currently locked, tap **Request Table Unlock** to notify staff at the cashier station.\n'
          '• Need assistance during your meal? Use the **Call Waiter** buzzer in the app!';
    }

    if (RegExp(r'\b(deliver|delivery|area|areas|cavite|imus|bacoor|general\s+trias)\b').hasMatch(q)) {
      return '🛵 **Delivery Coverage & Policy**:\n\n'
          '• We deliver across Cavite (Silang, Bulihan, Dasmariñas, Imus, Bacoor, and nearby areas).\n'
          '• **Bulihan Area**: Enjoys FREE delivery!\n'
          '• **Remote Delivery**: To safeguard food freshness and rider dispatch, remote delivery orders are handled via **Payment First** (PayMongo QRPh/GCash/Maya/Cards).';
    }

    if (RegExp(r'\b(pay|payment|gcash|maya|qrph|card|cash|paymongo)\b').hasMatch(q)) {
      return '💳 **Accepted Payment Methods**:\n\n'
          '• **Digital Payments**: PayMongo QRPh, GCash, Maya, and Credit/Debit Cards.\n'
          '• **Cash**: Accepted for Pick-up orders and In-House Table Dine-in.\n'
          '• *Note: Remote deliveries require digital payment confirmation before kitchen dispatch.*';
    }

    return 'I\'d be happy to help with that! Here is what I can provide for you right now:\n\n'
        '• 📍 **Locations & Branches**\n'
        '• 🕒 **Daily Operating Hours**\n'
        '• 🥩 **Live Menu Prices**\n'
        '• 🎟️ **Store Discounts & Promos**\n'
        '• 🏷️ **Vouchers & Coupon Codes**\n\n'
        'Tap any of the quick options below, or ask me about our steaks and special meals!';
  }

  Future<void> _handleUserSubmit(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _isAiThinking || _typingMessageId != null) return;

    _inputCtrl.clear();
    _focusNode.unfocus();

    final userMsg = _ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: clean,
      time: _timeFormat.format(DateTime.now()),
    );

    setState(() {
      _messages.add(userMsg);
      _isAiThinking = true;
    });
    _scrollToBottom();

    final responseText = await _generateSmartResponse(clean);
    await Future.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;

    final botMsgId = 'bot-${DateTime.now().millisecondsSinceEpoch}';
    final botMsg = _ChatMessage(
      id: botMsgId,
      isUser: false,
      text: responseText,
      time: _timeFormat.format(DateTime.now()),
    );

    setState(() {
      _isAiThinking = false;
      _messages.add(botMsg);
    });

    _startTypewriter(botMsgId, responseText);
  }

  void _handleQuickOption(String topic) async {
    if (_isAiThinking || _typingMessageId != null) return;
    AppleTheme.hapticFeedback();

    String userLabel = '';
    Future<String> Function() getReply;

    switch (topic) {
      case 'locations':
        userLabel = 'Locations';
        getReply = () async => _getLocationsResponse();
        break;
      case 'hours':
        userLabel = 'Hours';
        getReply = () async => _getHoursResponse();
        break;
      case 'prices':
        userLabel = 'Menu & Prices';
        getReply = () => _getPricesResponse();
        break;
      case 'promos':
        userLabel = 'Promos & Discounts';
        getReply = () async => _getPromosResponse();
        break;
      case 'vouchers':
        userLabel = 'Vouchers';
        getReply = () => _getVouchersResponse();
        break;
      default:
        return;
    }

    final userMsg = _ChatMessage(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      isUser: true,
      text: userLabel,
      time: _timeFormat.format(DateTime.now()),
    );

    setState(() {
      _messages.add(userMsg);
      _isAiThinking = true;
    });
    _scrollToBottom();

    final reply = await getReply();
    await Future.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    final botMsgId = 'bot-${DateTime.now().millisecondsSinceEpoch}';
    final botMsg = _ChatMessage(
      id: botMsgId,
      isUser: false,
      text: reply,
      time: _timeFormat.format(DateTime.now()),
    );

    setState(() {
      _isAiThinking = false;
      _messages.add(botMsg);
    });

    _startTypewriter(botMsgId, reply);
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    AppleTheme.hapticFeedback();
    setState(() => _copiedCode = code);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Voucher code $code copied to clipboard!'),
        backgroundColor: const Color(0xFFF59E0B),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copiedCode = null);
    });
  }

  void _clearChat() {
    _typewriterTimer?.cancel();
    setState(() {
      _messages.clear();
      _typedTextMap.clear();
      _typingMessageId = null;
      _isAiThinking = false;
    });
    _initWelcomeMessage();
  }

  Widget _buildFormattedText(String text) {
    final regex = RegExp(r'(\*\*.*?\*\*|`.*?`)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.workSans(
          color: const Color(0xFF1F2937),
          fontSize: 13.5,
          height: 1.45,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.workSans(
            color: const Color(0xFF1F2937),
            fontSize: 13.5,
            height: 1.45,
          ),
        ));
      }

      final matchedText = match.group(0)!;
      if (matchedText.startsWith('**') && matchedText.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedText.substring(2, matchedText.length - 2),
          style: GoogleFonts.workSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF92400E),
            fontSize: 13.5,
          ),
        ));
      } else if (matchedText.startsWith('`') && matchedText.endsWith('`')) {
        final code = matchedText.substring(1, matchedText.length - 1);
        final isCopied = _copiedCode == code;
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onTap: () => _copyCode(code),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      color: Color(0xFFB45309),
                      fontWeight: FontWeight.bold,
                      fontSize: 11.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isCopied ? LucideIcons.check : LucideIcons.copy,
                    size: 12,
                    color: isCopied ? Colors.green : const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
          ),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.workSans(
          color: const Color(0xFF1F2937),
          fontSize: 13.5,
          height: 1.45,
        ),
      ));
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFFFBFBFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: const Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/saddle_ranch_logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Help Assisstant',
                        style: GoogleFonts.domine(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Clear Chat',
                      onPressed: _clearChat,
                      icon: const Icon(LucideIcons.rotateCcw, size: 18, color: Color(0xFF6B7280)),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(LucideIcons.x, size: 20, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: _messages.length + (_isAiThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isAiThinking && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'AI is thinking...',
                            style: GoogleFonts.workSans(
                              color: const Color(0xFF9CA3AF),
                              fontSize: 12.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                final displayText = msg.isUser
                    ? msg.text
                    : (_typedTextMap[msg.id] ?? msg.text);

                if (msg.isUser) {
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            displayText,
                            style: GoogleFonts.workSans(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.time,
                            style: GoogleFonts.workSans(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                        bottomLeft: Radius.circular(4),
                      ),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormattedText(displayText),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Help Assisstant',
                              style: GoogleFonts.workSans(
                                color: const Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            Text(
                              msg.time,
                              style: GoogleFonts.workSans(
                                color: const Color(0xFF9CA3AF),
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildQuickChip('📍 Locations', 'locations'),
                _buildQuickChip('🕒 Hours', 'hours'),
                _buildQuickChip('🥩 Menu & Prices', 'prices'),
                _buildQuickChip('🎉 Promos', 'promos'),
                _buildQuickChip('🎟️ Vouchers', 'vouchers'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 14 + bottomInset),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: TextField(
                      controller: _inputCtrl,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _handleUserSubmit,
                      style: GoogleFonts.workSans(color: const Color(0xFF1F2937), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Ask about steak, promos, branches...',
                        hintStyle: GoogleFonts.workSans(color: const Color(0xFF9CA3AF), fontSize: 13.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.sendHorizontal, color: Colors.white, size: 18),
                    onPressed: () => _handleUserSubmit(_inputCtrl.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, String topic) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _handleQuickOption(topic),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.workSans(
                color: const Color(0xFF374151),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
