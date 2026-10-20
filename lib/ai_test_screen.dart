
import 'package:flutter/material.dart';
import 'services/gemma_service.dart';

class AiTestScreen extends StatefulWidget {
  const AiTestScreen({super.key});

  @override
  State<AiTestScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends State<AiTestScreen> {
  final _service = GemmaService();
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];

  bool _loading = false;

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _loading) return;

    _controller.clear();

    setState(() {
      _messages.add({'role': 'You', 'text': text});
      _loading = true;
    });

    try {
      final answer = await _service.sendMessage(text);

      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'UniBus AI', 'text': answer});
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'role': 'Error',
          'text': 'Could not reach Gemma. Check that the backend is running.',
        });
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniBus AI Assistant'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];

                    return Card(
                      child: ListTile(
                        title: Text(message['role']!),
                        subtitle: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(message['text']!),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_loading)
                const LinearProgressIndicator(),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_loading,
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: 'Ask about university buses...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _loading ? null : _sendMessage,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
