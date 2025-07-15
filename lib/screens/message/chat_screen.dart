import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
as local_notifications;
import 'package:location_tracker/data/repositories/colgis_message_repository.dart';
// import 'package:image_picker/image_picker.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/chat_screen/chat_screen_bloc.dart';
import '../../bloc/chat_screen/chat_screen_event.dart';
import '../../bloc/chat_screen/chat_screen_state.dart';
import '../../data/models/message.dart';
import '../../services/message_service.dart';
import '../../services/user_service.dart';
// import '../auth_screen.dart';
// import '../button_details_screen.dart';
// import '../change_password_screen.dart';
// import '../distance_tracker_screen.dart';
// import '../profile/profile_screen.dart';
// import '../profile/user_profile_screen.dart';
// import '../sidebar.dart';
// import '../user_list_screen.dart';
// import 'chat_box_screen.dart';
import 'package:location_tracker/screens/settings_screen.dart';
import 'package:location_tracker/bloc/auth/auth_bloc.dart';
import 'package:location_tracker/bloc/auth/auth_event.dart';
import 'package:location_tracker/screens/auth/login.dart';

class ChatScreen extends StatelessWidget {
  // final int senderId;
  // final int receiverId;
  // final int route;

  const ChatScreen({
    super.key,
    // required this.senderId,
    // required this.receiverId,
    // required this.route,
  });

  @override
  Widget build(BuildContext context) {
    // return BlocProvider(
    //   create:
    //       (context) => ChatScreenBloc(
    //     MessageService(),
    //     ColgisMessageRepository(),
    //     UserService(),
    //     senderId,
    //     receiverId,
    //   )..add(LoadChat(senderId, receiverId)),
    //   child: _ChatScreenView(route: route),
    // );
    return BlocProvider(
      create:
          (context) => ChatScreenBloc(
        MessageService(),
        ColgisMessageRepository(),
        // UserService()
      )..add(LoadChat()),
      child: _ChatScreenView(),
    );
  }
}

class _ChatScreenView extends StatefulWidget {
  // final int route;

  // const _ChatScreenView({required this.route});
  const _ChatScreenView();

  @override
  State<_ChatScreenView> createState() => _ChatScreenViewState();
}

class _ChatScreenViewState extends State<_ChatScreenView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final local_notifications.FlutterLocalNotificationsPlugin
  _notificationsPlugin = local_notifications.FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // _initializeNotificationsAsync();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  // Future<void> _initializeNotificationsAsync() async {
  //   const local_notifications.AndroidInitializationSettings
  //   initializationSettingsAndroid =
  //   local_notifications.AndroidInitializationSettings(
  //     '@mipmap/ic_launcher',
  //   );
  //
  //   const local_notifications.DarwinInitializationSettings
  //   initializationSettingsIOS =
  //   local_notifications.DarwinInitializationSettings();
  //
  //   final local_notifications.InitializationSettings initializationSettings =
  //   local_notifications.InitializationSettings(
  //     android: initializationSettingsAndroid,
  //     iOS: initializationSettingsIOS,
  //   );
  //
  //   await _notificationsPlugin.initialize(initializationSettings);
  // }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // void _showAttachmentOptions(BuildContext context) {
  //   final size = MediaQuery.of(context).size;
  //   final isPad = size.width >= 1200;
  //   final isTablet = size.width >= 600 && size.width < 1200;
  //
  //   showModalBottomSheet(
  //     context: context,
  //     shape: const RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder:
  //         (context) => SafeArea(
  //       child: Wrap(
  //         children: [
  //           ListTile(
  //             leading: Icon(
  //               Icons.photo,
  //               color: const Color(0xFF0088CC),
  //               size:
  //               isPad
  //                   ? size.width * 0.02
  //                   : isTablet
  //                   ? size.width * 0.03
  //                   : size.width * 0.05,
  //             ),
  //             title: Text(
  //               'ギャラリーから写真を選択',
  //               style: TextStyle(
  //                 fontSize:
  //                 isPad
  //                     ? size.width * 0.015
  //                     : isTablet
  //                     ? size.width * 0.025
  //                     : size.width * 0.04,
  //               ),
  //             ),
  //             onTap: () {
  //               Navigator.pop(context);
  //               context.read<ChatScreenBloc>().add(
  //                 const PickImage(ImageSource.gallery),
  //               );
  //             },
  //           ),
  //           ListTile(
  //             leading: Icon(
  //               Icons.camera_alt,
  //               color: const Color(0xFF0088CC),
  //               size:
  //               isPad
  //                   ? size.width * 0.02
  //                   : isTablet
  //                   ? size.width * 0.03
  //                   : size.width * 0.05,
  //             ),
  //             title: Text(
  //               '写真を撮る',
  //               style: TextStyle(
  //                 fontSize:
  //                 isPad
  //                     ? size.width * 0.015
  //                     : isTablet
  //                     ? size.width * 0.025
  //                     : size.width * 0.04,
  //               ),
  //             ),
  //             onTap: () {
  //               Navigator.pop(context);
  //               context.read<ChatScreenBloc>().add(
  //                 const PickImage(ImageSource.camera),
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1200;
    final isPad = size.width >= 1200;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return SafeArea(
      child: Scaffold(
        appBar: _buildAppBar(context, size, isSmallScreen, isTablet, isPad),
        drawer: _buildSidebar(context),
        body: Row(
          children: [
            // if ((isTablet || isPad) && isLandscape)
            //   Container(
            //     width: size.width * 0.25,
            //     constraints: const BoxConstraints(minWidth: 200, maxWidth: 300),
            //     child: _buildSidebar(context),
            //   ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: _buildMessageList(
                      context,
                      size,
                      isSmallScreen,
                      isTablet,
                      isPad,
                    ),
                  ),
                  _buildMessageInput(
                    context,
                    size,
                    isSmallScreen,
                    isTablet,
                    isPad,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      Size size,
      bool isSmallScreen,
      bool isTablet,
      bool isPad,
      ) {
    final titleFontSize =
    isPad
        ? size.width * 0.015
        : isTablet
        ? size.width * 0.025
        : size.width * 0.04;
    final statusFontSize =
    isPad
        ? size.width * 0.01
        : isTablet
        ? size.width * 0.015
        : size.width * 0.03;
    final avatarRadius =
    isPad
        ? size.width * 0.015
        : isTablet
        ? size.width * 0.025
        : size.width * 0.04;

    return AppBar(
      // leading: IconButton(
      //   icon: Icon(
      //     Icons.arrow_back,
      //     color: Colors.white,
      //     size:
      //     isPad
      //         ? size.width * 0.02
      //         : isTablet
      //         ? size.width * 0.03
      //         : size.width * 0.05,
      //   ),
      //   onPressed: () {
      //     if (widget.route == 1) {
      //       Navigator.pushReplacement(
      //         context,
      //         MaterialPageRoute(builder: (_) => const ChatBoxScreen()),
      //       );
      //     } else {
      //       Navigator.pushReplacement(
      //         context,
      //         MaterialPageRoute(builder: (_) => const DistanceTrackerScreen()),
      //       );
      //     }
      //   },
      // ),
      title: BlocBuilder<ChatScreenBloc, ChatScreenState>(
        buildWhen:
            (previous, current) =>
        previous is! ChatLoaded ||
            current is! ChatLoaded ||
            previous != current,
        builder: (context, state) {
          if (state is ChatLoading) {
            return Center(
              child: SizedBox(
                width: avatarRadius,
                height: avatarRadius,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            );
          } else if (state is ChatError) {
            return Center( // Ensures error message is centered
              child: _handleError(context, state.message),
            );
          } else if (state is ChatLoaded) {
            final user = state.receiver;
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                GestureDetector(
                  // onTap: () {
                  //   Navigator.push(
                  //     context,
                  //     MaterialPageRoute(
                  //       builder: (context) => ProfileScreen(user: user),
                  //     ),
                  //   );
                  // },
                  child: CircleAvatar(
                    radius: avatarRadius.clamp(16, 24),
                    // backgroundImage: const AssetImage(
                    //   'assets/person_marker.png',
                    // ),
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 30, color: Colors.white),
                  ),
                ),
                SizedBox(width: isSmallScreen ? 10 : 16),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullname,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: titleFontSize.clamp(14, 18),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Text(
                      //   user.status.toLowerCase() == 'active'
                      //       ? '有効'
                      //       : 'Offline',
                      //   style: TextStyle(
                      //     color: Colors.white.withOpacity(0.7),
                      //     fontSize: statusFontSize.clamp(10, 14),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
              )
            );
          }
          return Center(
            child: Text(
              'Chat',
              style: TextStyle(
                color: Colors.white,
                fontSize: titleFontSize.clamp(14, 18),
              ),
            ),
          );
        },
      ),
      // backgroundColor: const Color(0xFF0088CC),
      centerTitle: true,
      backgroundColor: Colors.lightBlueAccent,
      elevation: 0,
      actions: [
        IconButton(
          icon: Icon(
            Icons.call,
            color: Colors.white,
            size:
            isPad
                ? size.width * 0.02
                : isTablet
                ? size.width * 0.03
                : size.width * 0.05,
          ),
          onPressed: null,
        ),
        IconButton(
          icon: Icon(
            Icons.videocam,
            color: Colors.white,
            size:
            isPad
                ? size.width * 0.02
                : isTablet
                ? size.width * 0.03
                : size.width * 0.05,
          ),
          onPressed: null,
        ),
      ],
    );
  }

  Widget _buildSidebar(BuildContext context) {
  //   return Sidebar(
  //     onHomeTap: () => _navigate(context, const DistanceTrackerScreen()),
  //     onUsersTap: () => _navigate(context, const UserListScreen()),
  //     onTrackLocationTap:
  //         () => _navigate(context, const DistanceTrackerScreen()),
  //     onChatBoxTap: () => _navigate(context, const ChatBoxScreen()),
  //     onChangePasswordTap:
  //         () => _navigate(context, const ChangePasswordScreen()),
  //     onProfileUpdateTap: () => _navigate(context, const UserProfileScreen()),
  //     onLogoutTap: () {
  //       context.read<AuthBloc>().add(LogoutEvent());
  //       _navigate(context, const AuthScreen());
  //     },
  //     onButtonDetailsTap: () => _navigate(context, const ButtonDetailsScreen()),
  //   );
      return Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.lightBlueAccent,
              ),
              child: Text(
                'Location Tracker',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                // Already on ChatScreen, do nothing or navigate to self
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                context.read<AuthBloc>().add(LogoutEvent());
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
            ),
            // Add more list tiles for other navigation options if needed
          ],
        ),
      );
  }

  Widget _buildMessageList(
      BuildContext context,
      Size size,
      bool isSmallScreen,
      bool isTablet,
      bool isPad,
      ) {
    return BlocBuilder<ChatScreenBloc, ChatScreenState>(
      buildWhen:
          (previous, current) =>
      previous is! ChatLoaded ||
          current is! ChatLoaded ||
          previous.messages != current.messages,
      builder: (context, state) {
        if (state is ChatLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ChatError) {
          return _handleError(context, state.message);
        }
        if (state is ChatLoaded) {
          final messages = state.messages;
          if (messages.isEmpty) {
            return Center(
              child: Text(
                '会話を始めましょう！',
                style: TextStyle(
                  fontSize:
                  isPad
                      ? size.width * 0.015
                      : isTablet
                      ? size.width * 0.025
                      : size.width * 0.04,
                ),
              ),
            );
          }
          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              vertical: 8,
              horizontal:
              isPad
                  ? size.width * 0.05
                  : isTablet
                  ? size.width * 0.03
                  : 12,
            ),
            itemCount: messages.length,
            itemBuilder:
                (context, index) => _MessageBubble(
              message: messages[index],
              isSender:
              messages[index].senderId ==
                  context.read<ChatScreenBloc>().senderId,
              size: size,
              isSmallScreen: isSmallScreen,
              isTablet: isTablet,
              isPad: isPad,
            ),
          );
        }
        return Center(
          child: Text(
            '会話を始めましょう！',
            style: TextStyle(
              fontSize:
              isPad
                  ? size.width * 0.015
                  : isTablet
                  ? size.width * 0.025
                  : size.width * 0.04,
            ),
          ),
        );
      },
    );
  }

  Widget _handleError(BuildContext context, String message) {
    final size = MediaQuery.of(context).size;
    final isPad = size.width >= 1200;
    final isTablet = size.width >= 600 && size.width < 1200;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      String dialogTitle = 'エラーが発生しました。';
      String dialogContent = '問題が発生しました。後でもう一度お試しください。';

      if (message.contains('SocketException')) {
        dialogTitle = 'ネットワークエラーが発生しました。';
        dialogContent = 'サーバーへの接続に失敗しました。インターネット接続をご確認ください。';
      }

      showDialog(
        context: context,
        builder:
            (_) => AlertDialog(
          title: Text(
            dialogTitle,
            style: TextStyle(
              fontSize:
              isPad
                  ? size.width * 0.015
                  : isTablet
                  ? size.width * 0.025
                  : size.width * 0.04,
            ),
          ),
          content: Text(
            dialogContent,
            style: TextStyle(
              fontSize:
              isPad
                  ? size.width * 0.012
                  : isTablet
                  ? size.width * 0.02
                  : size.width * 0.035,
            ),
          ),
          actions: [
            TextButton(
              child: Text(
                'わかった',
                style: TextStyle(
                  fontSize:
                  isPad
                      ? size.width * 0.012
                      : isTablet
                      ? size.width * 0.02
                      : size.width * 0.035,
                ),
              ),
              //   onPressed: () {
              //     Navigator.pop(context); // Close dialog
              //     if (widget.route == 1) {
              //       Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(
              //           builder: (_) => const ChatBoxScreen(),
              //         ),
              //       );
              //     } else {
              //       Navigator.pushReplacement(
              //         context,
              //         MaterialPageRoute(
              //           builder: (_) => const DistanceTrackerScreen(),
              //         ),
              //       );
              //     }
              //   },
              // ),
              onPressed: (){print("わかった button tapped");},
            )
          ],
        ),
      );
    });

    return Center(
      child: Padding(
        padding: EdgeInsets.all(
          isPad
              ? size.width * 0.05
              : isTablet
              ? size.width * 0.03
              : 16,
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.red,
            fontSize:
            isPad
                ? size.width * 0.015
                : isTablet
                ? size.width * 0.025
                : size.width * 0.04,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildMessageInput(
      BuildContext context,
      Size size,
      bool isSmallScreen,
      bool isTablet,
      bool isPad,
      ) {
    final avatarRadius =
    isPad
        ? size.width * 0.015
        : isTablet
        ? size.width * 0.025
        : size.width * 0.04;
    final iconSize =
    isPad
        ? size.width * 0.02
        : isTablet
        ? size.width * 0.03
        : size.width * 0.05;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal:
        isPad
            ? size.width * 0.05
            : isTablet
            ? size.width * 0.03
            : 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: const Offset(0, -1),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: Colors.lightBlueAccent,
              size: iconSize,
            ),
            // onPressed: () => _showAttachmentOptions(context),
              onPressed: () {
                print('attachment icon tapped');
              },
          ),
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                isPad
                    ? 200
                    : isTablet
                    ? 160
                    : 120,
              ),
              child: TextField(
                controller: _messageController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  hintText: 'メッセージ...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal:
                    isPad
                        ? size.width * 0.03
                        : isTablet
                        ? size.width * 0.04
                        : 16,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(
                  fontSize:
                  isPad
                      ? size.width * 0.015
                      : isTablet
                      ? size.width * 0.025
                      : size.width * 0.04,
                ),
                onSubmitted: (_) => _sendMessage(context),
              ),
            ),
          ),
          SizedBox(width: isSmallScreen ? 8 : 12),
          CircleAvatar(
            radius: avatarRadius.clamp(16, 24),
            backgroundColor: Colors.lightBlueAccent,
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: Colors.white,
                size: avatarRadius * 0.8,
              ),
              onPressed: () => _sendMessage(context),
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    if (_messageController.text.isNotEmpty) {
      context.read<ChatScreenBloc>().add(SendMessage(_messageController.text));
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isSender;
  final Size size;
  final bool isSmallScreen;
  final bool isTablet;
  final bool isPad;

  const _MessageBubble({
    required this.message,
    required this.isSender,
    required this.size,
    required this.isSmallScreen,
    required this.isTablet,
    required this.isPad,
  });

  @override
  Widget build(BuildContext context) {
    final time = message.sentAt;
    final isImage = message.content.startsWith('http');
    final bubbleMaxWidth =
    isPad
        ? size.width * 0.6
        : isTablet
        ? size.width * 0.65
        : size.width * 0.75;
    final imageSize =
    isPad
        ? size.width * 0.25
        : isTablet
        ? size.width * 0.35
        : size.width * 0.5;
    final textFontSize =
    isPad
        ? size.width * 0.015
        : isTablet
        ? size.width * 0.025
        : size.width * 0.04;
    final timeFontSize =
    isPad
        ? size.width * 0.01
        : isTablet
        ? size.width * 0.015
        : size.width * 0.03;
    final avatarRadius =
    isPad
        ? size.width * 0.015
        : isTablet
        ? size.width * 0.025
        : size.width * 0.04;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSender)
            Padding(
              padding: EdgeInsets.only(right: isSmallScreen ? 8 : 12),
              child: CircleAvatar(
                radius: avatarRadius.clamp(12, 20),
                // backgroundImage: const AssetImage('assets/person_marker.png'),
                backgroundColor: Colors.grey[300],
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
            ),
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
              padding: EdgeInsets.symmetric(
                horizontal:
                isPad
                    ? size.width * 0.02
                    : isTablet
                    ? size.width * 0.03
                    : 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color:
                isSender ? Colors.lightBlueAccent : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(18).copyWith(
                  topLeft:
                  isSender
                      ? const Radius.circular(18)
                      : const Radius.circular(0),
                  topRight:
                  isSender
                      ? const Radius.circular(0)
                      : const Radius.circular(18),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                isSender
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // if (isImage)
                  //   CachedNetworkImage(
                  //     imageUrl: message.content,
                  //     width: imageSize.clamp(150, 300),
                  //     height: imageSize.clamp(150, 300),
                  //     fit: BoxFit.cover,
                  //     placeholder:
                  //         (context, url) =>
                  //     const Center(child: CircularProgressIndicator()),
                  //     errorWidget:
                  //         (context, url, error) => const Icon(
                  //       Icons.broken_image,
                  //       color: Colors.grey,
                  //       size: 50,
                  //     ),
                  //   )
                  // else
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isSender ? Colors.white : Colors.black87,
                        fontSize: textFontSize.clamp(12, 16),
                      ),
                    ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          color:
                          isSender ? Colors.white70 : Colors.grey.shade600,
                          fontSize: timeFontSize.clamp(10, 14),
                        ),
                      ),
                      if (isSender) ...[
                        SizedBox(width: isSmallScreen ? 4 : 8),
                        Icon(
                          message.isRead ? Icons.done_all : Icons.check,
                          size: timeFontSize.clamp(12, 16),
                          color: message.isRead ? Colors.green : Colors.white70,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isSender)
            Padding(
              padding: EdgeInsets.only(left: isSmallScreen ? 8 : 12),
              child: SizedBox(width: avatarRadius.clamp(12, 20)),
            ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:location_tracker/screens/settings_screen.dart';
// import 'package:location_tracker/bloc/auth/auth_bloc.dart';
// import 'package:location_tracker/bloc/auth/auth_event.dart';
// import 'package:location_tracker/screens/auth/login.dart';
//
// class ChatScreen extends StatelessWidget {
//   // final int senderId;
//   // final int receiverId;
//   // final int route;
//
//   const ChatScreen({
//     super.key,
//     // required this.senderId,
//     // required this.receiverId,
//     // required this.route,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat Home'),
//         backgroundColor: Colors.lightBlueAccent,
//       ),
//       drawer: Drawer(
//         child: ListView(
//           padding: EdgeInsets.zero,
//           children: <Widget>[
//             const DrawerHeader(
//               decoration: BoxDecoration(
//                 color: Colors.lightBlueAccent,
//               ),
//               child: Text(
//                 'Location Tracker',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 24,
//                 ),
//               ),
//             ),
//             ListTile(
//               leading: const Icon(Icons.chat),
//               title: const Text('Chat'),
//               onTap: () {
//                 Navigator.pop(context); // Close the drawer
//                 // Already on ChatScreen, do nothing or navigate to self
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.settings),
//               title: const Text('Settings'),
//               onTap: () {
//                 Navigator.pop(context); // Close the drawer
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => const SettingsPage()),
//                 );
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.logout),
//               title: const Text('Logout'),
//               onTap: () {
//                 Navigator.pop(context); // Close the drawer
//                 context.read<AuthBloc>().add(LogoutEvent());
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(builder: (context) => AuthScreen()),
//                 );
//               },
//             ),
//             // Add more list tiles for other navigation options if needed
//           ],
//         ),
//       ),
//       body: const Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.message, size: 100, color: Colors.grey),
//             SizedBox(height: 20),
//             Text(
//               'Welcome to the Chat Screen!',
//               style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//             ),
//             Text(
//               'Use the sidebar to navigate to settings.',
//               style: TextStyle(fontSize: 16, color: Colors.grey),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
