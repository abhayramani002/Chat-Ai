import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final String userEmail;
  final List<String> chatSessions;
  final String currentSession;
  final Function(String) onSessionTap;
  final Function(String) onDeleteSession;
  final VoidCallback onCreateNewSession;
  final VoidCallback onLogout;

  const Sidebar({
    super.key,
    required this.userEmail,
    required this.chatSessions,
    required this.currentSession,
    required this.onSessionTap,
    required this.onDeleteSession,
    required this.onCreateNewSession,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    String userInitial =
        userEmail.isNotEmpty ? userEmail[0].toUpperCase() : '?';

    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                userEmail.isNotEmpty ? userEmail.split('@')[0] : 'Guest User',
                overflow: TextOverflow.ellipsis,
              ),
              accountEmail: Text(
                userEmail.isNotEmpty ? userEmail : 'No Email',
                overflow: TextOverflow.ellipsis,
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Text(
                  userInitial,
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (var session in chatSessions)
                    _buildChatSessionTile(context, session),
                  ListTile(
                    leading: Icon(Icons.add),
                    title: Text("New Chat"),
                    onTap: onCreateNewSession,
                  ),
                ],
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout"),
              onTap: onLogout,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatSessionTile(BuildContext context, String session) {
    return Container(
      color: currentSession == session
          ? Colors.teal.withOpacity(0.2)
          : Colors.transparent,
      child: ListTile(
        title: Text(
          session,
          style: TextStyle(
            fontWeight:
                currentSession == session ? FontWeight.bold : FontWeight.normal,
            color: currentSession == session ? Colors.teal : Colors.black,
          ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Delete Chat'),
                  content: Text('Are you sure you want to delete $session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onDeleteSession(session);
                      },
                      child:
                          Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              },
            );
          },
        ),
        onTap: () => onSessionTap(session),
      ),
    );
  }
}
