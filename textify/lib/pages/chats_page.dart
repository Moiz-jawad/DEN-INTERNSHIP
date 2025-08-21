//Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';

//Providers
import '../providers/authentication_provider.dart';
import '../providers/chats_page_provider.dart';

//Services
import '../services/navigation_service.dart';

//Pages
import '../pages/chat_page.dart';

//Widgets
import '../widgets/top_bar.dart';
import '../widgets/custom_list_view_tiles.dart';

//Models
import '../models/chat.dart';
import '../models/chat_user.dart';
import '../models/chat_message.dart';

class ChatsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final _deviceHeight = MediaQuery.of(context).size.height;
    final _deviceWidth = MediaQuery.of(context).size.width;
    final _auth = Provider.of<AuthenticationProvider>(context, listen: false);
    final _navigation = Getit.instance.get<NavigationService>();

    return ChangeNotifierProvider<ChatsPageProvider>(
      create: (_) => ChatsPageProvider(_auth),
      child: Builder(
        builder: (context) {
          final _pageProvider = context.watch<ChatsPageProvider>();

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: _deviceWidth * 0.03,
              vertical: _deviceHeight * 0.02,
            ),
            height: _deviceHeight * 0.98,
            width: _deviceWidth * 0.97,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TopBar(
                  'Chats',
                  primaryAction: IconButton(
                    icon: Icon(
                      Icons.logout,
                      color: Color.fromRGBO(0, 82, 218, 1.0),
                    ),
                    onPressed: () => _auth.logout(),
                  ),
                ),
                Expanded(
                  child: _buildChatsList(
                    _pageProvider,
                    _navigation,
                    _deviceHeight,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatsList(
    ChatsPageProvider pageProvider,
    NavigationService navigation,
    double deviceHeight,
  ) {
    final chats = pageProvider.chats;

    if (chats == null) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (chats.isEmpty) {
      return Center(
        child: Text("No Chats Found.", style: TextStyle(color: Colors.white)),
      );
    }

    return ListView.builder(
      itemCount: chats.length,
      itemBuilder: (_, index) =>
          _chatTile(chats[index], navigation, deviceHeight),
    );
  }

  Widget _chatTile(
    Chat chat,
    NavigationService navigation,
    double deviceHeight,
  ) {
    final recipients = chat.recepients();
    final isActive = recipients.any((d) => d.wasRecentlyActive());
    final subtitle = chat.messages.isNotEmpty
        ? chat.messages.first.type != MessageType.TEXT
              ? "Media Attachment"
              : chat.messages.first.content
        : "";

    return CustomListViewTileWithActivity(
      height: deviceHeight * 0.10,
      title: chat.title(),
      subtitle: subtitle,
      imagePath: chat.imageURL(),
      isActive: isActive,
      isActivity: chat.activity,
      onTap: () => navigation.navigateToPage(ChatPage(chat: chat)),
    );
  }
}
