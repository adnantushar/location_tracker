import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location_tracker/screen/auth/login.dart';
import 'package:location_tracker/screen/message/chat_screen.dart';
import 'package:location_tracker/bloc/auth/auth_bloc.dart';
import 'package:location_tracker/bloc/auth/auth_event.dart';
import 'package:location_tracker/bloc/location/location_bloc.dart';
import 'package:location_tracker/data/repositories/auth_repository.dart';
import 'package:location_tracker/services/background_location_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create:
              (context) =>
          AuthBloc(AuthRepository())
            ..add(CheckLoginStatusEvent()),
        ),
        BlocProvider(
          create: (context) => LocationBloc(), // Inject LocationBloc here
        ),
      ],
      child: MultiRepositoryProvider(
        providers: [
          // RepositoryProvider(create: (_) => UserLocationRepository()),
          RepositoryProvider(create: (_) => AuthRepository()),
          // RepositoryProvider(create: (_) => MatchUsersRepository()),
          // RepositoryProvider(create: (_) => UserService()),
          // RepositoryProvider(create: (_) => MessageService()),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          // navigatorKey: navigatorKey,
          // locale: const Locale('ja', 'JP'),
          // supportedLocales: const [Locale('ja', 'JP'), Locale('en', 'US')],
          // localizationsDelegates: [
          //   // Removed const
          //   GlobalMaterialLocalizations.delegate,
          //   GlobalWidgetsLocalizations.delegate,
          //   GlobalCupertinoLocalizations.delegate,
          // ],
          title: 'Flutter Auth with BLoC',
          theme: ThemeData(primarySwatch: Colors.blue),
          initialRoute: '/auth',
          routes: {
            '/auth': (context) => AuthScreen(),
            '/home': (context) => ChatScreen(),
          },
          // onGenerateRoute: (settings) {
          //   if (settings.name == '/chat') {
          //     final args = settings.arguments as Map<String, dynamic>?;
          //     if (args != null) {
          //       return MaterialPageRoute(
          //         builder:
          //             (_) => ChatScreen(
          //           senderId: args['senderId'],
          //           receiverId: args['receiverId'],
          //           route: args['route'],
          //         ),
          //       );
          //     }
          //   }
          //   return null;
          // },
        ),
      ),
    ),
  );

}

