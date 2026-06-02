import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';

class GroupChatScreen extends StatefulWidget {
  final int myUserId;
  final String myName;
  final String myRole; // 'ADMIN' ou 'COACH'
  final List<Map<String, dynamic>> participants; // participants sélectionnés

  const GroupChatScreen({
    super.key,
    required this.myUserId,
    required this.myName,
    required this.myRole,
    this.participants = const [],
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _textCtrl   = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await DioClient.instance.dio.get(ApiConstants.groupMessages);
      final list = res.data as List;
      if (mounted) {
        setState(() => _messages = List<Map<String, dynamic>>.from(list));
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _textCtrl.clear();
    try {
      await DioClient.instance.dio.post(ApiConstants.groupMessages, data: {
        'senderId':   widget.myUserId,
        'senderName': widget.myName,
        'senderRole': widget.myRole,
        'content':    text,
      });
      await _load();
    } catch (_) {
      if (mounted) _textCtrl.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _timeAgo(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFE5A01A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.groups, color: Color(0xFFE5A01A), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                widget.participants.isEmpty
                    ? 'Groupe Coachs & Admin'
                    : widget.participants.map((p) =>
                        '${p['firstName'] ?? ''} ${p['lastName'] ?? ''}'.trim()).join(', '),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                widget.participants.isEmpty
                    ? 'Canal privé'
                    : '${widget.participants.length} participant${widget.participants.length > 1 ? 's' : ''}',
                style: const TextStyle(color: Color(0xFF888888), fontSize: 11),
              ),
            ]),
          ),
        ]),
      ),
      body: Column(children: [
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.groups_outlined, color: Color(0xFFBBBBBB), size: 56),
                  const SizedBox(height: 12),
                  const Text('Aucun message pour l\'instant',
                      style: TextStyle(color: Color(0xFF888888), fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Soyez le premier à écrire dans le groupe',
                      style: TextStyle(color: const Color(0xFFBBBBBB).withValues(alpha: 0.7), fontSize: 12)),
                ]))
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) => _buildBubble(_messages[i]),
                ),
        ),
        // Input
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            top: false,
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    border: Border.all(color: const Color(0xFFE5A01A).withValues(alpha: 0.3)),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _textCtrl,
                    onSubmitted: (_) => _send(),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Écrire dans le groupe...',
                      hintStyle: TextStyle(color: Color(0xFF666666)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A01A),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: const Color(0xFFE5A01A).withValues(alpha: 0.3), blurRadius: 8)],
                  ),
                  child: _sending
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isMine   = (msg['senderId'] ?? 0).toString() == widget.myUserId.toString();
    final name     = msg['senderName'] ?? '';
    final role     = msg['senderRole'] ?? '';
    final content  = msg['content']    ?? '';
    final time     = _timeAgo(msg['sentAt']?.toString());
    final isAdmin  = role == 'ADMIN';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Nom + badge rôle (seulement si pas moi)
          if (!isMine) Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(name, style: const TextStyle(color: Color(0xFF555555), fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? const Color(0xFFE5A01A).withValues(alpha: 0.15)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAdmin ? 'Admin' : 'Coach',
                  style: TextStyle(
                    color: isAdmin ? const Color(0xFFE5A01A) : const Color(0xFF3B82F6),
                    fontSize: 9, fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
          ),
          // Bulle
          Row(
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                  decoration: BoxDecoration(
                    color: isMine ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: isMine
                        ? const BorderRadius.only(
                            topLeft: Radius.circular(14), topRight: Radius.circular(4),
                            bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14))
                        : const BorderRadius.only(
                            topLeft: Radius.circular(4), topRight: Radius.circular(14),
                            bottomLeft: Radius.circular(14), bottomRight: Radius.circular(14)),
                    border: isMine ? null : Border.all(color: const Color(0xFFE8E8E8), width: 0.5),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(content, style: TextStyle(
                      color: isMine ? Colors.white : const Color(0xFF1A1A1A),
                      fontSize: 14, height: 1.4,
                    )),
                    if (time.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(time, style: TextStyle(
                        color: isMine
                            ? Colors.white.withValues(alpha: 0.5)
                            : const Color(0xFFBBBBBB),
                        fontSize: 10,
                      )),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
