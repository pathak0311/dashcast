import 'package:dashcast/notifiers.dart';
import 'package:dashcast/player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webfeed/webfeed.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final url = 'https://itsallwidgets.com/podcast/feed';

  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => Podcast()..parse(url),
      child: const MaterialApp(
        title: 'The Boring Show!',
        home: MyPage(),
      ),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({Key? key}) : super(key: key);

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  var navIndex = 0;

  final pages = List.unmodifiable([const EpisodesPage(), const DummyPage()]);
  final iconList =
      List<IconData>.unmodifiable([Icons.hot_tub, Icons.timelapse]);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[navIndex],
      bottomNavigationBar: MyNavBar(
        icons: iconList,
        onPressed: (i) => setState(() => navIndex = i),
        activeIndex: navIndex,
      ),
    );
  }
}

class DummyPage extends StatelessWidget {
  const DummyPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: const Text('Dummy Page'),
    );
  }
}

class MyNavBar extends StatefulWidget {
  final List<IconData> icons;
  final Function(int) onPressed;
  final int activeIndex;

  const MyNavBar(
      {Key? key,
      required this.icons,
      required this.onPressed,
      required this.activeIndex})
      : super(key: key);

  @override
  State<MyNavBar> createState() => _MyNavBarState();
}

class _MyNavBarState extends State<MyNavBar>
    with SingleTickerProviderStateMixin {
  double beaconRadius = 0;
  double iconScale = 1;
  double maxBeaconRadius = 20;
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MyNavBar oldWidget) {
    if (oldWidget.activeIndex != widget.activeIndex) {
      _startAnimation();
    }
    super.didUpdateWidget(oldWidget);
  }

  void _startAnimation() {
    _controller.reset();
    final _curve = CurvedAnimation(parent: _controller, curve: Curves.linear);
    Tween<double>(begin: 0, end: 1).animate(_curve).addListener(() {
      setState(() {
        beaconRadius = maxBeaconRadius * _curve.value;
        if (beaconRadius == maxBeaconRadius) beaconRadius = 0;
        if (_curve.value < 0.5) {
          iconScale = 1 + _curve.value;
        } else {
          iconScale = 2 - _curve.value;
        }
      });
    });
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < widget.icons.length; i++)
            _NavBarItem(
              isActive: i == widget.activeIndex,
              iconData: widget.icons[i],
              onPressed: () => widget.onPressed(i),
              beaconRadius: beaconRadius,
              maxBeaconRadius: maxBeaconRadius,
              iconScale: iconScale,
            )
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final bool isActive;
  final double beaconRadius;
  final double maxBeaconRadius;
  final double iconScale;
  final IconData iconData;
  final VoidCallback onPressed;

  const _NavBarItem(
      {Key? key,
      required this.isActive,
      required this.beaconRadius,
      required this.maxBeaconRadius,
      required this.iconScale,
      required this.iconData,
      required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BeaconPainter(
          beaconRadius: isActive ? beaconRadius : 0,
          maxBeaconRadius: maxBeaconRadius,
          beaconColor: Colors.purple),
      child: GestureDetector(
        child: Transform.scale(
          scale: isActive ? iconScale : 1,
          child: Icon(
            iconData,
            color: isActive ? Colors.amber : Colors.black,
          ),
        ),
        onTap: onPressed,
      ),
    );
  }
}

class BeaconPainter extends CustomPainter {
  final double beaconRadius;
  final double maxBeaconRadius;
  final Color beaconColor;
  final Color endColor;

  BeaconPainter(
      {required this.beaconRadius,
      required this.maxBeaconRadius,
      required this.beaconColor})
      : endColor = Color.lerp(beaconColor, Colors.white, 0.9)!;

  @override
  void paint(Canvas canvas, Size size) {
    if (beaconRadius == maxBeaconRadius) return;
    double strokeWidth = beaconRadius < maxBeaconRadius * 0.5
        ? beaconRadius
        : maxBeaconRadius - beaconRadius;
    final paint = Paint()
      ..color = Color.lerp(beaconColor, endColor, beaconRadius)!
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(12, 12), beaconRadius, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class EpisodesPage extends StatelessWidget {
  const EpisodesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<Podcast>(
      builder: (context, podcast, _) {
        return EpisodeListView(rssFeed: podcast.feed);
      },
    );
  }
}

class EpisodeListView extends StatelessWidget {
  const EpisodeListView({
    Key? key,
    required this.rssFeed,
  }) : super(key: key);

  final EpisodeFeed rssFeed;

  @override
  Widget build(BuildContext context) {
    if ((rssFeed.items != null)) {
      return ListView(
        children: rssFeed.items!
            .map((e) => ListTile(
                  title: Text(e.title!),
                  subtitle: Text(
                    e.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Consumer<Episode>(
                    builder:
                        (BuildContext context, Episode value, Widget? child) {
                      if (value.downloadLocation != null) {
                        return child ?? Container();
                      } else {
                        return Container();
                      }
                    },
                    child: IconButton(
                      icon: const Icon(Icons.download),
                      onPressed: () {
                        e.download();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Downloading ${e.title}')));
                      },
                    ),
                  ),
                  onTap: () {
                    Provider.of<Podcast>(context, listen: false).selectedItem =
                        e;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => const PlayerPage()));
                  },
                ))
            .toList(),
      );
    } else {
      return Center(
        child: CircularProgressIndicator(),
      );
    }
  }
}
