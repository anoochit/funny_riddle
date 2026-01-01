import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:genui_firebase_ai/genui_firebase_ai.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final A2uiMessageProcessor _a2uiMessageProcessor;
  late final GenUiConversation _genUiConversation;

  final _textController = TextEditingController();
  final _surfaceIds = <String>[];

  @override
  void initState() {
    super.initState();

    _a2uiMessageProcessor = A2uiMessageProcessor(
      catalogs: [CoreCatalogItems.asCatalog()],
    );

    final contentGenerator = FirebaseAiContentGenerator(
      catalog: CoreCatalogItems.asCatalog(),
      systemInstruction: '''
        You are an expert in creating funny riddles. Every time I give you a word,
        you should generate UI that displays one new riddle related to that word.
        Each riddle should have both a question and an answer.
        ''',
    );

    // Create the GenUiConversation to orchestrate everything.
    _genUiConversation = GenUiConversation(
      a2uiMessageProcessor: _a2uiMessageProcessor,
      contentGenerator: contentGenerator,
      onSurfaceAdded: _onSurfaceAdded, // Added in the next step.
      onSurfaceDeleted: _onSurfaceDeleted, // Added in the next step.
    );
  }

  // A callback invoked by the [GenUiConversation] when a new UI surface is generated.
  // Here, the ID is stored so the build method can create a GenUiSurface to
  // display it.
  void _onSurfaceAdded(SurfaceAdded update) {
    setState(() {
      _surfaceIds.add(update.surfaceId);
    });
  }

  // A callback invoked by GenUiConversation when a UI surface is removed.
  void _onSurfaceDeleted(SurfaceRemoved update) {
    setState(() {
      _surfaceIds.remove(update.surfaceId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _genUiConversation.dispose();
    super.dispose();
  }

  // Send a message containing the user's text to the agent.
  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    _genUiConversation.sendRequest(UserMessage.text(text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _surfaceIds.length,
              itemBuilder: (context, index) {
                // For each surface, create a GenUiSurface to display it.
                final id = _surfaceIds[index];
                return GenUiSurface(
                  host: _genUiConversation.host,
                  surfaceId: id,
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Enter a message',
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    // Send the user's text to the agent.
                    _sendMessage(_textController.text);
                    _textController.clear();
                  },
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
