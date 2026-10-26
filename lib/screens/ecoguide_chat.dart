import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_theme.dart';
import '../models/chat_message.dart';
import '../models/community_report.dart';
import '../models/environmental_item.dart';
import '../models/official_record.dart';
import '../services/chat_store.dart';
import '../services/ecoguide_api.dart';
import '../services/uploads.dart';
import '../widgets/chat/chat_bubble.dart';
import '../widgets/chat/chat_welcome.dart';
import '../widgets/chat/context_header.dart';
import '../widgets/chat/quick_reply_chip.dart';
import 'new_report.dart';
import 'record_detail.dart';
import 'report_detail.dart';

class EcoGuideScreen extends StatefulWidget {
  final EnvironmentalItem? item;
  final String? initialQuestion;

  const EcoGuideScreen({super.key, this.item, this.initialQuestion});

  @override
  State<EcoGuideScreen> createState() => _EcoGuideScreenState();
}

class _EcoGuideScreenState extends State<EcoGuideScreen> {
  final _service = EcoGuideService();
  final _chatService = EcoGuideChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final List<EcoGuideMessage> _messages = [];
  bool _sending = false;
  File? _pendingImage;
  int? _reportingIndex;

  String? get _itemType => widget.item == null
      ? null
      : (widget.item!.isOfficial ? 'record' : 'report');

  // kept apart from _itemType above, which must stay null for the general chat -
  // these just give the general thread a stable doc id/title in Firestore.
  String get _persistItemType => widget.item == null ? 'general' : _itemType!;
  String get _persistItemId => widget.item == null ? 'chat' : widget.item!.id;
  String get _persistItemTitle =>
      widget.item == null ? 'Ask EcoGuide' : widget.item!.title;

  String get _threadId => '${_persistItemType}_$_persistItemId';

  List<String> get _quickReplies => widget.item == null
      ? const [
          'How does EcoSignal MD work?',
          'How do I report an issue?',
          'What should I do if I see illegal dumping?',
          'What do the MDE inspection records mean?',
        ]
      : const [
          'Why is this harmful?',
          'What can be done?',
          'Should I report this?',
          'Who handles this?',
        ];

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    await _loadSavedThread();
    final question = widget.initialQuestion;
    if (mounted && question != null) _send(question);
  }

  Future<void> _loadSavedThread() async {
    final saved = await _chatService.loadThread(_persistItemType, _persistItemId);
    if (!mounted || saved.isEmpty) return;
    setState(() => _messages.addAll(saved));
    _scrollToBottom();
  }

  void _persistThread() {
    _chatService.saveThread(
      itemType: _persistItemType,
      itemId: _persistItemId,
      itemTitle: _persistItemTitle,
      messages: _messages.where((m) => !m.isError).toList(),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppTheme.spaceSmall),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 75);
    if (picked == null || !mounted) return;
    final file = File(picked.path);
    // image_picker occasionally hands back an empty file on the simulator - check before showing it
    if (!await file.exists() || await file.length() == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("That photo couldn't be loaded — try picking it again.")),
        );
      }
      return;
    }
    if (mounted) setState(() => _pendingImage = file);
  }

  Future<String?> _uploadChatImage(File image) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      return await StorageService().uploadChatImage(uid: uid, threadId: _threadId, file: image);
    } catch (_) {
      // the vision call still works off the local file even if this persistence upload fails
      return null;
    }
  }

  Future<void> _send(String text) async {
    final image = _pendingImage;
    var question = text.trim();
    if (question.isEmpty && image != null) {
      question = "What's this, and what should I do about it?";
    }
    if (question.isEmpty || _sending) return;

    final history = _messages.where((m) => !m.isError).toList();

    setState(() {
      _pendingImage = null;
      _sending = true;
      _messages.add(EcoGuideMessage(
        role: EcoGuideRole.user,
        text: question,
        localImage: image,
      ));
    });
    final userMessageIndex = _messages.length - 1;
    _inputController.clear();
    _scrollToBottom();

    // kicked off together, not one after the other - the slower of the two sets the wait
    final uploadFuture = image == null ? null : _uploadChatImage(image);

    try {
      final reply = await _service.ask(
        question: question,
        itemType: _itemType,
        itemId: widget.item?.id,
        history: history,
        image: image,
      );
      final imageUrl = await uploadFuture;
      if (!mounted) return;
      setState(() {
        if (imageUrl != null) {
          _messages[userMessageIndex] = EcoGuideMessage(
            role: EcoGuideRole.user,
            text: question,
            imageUrl: imageUrl,
            localImage: image,
          );
        }
        _messages.add(EcoGuideMessage(role: EcoGuideRole.model, text: reply));
      });
      _persistThread();
    } catch (e) {
      if (!mounted) return;
      setState(
        () => _messages.add(
          EcoGuideMessage(
            role: EcoGuideRole.model,
            text: e.toString().replaceFirst('Exception: ', ''),
            isError: true,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _reportImage(int index, EcoGuideMessage message) async {
    setState(() => _reportingIndex = index);
    try {
      File photo;
      if (message.localImage != null) {
        photo = message.localImage!;
      } else if (message.imageUrl != null) {
        final file = File(
          '${Directory.systemTemp.path}/ecoguide_report_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await FirebaseStorage.instance.refFromURL(message.imageUrl!).writeToFile(file);
        photo = file;
      } else {
        return;
      }
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Report Issue')),
            body: ReportIssueScreen(initialPhoto: photo),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Couldn't open that photo: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _reportingIndex = null);
    }
  }

  void _openItemDetail() {
    final item = widget.item;
    if (item == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => item.isOfficial
            ? RecordDetailScreen(record: item as OfficialRecord)
            : ReportDetailScreen(report: item as CommunityReport),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.aiGradient),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.ai,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EcoGuide AI',
                  style: AppTheme.h3.copyWith(
                    color: Colors.white,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'Your environmental questions, answered.',
                  style: AppTheme.subtitle.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.item != null)
            ContextHeader(item: widget.item!, onTap: _openItemDetail),
          Expanded(
            child: _messages.isEmpty
                ? ChatWelcome(
                    hasItem: widget.item != null,
                    suggestions: _quickReplies,
                    onPick: _send,
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppTheme.spaceMedium),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppTheme.spaceMedium),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return const TypingBubble();
                      }
                      return ChatBubble(
                        message: _messages[index],
                        onReport: () => _reportImage(index, _messages[index]),
                        reporting: _reportingIndex == index,
                      );
                    },
                  ),
          ),
          if (_messages.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spaceMedium,
                ),
                itemCount: _quickReplies.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: AppTheme.spaceSmall),
                itemBuilder: (context, index) {
                  final reply = _quickReplies[index];
                  return QuickReplyChip(
                    label: reply,
                    onTap: () => _send(reply),
                  );
                },
              ),
            ),
          const SizedBox(height: AppTheme.spaceSmall),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spaceMedium,
                vertical: AppTheme.spaceSmall,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_pendingImage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spaceSmall),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            child: Image.file(_pendingImage!, width: 72, height: 72, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setState(() => _pendingImage = null),
                              child: const CircleAvatar(
                                radius: 11,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.close_rounded, size: 13, color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _sending ? null : _pickImage,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        color: AppTheme.ai,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: InputDecoration(
                            hintText: _pendingImage == null
                                ? 'Type your question...'
                                : 'Ask about this photo...',
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: _send,
                          enabled: !_sending,
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceSmall),
                      IconButton.filled(
                        onPressed: _sending
                            ? null
                            : () => _send(_inputController.text),
                        icon: const Icon(Icons.send_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.ai,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
