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
    return SafeArea(
      child: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(userEmail.split('@')[0]),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.teal,
                child: Text(
                  userEmail[0].toUpperCase(),
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (var session in chatSessions)
                    Container(
                      color: currentSession == session
                          ? Colors.grey[300]
                          : Colors.transparent,
                      child: ListTile(
                        title: Text(
                          session,
                          style: TextStyle(
                            fontWeight: currentSession == session
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => onDeleteSession(session),
                        ),
                        onTap: () => onSessionTap(session),
                      ),
                    ),
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
}
