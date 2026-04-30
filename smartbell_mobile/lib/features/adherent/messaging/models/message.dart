class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final String? sentAt;
  final bool read;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.sentAt,
    this.read = false,
  });

  factory Message.fromJson(Map<String, dynamic> j) => Message(
    id:         (j['id'] ?? 0).toInt(),
    senderId:   (j['senderId'] ?? j['sender']?['id'] ?? 0).toInt(),
    receiverId: (j['receiverId'] ?? j['receiver']?['id'] ?? 0).toInt(),
    content:    j['content'] ?? j['text'] ?? '',
    sentAt:     j['sentAt'] ?? j['createdAt'],
    read:       j['read'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    'senderId': senderId, 'receiverId': receiverId, 'content': content,
  };
}
