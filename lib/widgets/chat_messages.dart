import 'package:flutter/material.dart';
import 'package:chat_ai/widgets/loader.dart';

class ChatMessages extends StatelessWidget {
  final List<Map<String, dynamic>> messages;
  final Function(String) onSpeakMessage;
  final ScrollController scrollController;
  final bool isLoading;
  final String userEmail;

  const ChatMessages(
      {super.key,
      required this.messages,
      required this.onSpeakMessage,
      required this.scrollController,
      required this.isLoading,
      required this.userEmail});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      reverse: true,
      controller: scrollController,
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (isLoading && index == 0) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.transparent,
                    radius: 15,
                    backgroundImage: NetworkImage(
                      'https://img.freepik.com/free-vector/graident-ai-robot-vectorart_78370-4114.jpg?t=st=1737040122~exp=1737043722~hmac=304d86e3eaec7e242b2e3c6b57baf4de6c9dca4ab9ec2275c6efc29f3728708e&w=1380',
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: LoaderAnimation(),
                  ),
                ],
              ),
            ),
          );
        }

        final reversedIndex =
            isLoading ? messages.length - index : messages.length - 1 - index;
        final message = messages[reversedIndex];
        final isUser = message['sender'] == 'user';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  radius: 15,
                  backgroundImage: NetworkImage(
                    'https://img.freepik.com/free-vector/graident-ai-robot-vectorart_78370-4114.jpg?t=st=1737040122~exp=1737043722~hmac=304d86e3eaec7e242b2e3c6b57baf4de6c9dca4ab9ec2275c6efc29f3728708e&w=1380',
                  ),
                ),
              ),
            Flexible(
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
                    Flexible(
                      child: Text(
                        message['message'],
                        textAlign: TextAlign.left,
                        style: TextStyle(color: Colors.black87),
                      ),
                    ),
                    if (!isUser)
                      IconButton(
                        icon: Icon(Icons.volume_up, color: Colors.teal),
                        onPressed: () => onSpeakMessage(message['message']),
                      ),
                  ],
                ),
              ),
            ),
            if (isUser)
              Padding(
                padding: const EdgeInsets.only(right: 5.0),
                child: CircleAvatar(
                  backgroundColor: Colors.blueGrey,
                  radius: 15,
                  child: Text(
                    userEmail[0]
                        .toUpperCase(), // Get the first letter of the email
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
