import 'dart:async';

import 'package:dashcast/notifiers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:provider/provider.dart';

class PlayerPage extends StatelessWidget {
  const PlayerPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(Provider.of<Podcast>(context).selectedItem.title!),
        ),
        body: const SafeArea(child: const Player()));
  }
}

class Player extends StatelessWidget {
  const Player({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context, listen: false);
    return Column(
      children: [
        Flexible(flex: 5, child: Image.network(podcast.feed.image.url!)),
        Flexible(
          flex: 4,
          child: SingleChildScrollView(
            child: Text(podcast.selectedItem.description!),
          ),
        ),
        const Flexible(flex: 2, child: AudioControls())
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
        const PlaybackButtons(),
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
        const PlaybackButton(),
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

  void _play(String url) async {
    await _mPlayer.startPlayer(
        fromURI: url,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });

    setState(() {
      _isPlaying = true;
    });
  }

  void _fastForward() {}

  void _fastRewind() {}

  @override
  Widget build(BuildContext context) {
    final podcast = Provider.of<Podcast>(context, listen: false);
    final item = podcast.selectedItem;
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
            IconButton(onPressed: () {}, icon: const Icon(Icons.fast_rewind)),
            IconButton(
                onPressed: () {
                  if (_isPlaying) {
                    _stop();
                  } else {
                    var url = item.downloadLocation;
                    print(url);
                    _play(url);
                  }
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                icon: (_isPlaying)
                    ? const Icon(Icons.stop)
                    : const Icon(Icons.play_arrow)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.fast_forward)),
          ],
        ),
        Text('$playPosition')
      ],
    );
  }
}
