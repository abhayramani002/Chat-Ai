import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:hive/hive.dart';

class ChatScreen extends StatefulWidget {
  final String userEmail;

  ChatScreen({required this.userEmail});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final FlutterTts _flutterTts = FlutterTts();
  late stt.SpeechToText _speechToText;
  late Box _chatBox;

  bool _isListening = false;
  List<String> _chatSessions = [];
  String _currentSession = "";

  @override
  void initState() {
    super.initState();
    _speechToText = stt.SpeechToText();
    _initializeHive();
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
    if (_chatBox == null || !_chatBox.isOpen) {
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

    setState(() {
      _messages.add({'sender': 'user', 'message': userMessage});
      _messageController.clear();
    });

    // Simulate AI response (Replace with API integration)
    await Future.delayed(Duration(seconds: 2));
    final aiResponse = "This is AI's response to: $userMessage";

    setState(() {
      _messages.add({'sender': 'ai', 'message': aiResponse});
    });

    await _saveChatHistory();
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.speak(text);
  }

  Widget _buildSidebar() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.userEmail.split('@')[0]),
            accountEmail: Text(widget.userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.teal,
              child: Text(
                widget.userEmail[0].toUpperCase(),
                style: TextStyle(fontSize: 24, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                for (var session in _chatSessions)
                  Container(
                    color: _currentSession == session
                        ? Colors.grey[300]
                        : Colors.transparent,
                    child: ListTile(
                      title: Text(
                        session,
                        style: TextStyle(
                          fontWeight: _currentSession == session
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteChatSession(session),
                      ),
                      onTap: () => _loadChatSession(session),
                    ),
                  ),
                ListTile(
                  leading: Icon(Icons.add),
                  title: Text("New Chat"),
                  onTap: _createNewChatSession,
                ),
              ],
            ),
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout"),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  void _openMicPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.mic, size: 60, color: Colors.redAccent),
              SizedBox(height: 10),
              Text("Listening...", style: TextStyle(fontSize: 16)),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _stopListening();

                  Navigator.pop(context);
                },
                icon: Icon(Icons.stop, color: Colors.white),
                label: Text("Stop"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat with AI"),
        backgroundColor: Colors.teal,
      ),
      drawer: _buildSidebar(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: 250),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.green[100] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                        bottomLeft: isUser ? Radius.circular(10) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : Radius.circular(10),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: !isUser ? 8 : 0),
                        Flexible(
                          child: Text(
                            message['message'],
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (isUser) SizedBox(width: 8),
                        if (!isUser)
                          IconButton(
                            icon: Icon(Icons.volume_up, color: Colors.teal),
                            onPressed: () {
                              _speak(message['message']);
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
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
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
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
    );
  }
}
