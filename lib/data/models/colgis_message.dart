import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ColgisMessage extends Equatable {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const ColgisMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.sentAt,
    required this.isRead,
  });

  ColgisMessage copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? content,
    DateTime? sentAt,
    bool? isRead,
  }) {
    return ColgisMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      sentAt: sentAt ?? this.sentAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderId': senderId,
    'receiverId': receiverId,
    'content': content,
    'sentAt': Timestamp.fromDate(sentAt),
    'isRead': isRead,
  };

  static ColgisMessage fromJson(Map<String, dynamic> json) => ColgisMessage(
    id: json['id'] as int,
    senderId: json['senderId'] as int,
    receiverId: json['receiverId'] as int,
    content: json['content'] as String,
    sentAt: (json['sentAt'] as Timestamp).toDate(),
    isRead: json['isRead'] as bool? ?? false, // Default to false if null
  );

  @override
  List<Object?> get props => [
    id,
    senderId,
    receiverId,
    content,
    sentAt,
    isRead,
  ];
}