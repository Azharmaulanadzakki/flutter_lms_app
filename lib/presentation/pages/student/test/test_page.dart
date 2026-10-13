import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../domain/entities/quiz_test.dart';
import '../../../../injection_container.dart';
import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/test/test_bloc.dart';
import '../../../widgets/app_snackbar.dart';
import '../../../widgets/state_views.dart';
import 'widgets/quiz_view.dart';
import 'widgets/result_view.dart';
import 'widgets/test_dialogs.dart';
import 'widgets/test_intro_view.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key, required this.courseId, required this.type});

  final String courseId;
  final TestType type;

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthBloc>().state.user?.uid ?? '';

    return BlocProvider(
      create: (_) => sl<TestBloc>()
        ..add(TestOpened(userId: uid, courseId: courseId, type: type)),
      child: _TestView(userId: uid, courseId: courseId, type: type),
    );
  }
}

class _TestView extends StatelessWidget {
  const _TestView({
    required this.userId,
    required this.courseId,
    required this.type,
  });

  final String userId;
  final String courseId;
  final TestType type;

  /// Detik timer tidak membangun ulang seluruh halaman.
  bool _shouldRebuild(TestState prev, TestState curr) {
    return prev.status != curr.status ||
        prev.index != curr.index ||
        prev.isBusy != curr.isBusy ||
        prev.message != curr.message ||
        prev.result != curr.result ||
        prev.overview != curr.overview ||
        !identical(prev.answers, curr.answers) ||
        !identical(prev.questions, curr.questions);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TestBloc, TestState>(
      listenWhen: (prev, curr) => curr.error != null,
      listener: (context, state) =>
          showAppSnackBar(context, state.error!, isError: true),
      child: BlocBuilder<TestBloc, TestState>(
        buildWhen: _shouldRebuild,
        builder: (context, state) {
          final bloc = context.read<TestBloc>();

          switch (state.status) {
            case TestStatus.loading:
              return _Shell(title: type.label, child: const LoadingView());

            case TestStatus.unavailable:
              return _Shell(
                title: type.label,
                child: EmptyView(
                  icon: Icons.quiz_outlined,
                  message: state.message ?? 'Test belum tersedia.',
                ),
              );

            case TestStatus.failure:
              return _Shell(
                title: type.label,
                child: ErrorView(
                  message: state.message ?? 'Gagal memuat test.',
                  onRetry: () => bloc.add(
                    TestOpened(userId: userId, courseId: courseId, type: type),
                  ),
                ),
              );

            case TestStatus.ready:
              final overview = state.overview!;
              return TestIntroView(
                test: overview.test,
                resume: overview.attempt != null,
                isBusy: state.isBusy,
                onStart: () => bloc.add(const TestBeginPressed()),
              );

            case TestStatus.inProgress:
              return PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, result) async {
                  if (didPop) return;
                  final leave = await confirmLeaveDialog(context);
                  if (leave && context.mounted) context.pop();
                },
                child: QuizView(state: state, type: type),
              );

            case TestStatus.submitting:
              return PopScope(
                canPop: false,
                child: _Shell(
                  title: type.label,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Mengirim jawaban dan menghitung nilai...'),
                      ],
                    ),
                  ),
                ),
              );

            case TestStatus.result:
              return ResultView(result: state.result!, type: type);
          }
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text(title)), body: child);
  }
}