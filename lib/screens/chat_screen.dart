import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:hive/hive.dart';
import '../widgets/sidebar.dart';
import '../widgets/mic_popup.dart';
import '../services/api_service.dart';
import '../widgets/chat_messages.dart';

class ChatScreen extends StatefulWidget {
  final String userEmail;

  const ChatScreen({super.key, required this.userEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late ScrollController _scrollController;
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speechToText;
  late Box _chatBox;
  bool _isLoading = false;
  bool _isListening = false;
  List<String> _chatSessions = [];
  String _currentSession = "";
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _scrollController = ScrollController();
    _scrollController.addListener(() {
      if (_scrollController.offset > 100) {
        setState(() {
          _showScrollToBottom = true;
        });
      } else {
        setState(() {
          _showScrollToBottom = false;
        });
      }
    });
    _initializeHive();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeHive() async {
    _chatBox = await Hive.openBox('chatBox');
    if (_chatBox.containsKey(widget.userEmail)) {
      final userData = _chatBox.get(widget.userEmail);
      setState(() {
        _chatSessions = List<String>.from(userData['sessions'] ?? []);
      });
    }
    // Always start a new chat session on login
    await _createNewChatSession();
  }

  Future<void> _saveChatHistory() async {
    final userData =
        _chatBox.get(widget.userEmail, defaultValue: {'sessions': []});
    userData['sessions'] = _chatSessions;

    // Ensure messages are properly saved as List<Map<String, dynamic>>
    userData[_currentSession] =
        _messages.map((e) => Map<String, dynamic>.from(e)).toList();

    await _chatBox.put(widget.userEmail, userData);
  }

  Future<void> _createNewChatSession() async {
    if (!_chatBox.isOpen) {
      _chatBox = await Hive.openBox('chatBox');
    }

    final newSession = "Chat ${_chatSessions.length + 1}";
    setState(() {
      _chatSessions.add(newSession);
      _currentSession = newSession;
      _messages.clear();
    });

    await _saveChatHistory();
  }

  Future<void> _deleteChatSession(String session) async {
    final userData = _chatBox.get(widget.userEmail);

    // Remove the session and its messages
    userData.remove(session);
    _chatSessions.remove(session);

    // Renumber the remaining chat sessions
    final updatedSessions = <String>[];
    final updatedMessages = {};

    for (int i = 0; i < _chatSessions.length; i++) {
      final newSessionName = "Chat ${i + 1}";
      updatedSessions.add(newSessionName);

      // Update the session messages with the new session name
      updatedMessages[newSessionName] =
          userData[_chatSessions[i]] ?? []; // Preserve existing messages
      userData.remove(_chatSessions[i]); // Remove old session name
    }

    // Save the updated sessions and messages
    userData['sessions'] = updatedSessions;
    userData.addAll(updatedMessages);
    _chatSessions = updatedSessions;

    if (_currentSession == session) {
      // Load the first available session or create a new one
      if (_chatSessions.isNotEmpty) {
        _loadChatSession(_chatSessions.first);
      } else {
        await _createNewChatSession();
      }
    }

    await _chatBox.put(widget.userEmail, userData);
    setState(() {});
  }

  void _loadChatSession(String session) {
    setState(() {
      _currentSession = session;
      _messages.clear();

      // Safely convert the retrieved data to List<Map<String, dynamic>>
      final rawMessages = _chatBox.get(widget.userEmail)[session] ?? [];
      _messages.addAll(
        List<Map<String, dynamic>>.from(
          rawMessages.map((e) => Map<String, dynamic>.from(e)),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _logout(BuildContext context) async {
    await Hive.close();
    Navigator.pushReplacementNamed(context, '/login');
  }

  Future<void> _startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speechToText.listen(
          onResult: (result) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });
          },
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: false,
        );
      }
    }
  }

  void _stopListening() async {
    if (_isListening) {
      await _speechToText.stop();
      setState(() => _isListening = false);
    }
  }

  Future<void> _sendMessage() async {
    final userMessage = _messageController.text.trim();
    if (userMessage.isEmpty) return;
    _scrollToBottom();
    setState(() {
      _messages.add({'sender': 'user', 'message': userMessage});
      _messageController.clear();
      _isLoading = true;
    });
    final List<Map<String, String>> messageHistory = _messages.map((msg) {
      return {
        "role": msg['sender'] == 'user' ? "user" : "assistant",
        "content": msg['message'].toString(), // Ensure the content is a String
      };
    }).toList();

    final aiResponse = await ApiService.fetchAiResponse(messageHistory);
    setState(() {
      _messages.add({'sender': 'ai', 'message': aiResponse});
      _isLoading = false;
    });
    _scrollToBottom();
    await _saveChatHistory();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  void _openMicPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MicPopup(
        onStopListening: _stopListening,
      ),
    );

    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text("Chat with AI"),
            backgroundColor: Colors.teal,
          ),
          drawer: Sidebar(
            userEmail: widget.userEmail,
            chatSessions: _chatSessions,
            currentSession: _currentSession,
            onSessionTap: _loadChatSession,
            onDeleteSession: _deleteChatSession,
            onCreateNewSession: _createNewChatSession,
            onLogout: () => _logout(context),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (_messages.isEmpty)
                        Center(
                          child: Image.asset(
                            'assets/gif/robot.gif',
                            fit: BoxFit.contain,
                          ),
                        ),
                      if (_messages.isNotEmpty || _isLoading)
                        ChatMessages(
                          messages: _messages,
                          onSpeakMessage: _speak,
                          scrollController: _scrollController,
                          isLoading: _isLoading,
                          userEmail: widget.userEmail,
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(8),
                  color: Colors.grey[200],
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _openMicPopup,
                        child: Icon(
                          Icons.mic,
                          color: Colors.redAccent,
                          size: 30,
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          autofocus: false,
                          controller: _messageController,
                          maxLines: 3,
                          minLines: 1,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: "Type your message",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.send, color: Colors.teal),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showScrollToBottom)
          Positioned(
            bottom: 70,
            right: 20,
            child: FloatingActionButton(
              onPressed: _scrollToBottom,
              child: Icon(Icons.arrow_downward),
            ),
          ),
      ],
    );
  }
}
