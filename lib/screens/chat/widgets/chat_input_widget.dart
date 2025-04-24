import 'package:flutter/material.dart';
import 'package:elitara/localization/locale_provider.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isMessageValid;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isMessageValid,
  });

  @override
  _ChatInputWidgetState createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final String section = 'chat';

  double _calculateButtonOffset() {
    final lineCount = '\n'.allMatches(widget.controller.text).length + 1;
    if (lineCount <= 1) {
      return 8;
    } else {
      return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider =
        Localizations.of<LocaleProvider>(context, LocaleProvider)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.25,
              ),
              child: Stack(
                children: [
                  TextField(
                    controller: widget.controller,
                    keyboardType: TextInputType.multiline,
                    minLines: 1,
                    maxLines: null,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText:
                          localeProvider.translate(section, 'type_a_message'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: const BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide:
                            const BorderSide(color: Colors.blue, width: 2),
                      ),
                      contentPadding: const EdgeInsets.fromLTRB(22, 16, 60, 16),
                    ),
                  ),
                  if (widget.isMessageValid)
                    Positioned(
                      right: 10,
                      bottom: _calculateButtonOffset(),
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: ElevatedButton(
                          onPressed: widget.onSend,
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: EdgeInsets.zero,
                            backgroundColor: Colors.green,
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
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
