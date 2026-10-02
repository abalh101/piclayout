import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../collage_editor/editor_page.dart';
import '../projects/state/project_providers.dart';
import 'demo_project_factory.dart';

Future<void> openDemoProjects(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const DemoProjectsPage()));

class DemoProjectsPage extends ConsumerStatefulWidget {
  const DemoProjectsPage({super.key});
  @override
  ConsumerState<DemoProjectsPage> createState() => _DemoProjectsPageState();
}

class _DemoProjectsPageState extends ConsumerState<DemoProjectsPage> {
  bool _busy = false;
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).tr;
    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        appBar: AppBar(title: Text(t('demoProjects'))),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(t('demoDescription')),
          const SizedBox(height: 16),
          if (_busy) const LinearProgressIndicator(),
          for (final design in DemoProjectFactory.designs)
            Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _busy ? null : () => _open(design),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                            height: 110,
                            child: Row(children: [
                              for (final index in design.images)
                                Expanded(
                                    child: Image.asset(
                                        'assets/demo/demo_$index.png',
                                        fit: BoxFit.cover,
                                        height: 110)),
                            ])),
                        ListTile(
                            title: Text(t(design.key)),
                            subtitle: Text(design.ratio.replaceAll('_', ':')),
                            trailing: const Icon(Icons.chevron_right)),
                      ]),
                )),
        ])),
      ),
    );
  }

  Future<void> _open(DemoDesign design) async {
    setState(() => _busy = true);
    final t = AppLocalizations.of(context).tr;
    try {
      final project = await ref
          .read(demoProjectFactoryProvider)
          .createCopy(design, name: t(design.key));
      await ref.read(projectsProvider.notifier).reload();
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => EditorPage(project: project)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(t('operationFailed'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
