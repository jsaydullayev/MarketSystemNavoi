// /// Login Page
// /// Clean Architecture: Presentation layer with BLoC
// library;

// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../bloc/auth_bloc.dart';
// import '../bloc/events/auth_event.dart';
// import '../bloc/states/auth_state.dart';
// import '../../../../core/constants/app_strings.dart';

// /// Login Page
// class LoginPage extends StatelessWidget {
//   const LoginPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(AppStrings.login),
//       ),
//       body: BlocProvider(
//         create: (context) => AuthBloc(),
//         child: BlocListener<AuthBloc, AuthState>(
//           listener: (context, state) {
//             if (state is AuthErrorState) {
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(content: Text(state.message)),
//               );
//             }
//           },
//           child: BlocBuilder<AuthBloc, AuthState>(
//             builder: (context, state) {
//               if (state is AuthLoadingState) {
//                 return const Center(child: CircularProgressIndicator());
//               }

//               if (state is AuthInitialState) {
//                 return LoginForm();
//               }

//               return const SizedBox.shrink();
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// Login Form Widget
// class LoginForm extends StatefulWidget {
//   const LoginForm({super.key});

//   @override
//   State<LoginForm> createState() => _LoginFormState();
// }

// class _LoginFormState extends State<LoginForm> {
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AuthBloc, AuthState>(
//       builder: (context, state) {
//         return Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               TextField(
//                 controller: _emailController,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: _passwordController,
//                 decoration: const InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                 ),
//                 obscureText: true,
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () {
//                   context.read<AuthBloc>().add(LoginEvent(
//                         email: _emailController.text,
//                         password: _passwordController.text,
//                       ));
//                 },
//                 child: const Text('Login'),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
