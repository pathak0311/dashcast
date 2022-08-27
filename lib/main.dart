import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Boring Show!',
      home: BoringPage(),
    );
  }
}

class BoringPage extends StatelessWidget {
  const BoringPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(child: DashCastApp()));
  }
}

class DashCastApp extends StatelessWidget {
  const DashCastApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Flexible(
          flex: 9,
          child: Placeholder(),
        ),
        Flexible(flex: 2, child: AudioControls())
      ],
    );
  }
}

class AudioControls extends StatelessWidget {
  const AudioControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlaybackButtons(),
      ],
    );
  }
}

class PlaybackButtons extends StatelessWidget {
  const PlaybackButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PlaybackButton(),
      ],
    );
  }
}

class PlaybackButton extends StatefulWidget {
  const PlaybackButton({Key? key}) : super(key: key);

  @override
  State<PlaybackButton> createState() => _PlaybackButtonState();
}

class _PlaybackButtonState extends State<PlaybackButton> {
  final FlutterSoundPlayer _mPlayer = FlutterSoundPlayer();
  bool _mPlayerIsInited = false;
  bool _isPlaying = false;
  double _mSubscriptionDuration = 0;
  int playPosition = 0;

  StreamSubscription? _mPlayerSubscription;

  final url =
      "https://incompetech.com/music/royalty-free/mp3-royaltyfree/Surf%20Shimmy.mp3";

  @override
  void initState() {
    super.initState();
    init().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });
  }

  Future<void> init() async {
    await _mPlayer.openPlayer();
    print("setting listener");
    _mPlayerSubscription = _mPlayer.onProgress!.listen((event) {
      print("updated value");
      print(event.position);
      setState(() => playPosition = event.position.inMilliseconds);
    });
  }

  void _stop() async {
    await _mPlayer.stopPlayer();
  }

  void _play() async {
    await _mPlayer.startPlayer(fromURI: url, codec: Codec.mp3, whenFinished: () {
      setState(() {});
    });
    setState(() {});
  }

  void _fastForward() {}

  void _fastRewind() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Slider(
            value: _mSubscriptionDuration,
            onChanged: (value) async {
              _mSubscriptionDuration = value;
              setState(() {});
              await _mPlayer.setSubscriptionDuration(
                  Duration(milliseconds: value.floor()));
            }),
        Row(
          children: [
            IconButton(onPressed: () {}, icon: Icon(Icons.fast_rewind)),
            IconButton(
                onPressed: () {
                  if (_isPlaying) {
                    _stop();
                  } else {
                    _play();
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                icon: (_isPlaying) ? Icon(Icons.stop) : Icon(Icons.play_arrow)),
            IconButton(onPressed: () {}, icon: Icon(Icons.fast_forward)),
          ],
        ),
        Text('$playPosition')
      ],
    );
  }
}
