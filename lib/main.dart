import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';

const url = 'https://itsallwidgets.com/podcast/feed';
final pathSuffix = 'dashcast/downloads';

Future<String> _getDownloadPath(String filename) async {
  final dir = await getApplicationDocumentsDirectory();
  final prefix = dir.uri.path;

  final absolutePath = join(prefix, filename);
  print(absolutePath);
  return absolutePath;
}

class Podcast with ChangeNotifier {
  RssFeed _feed = RssFeed();
  RssItem _selectedItem = RssItem();
  Map<String, bool> downloadStatus = {};

  RssFeed get feed => _feed;

  void parse(String url) async {
    final res = await get(Uri.parse(url));
    final xmlStr = res.body;
    _feed = RssFeed.parse(xmlStr);
    notifyListeners();
  }

  RssItem get selectedItem => _selectedItem;

  set selectedItem(RssItem value) {
    _selectedItem = value;
    notifyListeners();
  }

  void download(RssItem item) async {
    final client = Client();

    final req = Request("GET", Uri.parse(item.guid!));
    final res = await client.send(req);

    if (res.statusCode != 200)
      throw Exception('Unexpected Error : ${res.statusCode}');

    final file = File(await _getDownloadPath(split(item.guid!).last));

    // res.stream.listen((bytes) {
    //   print(bytes.length);
    // });

    res.stream.pipe(file.openWrite()).whenComplete(() {
      print('Complete');
    });
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Podcast()..parse(url),
      child: const MaterialApp(
        title: 'The Boring Show!',
        home: EpisodesPage(),
      ),
    );
  }
}

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Consumer<Podcast>(
      builder: (context, podcast, _) {
        return EpisodeListView(rssFeed: podcast.feed);
      },
    ));
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key? key,
    required this.rssFeed,
  }) : super(key: key);

  final RssFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: rssFeed.items!
          .map((e) => ListTile(
                title: Text(e.title!),
                subtitle: Text(
                  e.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    Provider.of<Podcast>(context, listen: false).download(e);
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Downloading ${e.title}')));
                  },
                ),
                onTap: () {
                  Provider.of<Podcast>(context, listen: false).selectedItem = e;
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const PlayerPage()));
                },
              ))
          .toList(),
    );
  }
}

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
        Flexible(flex: 5, child: Image.network(podcast.feed.image!.url!)),
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
    print(url);
    url =
        "/data/user/0/in.theweekenddeveloper.dashcast/app_flutter/episode-33.mp3";
    await _mPlayer.startPlayer(
        fromURI: url,
        codec: Codec.mp3,
        whenFinished: () {
          setState(() {});
        });
    setState(() {});
  }

  void _fastForward() {}

  void _fastRewind() {}

  @override
  Widget build(BuildContext context) {
    final item = Provider.of<Podcast>(context, listen: false).selectedItem;
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
                    _play(item.guid!);
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
