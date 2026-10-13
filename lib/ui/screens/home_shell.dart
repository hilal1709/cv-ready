import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/motion.dart';
import '../../core/theme/clay.dart';
import '../../core/theme/palette.dart';
import '../kit/clay_widgets.dart';
import 'account_tab.dart';
import 'cv_list_tab.dart';
import 'match_tab.dart';
import 'update_flow.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  static bool _checkedForUpdate = false;

  @override
  void initState() {
    super.initState();
    if (_checkedForUpdate) return;
    _checkedForUpdate = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) checkForUpdate(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    const tabs = [CvListTab(), MatchTab(), AccountTab()];
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _index = 0);
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: Motion.of(context, Motion.medium),
          switchInCurve: Motion.expoOut,
          transitionBuilder: (child, a) => FadeTransition(
            opacity: a,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.02), end: Offset.zero).animate(a),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_index), child: tabs[_index]),
        ),
        // The nav bar is a clay slab, not a flat band.
        bottomNavigationBar: Container(
          decoration: Clay.box(
            context,
            color: context.clay.surfaceRaised,
            radius: 0,
            depth: 0.9,
          ).copyWith(borderRadius: const BorderRadius.vertical(top: Radius.circular(Clay.radiusXL))),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Hi(HugeIcons.strokeRoundedFolder01),
                selectedIcon: Hi(HugeIcons.strokeRoundedFolder01, size: 24),
                label: 'CV Saya',
              ),
              NavigationDestination(
                icon: Hi(HugeIcons.strokeRoundedTarget02),
                selectedIcon: Hi(HugeIcons.strokeRoundedTarget02, size: 24),
                label: 'Cocokkan',
              ),
              NavigationDestination(
                icon: Hi(HugeIcons.strokeRoundedUserCircle),
                selectedIcon: Hi(HugeIcons.strokeRoundedUserCircle, size: 24),
                label: 'Akun',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
