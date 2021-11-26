import 'package:flutter/material.dart';

import 'dart:async';
import 'package:telephony/telephony.dart';

onBackgroundMessage(SmsMessage message) {
  debugPrint("onBackgroundMessage called");
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    getMessage();
    initPlatformState();
  }

  onMessage(SmsMessage message) async {
    setState(() {
      getMessage();
    });
  }

  Future<void> initPlatformState() async {
    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(
          onNewMessage: onMessage, onBackgroundMessage: onBackgroundMessage);
      getMessage();
    }

    if (!mounted) return;
  }

  List<SmsConversation>? message;
  getMessage() async {
    List<SmsConversation> messages = await telephony.getConversations(
        sortOrder: [OrderBy(ConversationColumn.THREAD_ID, sort: Sort.ASC)]);
    setState(() {
      message = messages;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: message == null
          ? const Center(
              child: Text("Loading"),
            )
          : SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: message!.isEmpty ? 0 : message?.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Sms(
                                        address: message![index]
                                            .threadId
                                            .toString())),
                              );
                            },
                            child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding: EdgeInsets.all(0),
                                      title: Text(
                                        message![index].snippet.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w400,
                                            fontSize: 15,
                                            color: Colors.black),
                                      ),
                                      trailing: Text(
                                        ' ( ' +
                                            message![index]
                                                .messageCount
                                                .toString() +
                                            ' )   ',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 17,
                                            color: Colors.black),
                                      ),
                                    )
                                  ],
                                )),
                          );
                        })
                  ],
                ),
              ),
            ),
    ));
  }
}

class Sms extends StatefulWidget {
  final String? address;
  const Sms({Key? key, @required this.address}) : super(key: key);

  @override
  _SmsState createState() => _SmsState();
}

class _SmsState extends State<Sms> {
  final telephony = Telephony.instance;

  @override
  void initState() {
    super.initState();
    getMessage();
  }

  List<SmsMessage>? recmessage;
  List<SmsMessage>? sentmessage;
  List<SmsMessage>? finalmessage;
  Future getrecMessage() async {
    List<SmsMessage> messages = await telephony.getInboxSms(
      columns: [
        SmsColumn.ADDRESS,
        SmsColumn.DATE,
        SmsColumn.BODY,
        SmsColumn.THREAD_ID
      ],
      filter: SmsFilter.where(SmsColumn.THREAD_ID)
          .equals(widget.address.toString()),
      //.and(SmsColumn.BODY)
      // .like("starwars"),
      sortOrder: [
        OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
        OrderBy(SmsColumn.BODY)
      ],
    );
    setState(() {
      recmessage = messages;
    });
  }

  Future getsentMessage() async {
    List<SmsMessage> messages = await telephony.getSentSms(
      columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.THREAD_ID],
      filter: SmsFilter.where(SmsColumn.THREAD_ID)
          .equals(widget.address.toString()),
      //.and(SmsColumn.BODY)
      // .like("starwars"),
      sortOrder: [
        OrderBy(SmsColumn.ADDRESS, sort: Sort.ASC),
        OrderBy(SmsColumn.BODY)
      ],
    );
    setState(() {
      sentmessage = messages;
    });
  }

  merge() {
    setState(() {
      finalmessage = [...sentmessage!, ...recmessage!];
    });
  }

  getMessage() {
    getrecMessage().whenComplete(getsentMessage).whenComplete(merge);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
      ),
      body: finalmessage == null
          ? const Center(
              child: Text("Loading"),
            )
          : SizedBox(
              height: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                        onPressed: getMessage, child: const Text("Refresh")),
                    ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount:
                            finalmessage!.isEmpty ? 0 : finalmessage?.length,
                        itemBuilder: (BuildContext context, int index) {
                          return GestureDetector(
                            onTap: getMessage,
                            child: Container(
                                margin: const EdgeInsets.all(10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10)),
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        finalmessage![index].address.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 17,
                                            color: Colors.black),
                                      ),
                                    ),
                                    Text(
                                      finalmessage![index].body.toString(),
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black),
                                    ),
                                  ],
                                )),
                          );
                        })
                  ],
                ),
              ),
            ),
    ));
  }
}
