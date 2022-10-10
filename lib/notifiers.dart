import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webfeed/webfeed.dart';

class Podcast with ChangeNotifier {
  late EpisodeFeed _feed;
  late Episode _selectedItem;

  EpisodeFeed get feed => _feed;

  void parse(String url) async {
    final res = await get(Uri.parse(url));
    final xmlStr = res.body;
    _feed = EpisodeFeed.parse(xmlStr);
    notifyListeners();
  }

  Episode get selectedItem => _selectedItem;

  set selectedItem(Episode value) {
    _selectedItem = value;
    notifyListeners();
  }
}

class EpisodeFeed extends RssFeed {
  late RssFeed _feed;
  late List<Episode> items;

  EpisodeFeed(this._feed) {
    items = _feed.items!.map((element) {
      return Episode(element);
    }).toList();
  }

  RssImage get image => _feed.image!;

  static EpisodeFeed parse(xmlStr) {
    return EpisodeFeed(RssFeed.parse(xmlStr));
  }
}

class Episode extends RssItem with ChangeNotifier {
  late String downloadLocation;
  late RssItem _item;

  Episode(this._item);

  String get title => _item.title!;
  String get description => _item.description!;
  String get url => _item.guid!;

  void download([Function(double)? updates]) async {
    final client = Client();

    final req = Request("GET", Uri.parse(_item.guid!));
    final res = await client.send(req);

    if (res.statusCode != 200) {
      throw Exception('Unexpected Error : ${res.statusCode}');
    }

    final contentLength = res.contentLength;
    var downloadedLength = 0;

    String filePath = await _getDownloadPath(split(_item.guid!).last);
    final file = File(filePath);

    // res.stream.listen((bytes) {
    //   print(bytes.length);
    // });
    res.stream
        .map((chunk) {
          downloadedLength += chunk.length;
          if (updates != null) updates(downloadedLength / contentLength!);
          return chunk;
        })
        .pipe(file.openWrite())
        .whenComplete(() {
          downloadLocation = filePath;
          notifyListeners();
        })
        .catchError((error) => print("Error here!"));
  }

  Future<String> _getDownloadPath(String filename) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefix = dir.uri.path;

    final absolutePath = join(prefix, filename);
    print(absolutePath);
    return absolutePath;
  }
}
