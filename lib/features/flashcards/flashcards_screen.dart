import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/ui/app_colors.dart';
import '../../shared/back_app_bar.dart';
import 'flashcard_model.dart';
import 'flashfolder_model.dart';
import 'flashcards_provider.dart';
import 'flashcards_repo.dart';

class FlashcardsScreen extends ConsumerWidget {
  const FlashcardsScreen({super.key});

  // ✅ kolor “jak navigation bar” (indicatorColor w app_theme.dart)
  static const Color kNavColor = AppColors.orange;

  ButtonStyle _studyButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: kNavColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      minimumSize: const Size.fromHeight(46),
    );
  }

  // ✅ wspólny “ładny” styl dialogów (żeby nie nachodziło + wyglądało estetycznie)
  AlertDialog _prettyDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(child: content),
      ),
      actions: actions,
    );
  }

  Widget _dialogActionButton({
    required Widget child,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    final btn = primary
        ? FilledButton(
            onPressed: onPressed,
            child: child,
          )
        : TextButton(
            onPressed: onPressed,
            child: child,
          );

    return SizedBox(height: 44, child: btn);
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return x?.path;
  }

  Widget _thumb(String path, {double size = 44, double radius = 10}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _imagePickerRow({
    required BuildContext context,
    required String? pickedPath,
    required void Function(String? newPath) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final path = await _pickImage();
              if (path == null) return;
              onChanged(path);
            },
            icon: const Icon(Icons.image_outlined),
            label: Text(pickedPath == null ? 'Dodaj obrazek' : 'Zmień obrazek'),
          ),
        ),
        if (pickedPath != null) ...[
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Usuń obrazek',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.delete_outline),
          ),
          _thumb(pickedPath!, size: 44, radius: 8),
        ],
      ],
    );
  }

  Future<String?> _showRenameFolderDialog(BuildContext context, String currentName) async {
    final ctrl = TextEditingController(text: currentName);

    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _prettyDialog(
        context: dialogContext,
        title: 'Zmień nazwę folderu',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              decoration: const InputDecoration(labelText: 'Nazwa'),
            ),
          ],
        ),
        actions: [
          _dialogActionButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          _dialogActionButton(
            primary: true,
            child: const Text('Zapisz'),
            onPressed: () => Navigator.of(dialogContext).pop(ctrl.text.trim()),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteFolderDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _prettyDialog(
        context: dialogContext,
        title: 'Usuń folder?',
        content: const Text('Folder i jego fiszki zostaną usunięte.'),
        actions: [
          _dialogActionButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
          ),
          _dialogActionButton(
            primary: true,
            child: const Text('Usuń'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddFolderDialog(BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => _prettyDialog(
        context: dialogContext,
        title: 'Dodaj folder',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nazwa folderu'),
            ),
          ],
        ),
        actions: [
          _dialogActionButton(
            child: const Text('Anuluj'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          _dialogActionButton(
            primary: true,
            child: const Text('Dodaj'),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              await ref.read(flashcardsProvider.notifier).addFolder(name: name);

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openAddCardDialog(
    BuildContext context,
    WidgetRef ref, {
    String? folderId, // null = bez folderu
  }) async {
    final plCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    String? pickedPath;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return _prettyDialog(
            context: dialogContext,
            title: folderId == null ? 'Dodaj fiszkę' : 'Dodaj fiszkę do folderu',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plCtrl,
                  decoration: const InputDecoration(labelText: 'Polski'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enCtrl,
                  decoration: const InputDecoration(labelText: 'Angielski'),
                ),
                const SizedBox(height: 14),
                _imagePickerRow(
                  context: dialogContext,
                  pickedPath: pickedPath,
                  onChanged: (newPath) => setState(() => pickedPath = newPath),
                ),
              ],
            ),
            actions: [
              _dialogActionButton(
                child: const Text('Anuluj'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              _dialogActionButton(
                primary: true,
                child: const Text('Dodaj'),
                onPressed: () async {
                  final pl = plCtrl.text.trim();
                  final en = enCtrl.text.trim();
                  if (pl.isEmpty || en.isEmpty) return;

                  await ref.read(flashcardsProvider.notifier).addCard(
                        front: pl,
                        back: en,
                        imagePath: pickedPath,
                        folderId: folderId,
                      );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditCardDialog(
    BuildContext context,
    WidgetRef ref,
    Flashcard card,
  ) async {
    final plCtrl = TextEditingController(text: card.front);
    final enCtrl = TextEditingController(text: card.back);
    String? pickedPath = card.imagePath;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return _prettyDialog(
            context: dialogContext,
            title: 'Edytuj fiszkę',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plCtrl,
                  decoration: const InputDecoration(labelText: 'Polski'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enCtrl,
                  decoration: const InputDecoration(labelText: 'Angielski'),
                ),
                const SizedBox(height: 14),
                _imagePickerRow(
                  context: dialogContext,
                  pickedPath: pickedPath,
                  onChanged: (newPath) => setState(() => pickedPath = newPath),
                ),
              ],
            ),
            actions: [
              _dialogActionButton(
                child: const Text('Anuluj'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              _dialogActionButton(
                primary: true,
                child: const Text('Zapisz'),
                onPressed: () async {
                  final pl = plCtrl.text.trim();
                  final en = enCtrl.text.trim();
                  if (pl.isEmpty || en.isEmpty) return;

                  await ref.read(flashcardsProvider.notifier).updateCard(
                        card,
                        front: pl,
                        back: en,
                        imagePath: pickedPath,
                        folderId: card.folderId,
                      );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openStudyMode(BuildContext context, List<Flashcard> cards) {
    if (cards.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StudyScreen(cards: cards),
      ),
    );
  }

  Future<void> _openFabMenu(BuildContext context, WidgetRef ref) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Dodaj fiszkę (bez folderu)'),
              onTap: () => Navigator.pop(context, 'card'),
            ),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Dodaj folder'),
              onTap: () => Navigator.pop(context, 'folder'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'card') {
      await _openAddCardDialog(context, ref, folderId: null);
    } else if (choice == 'folder') {
      await _openAddFolderDialog(context, ref);
    }
  }

  void _openFolder(BuildContext context, FlashFolder folder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FolderScreen(folder: folder),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashcardsProvider);

    return Scaffold(
      appBar: BackAppBar(context: context, title: 'Fiszki'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openFabMenu(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (data) {
          final folders = data.folders;
          final cards = data.cards;
          final noFolder = cards.where((c) => c.folderId == null).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: _studyButtonStyle(),
                        onPressed: cards.isEmpty ? null : () => _openStudyMode(context, cards),
                        child: const Text('Tryb nauki (wszystkie)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        'Foldery',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),

                      if (folders.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.folder_off_outlined),
                            title: Text('Brak folderów'),
                            subtitle: Text('Dodaj folder z +'),
                          ),
                        )
                      else
                        ...folders.map((f) {
                          final count = cards.where((c) => c.folderId == f.id).length;

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.folder_outlined),
                              title: Text(f.name),
                              subtitle: Text('Fiszki: $count'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  await Future.delayed(Duration.zero);
                                  if (!context.mounted) return;

                                  final notifier = ref.read(flashcardsProvider.notifier);

                                  if (value == 'rename') {
                                    final newName = await _showRenameFolderDialog(context, f.name);
                                    if (!context.mounted) return;

                                    if (newName != null && newName.trim().isNotEmpty) {
                                      await notifier.renameFolder(f.id, newName.trim());
                                    }
                                  } else if (value == 'delete') {
                                    final ok = await _showDeleteFolderDialog(context);
                                    if (!context.mounted) return;

                                    if (ok == true) {
                                      await notifier.deleteFolder(f.id);
                                    }
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'rename', child: Text('Zmień nazwę')),
                                  PopupMenuItem(value: 'delete', child: Text('Usuń folder')),
                                ],
                              ),
                              onTap: () => _openFolder(context, f),
                            ),
                          );
                        }),

                      const SizedBox(height: 18),
                      const Text(
                        'Fiszki bez folderu',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),

                      if (noFolder.isEmpty)
                        const Card(
                          child: ListTile(
                            leading: Icon(Icons.style_outlined),
                            title: Text('Brak fiszek bez folderu'),
                          ),
                        )
                      else
                        ...noFolder.map((c) {
                          return Card(
                            child: ListTile(
                              leading: c.imagePath == null
                                  ? const CircleAvatar(
                                      child: Icon(Icons.image_not_supported_outlined),
                                    )
                                  : _thumb(c.imagePath!, size: 48, radius: 10),
                              title: Text('PL: ${c.front}'),
                              subtitle: Text('EN: ${c.back}'),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  await Future.delayed(Duration.zero);
                                  if (!context.mounted) return;

                                  if (value == 'edit') {
                                    await _openEditCardDialog(context, ref, c);
                                  } else if (value == 'delete') {
                                    await ref.read(flashcardsProvider.notifier).removeCard(c.id);
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                                  PopupMenuItem(value: 'delete', child: Text('Usuń')),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FolderScreen extends ConsumerWidget {
  final FlashFolder folder;
  const _FolderScreen({required this.folder});

  static const Color kNavColor = AppColors.orange;

  ButtonStyle _studyButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: kNavColor,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
      minimumSize: const Size.fromHeight(46),
    );
  }

  // ✅ wspólny “ładny” styl dialogów w folderze (żeby było identycznie)
  AlertDialog _prettyDialog({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
  }) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(child: content),
      ),
      actions: actions,
    );
  }

  Widget _dialogActionButton({
    required Widget child,
    required VoidCallback? onPressed,
    bool primary = false,
  }) {
    final btn = primary
        ? FilledButton(onPressed: onPressed, child: child)
        : TextButton(onPressed: onPressed, child: child);

    return SizedBox(height: 44, child: btn);
  }

  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    return x?.path;
  }

  Widget _thumb(String path, {double size = 44, double radius = 10}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(File(path), fit: BoxFit.contain),
      ),
    );
  }

  Widget _imagePickerRow({
    required BuildContext context,
    required String? pickedPath,
    required void Function(String? newPath) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () async {
              final path = await _pickImage();
              if (path == null) return;
              onChanged(path);
            },
            icon: const Icon(Icons.image_outlined),
            label: Text(pickedPath == null ? 'Dodaj obrazek' : 'Zmień obrazek'),
          ),
        ),
        if (pickedPath != null) ...[
          const SizedBox(width: 10),
          IconButton(
            tooltip: 'Usuń obrazek',
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.delete_outline),
          ),
          _thumb(pickedPath!, size: 44, radius: 8),
        ],
      ],
    );
  }

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final plCtrl = TextEditingController();
    final enCtrl = TextEditingController();
    String? pickedPath;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return _prettyDialog(
            context: dialogContext,
            title: 'Dodaj fiszkę — ${folder.name}',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plCtrl,
                  decoration: const InputDecoration(labelText: 'Polski'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enCtrl,
                  decoration: const InputDecoration(labelText: 'Angielski'),
                ),
                const SizedBox(height: 14),
                _imagePickerRow(
                  context: dialogContext,
                  pickedPath: pickedPath,
                  onChanged: (newPath) => setState(() => pickedPath = newPath),
                ),
              ],
            ),
            actions: [
              _dialogActionButton(
                child: const Text('Anuluj'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              _dialogActionButton(
                primary: true,
                child: const Text('Dodaj'),
                onPressed: () async {
                  final pl = plCtrl.text.trim();
                  final en = enCtrl.text.trim();
                  if (pl.isEmpty || en.isEmpty) return;

                  await ref.read(flashcardsProvider.notifier).addCard(
                        front: pl,
                        back: en,
                        imagePath: pickedPath,
                        folderId: folder.id,
                      );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditDialog(BuildContext context, WidgetRef ref, Flashcard card) async {
    final plCtrl = TextEditingController(text: card.front);
    final enCtrl = TextEditingController(text: card.back);
    String? pickedPath = card.imagePath;

    await showDialog(
      context: context,
      useRootNavigator: true,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setState) {
          return _prettyDialog(
            context: dialogContext,
            title: 'Edytuj fiszkę',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: plCtrl,
                  decoration: const InputDecoration(labelText: 'Polski'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: enCtrl,
                  decoration: const InputDecoration(labelText: 'Angielski'),
                ),
                const SizedBox(height: 14),
                _imagePickerRow(
                  context: dialogContext,
                  pickedPath: pickedPath,
                  onChanged: (newPath) => setState(() => pickedPath = newPath),
                ),
              ],
            ),
            actions: [
              _dialogActionButton(
                child: const Text('Anuluj'),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              _dialogActionButton(
                primary: true,
                child: const Text('Zapisz'),
                onPressed: () async {
                  final pl = plCtrl.text.trim();
                  final en = enCtrl.text.trim();
                  if (pl.isEmpty || en.isEmpty) return;

                  await ref.read(flashcardsProvider.notifier).updateCard(
                        card,
                        front: pl,
                        back: en,
                        imagePath: pickedPath,
                        folderId: folder.id,
                      );

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _openStudyMode(BuildContext context, List<Flashcard> cards) {
    if (cards.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _StudyScreen(cards: cards)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(flashcardsProvider);

    return Scaffold(
      appBar: BackAppBar(context: context, title: folder.name),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Błąd: $e')),
        data: (data) {
          final cards = data.cards.where((c) => c.folderId == folder.id).toList();

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: _studyButtonStyle(),
                        onPressed: cards.isEmpty ? null : () => _openStudyMode(context, cards),
                        child: const Text('Tryb nauki'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (cards.isEmpty)
                  const Expanded(
                    child: Center(child: Text('Brak fiszek w folderze. Dodaj pierwszą (+).')),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final c = cards[i];

                        return Card(
                          child: ListTile(
                            leading: c.imagePath == null
                                ? const CircleAvatar(
                                    child: Icon(Icons.image_not_supported_outlined),
                                  )
                                : _thumb(c.imagePath!, size: 48, radius: 10),
                            title: Text('PL: ${c.front}'),
                            subtitle: Text('EN: ${c.back}'),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) async {
                                await Future.delayed(Duration.zero);
                                if (!context.mounted) return;

                                if (value == 'edit') {
                                  await _openEditDialog(context, ref, c);
                                } else if (value == 'delete') {
                                  await ref.read(flashcardsProvider.notifier).removeCard(c.id);
                                }
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edytuj')),
                                PopupMenuItem(value: 'delete', child: Text('Usuń')),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StudyScreen extends StatefulWidget {
  final List<Flashcard> cards;
  const _StudyScreen({required this.cards});

  @override
  State<_StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends State<_StudyScreen> {
  final _rng = Random();
  int idx = 0;
  bool showBack = false;
  bool plToEn = true;

  @override
  void initState() {
    super.initState();
    _randomDirection();
  }

  void _randomDirection() {
    plToEn = _rng.nextBool();
  }

  void _next() {
    setState(() {
      showBack = false;
      idx = (idx + 1) % widget.cards.length;
      _randomDirection();
    });
  }

  void _prev() {
    setState(() {
      showBack = false;
      idx = (idx - 1) < 0 ? widget.cards.length - 1 : idx - 1;
      _randomDirection();
    });
  }

  // ✅ flaga zależy od tego, JAKI JĘZYK AKTUALNIE WIDZISZ (front/back + direction)
  String _flagForCurrentlyVisibleLanguage() {
    final showingFront = !showBack;

    // FRONT:
    // - plToEn => FRONT = PL
    // - !plToEn => FRONT = EN
    //
    // BACK:
    // - plToEn => BACK = EN
    // - !plToEn => BACK = PL
    final isPolish = (showingFront && plToEn) || (!showingFront && !plToEn);
    return isPolish ? '🇵🇱' : '🇬🇧';
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cards[idx];

    final frontText = plToEn ? card.front : card.back;
    final backText = plToEn ? card.back : card.front;

    final flag = _flagForCurrentlyVisibleLanguage();

    return Scaffold(
      appBar: AppBar(title: const Text('Tryb nauki')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ flaga na środku u góry
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 10),
              child: Text(
                flag,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
            ),
            if (card.imagePath != null) ...[
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(card.imagePath!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => showBack = !showBack),
                child: Card(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        showBack ? backText : frontText,
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _prev,
                    child: const Text('Poprzednia'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _next,
                    child: const Text('Następna'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${idx + 1}/${widget.cards.length}'),
          ],
        ),
      ),
    );
  }
}