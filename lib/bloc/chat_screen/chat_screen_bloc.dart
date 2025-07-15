import 'dart:async';
import 'dart:io';
// import 'package:audioplayers/audioplayers.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:location_tracker/data/repositories/colgis_message_repository.dart';
import 'package:location_tracker/storage/admin_user_storage.dart';
// import 'package:image_picker/image_picker.dart';
import '../../data/models/message.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
import '../../storage/secure_storage.dart';
import '../../storage/user_dto.dart';
import 'chat_screen_event.dart';
import 'chat_screen_state.dart';

class ChatScreenBloc extends Bloc<ChatScreenEvent, ChatScreenState> {
  final MessageService _messageService;
  final ColgisMessageRepository _colgisMessageRepository;
  // final UserService _userService;
  // final int senderId;
  // final int receiverId;
  int? senderId;
  int? receiverId;
  UserModel? user;
  UserModel? admin;
  // final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<List<Message>>? _messageSubscription;

  ChatScreenBloc(
      this._messageService,
      this._colgisMessageRepository,
      // this._userService,
      // this.senderId,
      // this.receiverId,
      ) : super(ChatInitial()) {
    on<LoadChat>(_onLoadChat);
    on<SendMessage>(_onSendMessage);
    on<MarkMessagesAsRead>(_onMarkMessagesAsRead);
    // on<PickImage>(_onPickImage);
    on<UpdateMessages>(_onUpdateMessages);
  }

  Future<void> _onLoadChat(
      LoadChat event,
      Emitter<ChatScreenState> emit,
      ) async {
    emit(ChatLoading());
    try {
      // Fetch initial data synchronously for speed
      // final user = await _userService.fetchUserInfo(event.receiverId);
      await _loadUserFromStorage();
      print("onload  sender: $senderId, receiver: $receiverId");
      final initialMessages = await _messageService.getInitialMessages(
        senderId!,
        receiverId!,
      );

      // Emit initial state
      emit(ChatLoaded(initialMessages, admin!, null));

      // Cancel any existing subscription
      await _messageSubscription?.cancel();
      _messageSubscription = _messageService
          .getMessages(senderId!, receiverId!)
          .listen(
            (messages) {
          // Only add event if the Bloc is not closed
          if (!isClosed) {
            add(UpdateMessages(messages));
          }
        },
        onError: (e) {
          if (!isClosed) {
            add(UpdateMessages([])); // Optionally handle stream errors
          }
        },
      );
    } catch (e) {
      emit(ChatError('Failed to load chat: $e'));
    }
  }

  Future<void> _onUpdateMessages(
      UpdateMessages event,
      Emitter<ChatScreenState> emit,
      ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final incomingMessages =
      event.messages
          .where((m) => m.receiverId == senderId && !m.isRead)
          .toList();
      String? lastMessageId = currentState.lastMessageId;

      if (incomingMessages.isNotEmpty &&
          lastMessageId != incomingMessages.first.id) {
        lastMessageId = incomingMessages.first.id;
        add(MarkMessagesAsRead());
      }
      emit(ChatLoaded(event.messages, currentState.receiver, lastMessageId));
    }
  }

  Future<void> _onSendMessage(
      SendMessage event,
      Emitter<ChatScreenState> emit,
      ) async {
    if (event.content.isNotEmpty) {
      try {
        print("sender: $senderId, receiver: $receiverId");
        await _colgisMessageRepository.sendMessage(
          receiverId!,
          event.content,
          senderId!,
        );
        await _messageService.sendMessage(receiverId!, event.content, senderId!);
      } catch (e) {
        emit(ChatError('Failed to send message: $e'));
      }
    }
  }

  Future<void> _onMarkMessagesAsRead(
      MarkMessagesAsRead event,
      Emitter<ChatScreenState> emit,
      ) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final unread =
      currentState.messages
          .where((m) => !m.isRead && m.receiverId == senderId)
          .toList();
      if (unread.isNotEmpty) {
        try {
          await _messageService.updateMessages(
            unread.map((m) => m.copyWith(isRead: true)).toList(),
          );
        } catch (e) {
          emit(ChatError('Failed to mark messages as read: $e'));
        }
      }
    }
  }

  // Future<void> _onPickImage(
  //     PickImage event,
  //     Emitter<ChatScreenState> emit,
  //     ) async {
  //   try {
  //     final picker = ImagePicker();
  //     final XFile? pickedFile = await picker.pickImage(source: event.source);
  //     if (pickedFile != null) {
  //       final File imageFile = File(pickedFile.path);
  //       final imageUrl = await _uploadImage(imageFile);
  //       if (imageUrl != null) {
  //         await _messageService.sendMessage(receiverId, imageUrl, senderId);
  //       }
  //     }
  //   } catch (e) {
  //     emit(ChatError('Failed to pick image: $e'));
  //   }
  // }

  // Future<String?> _uploadImage(File imageFile) async {
  //   if (kDebugMode) print('Uploading image: ${imageFile.path}');
  //   await Future.delayed(const Duration(seconds: 1)); // Simulate upload
  //   return '[https://example.com/uploaded_image.jpg](https://example.com/uploaded_image.jpg)';
  // }

  Future<void> _loadUserFromStorage() async {
    senderId = await SecureStorage.getUserId();
    user = await SecureStorage.getUser();
    receiverId = await AdminUserStorage.getAdminUserId();
    admin = await AdminUserStorage.getUser();
    print("localStorage  sender: $senderId, receiver: $receiverId");
  }

  @override
  Future<void> close() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    // await _audioPlayer.dispose();
    return super.close();
  }
}