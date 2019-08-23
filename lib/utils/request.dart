import 'dart:io';

import 'package:flutter_downloader/flutter_downloader.dart';

import '../services/system.dart';
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';

class Request {
  static Future<List<int>> getYears() async {
    var url = "https://www.loveq.cn/program.php";
    var response = await http.get(url);
    if (response.statusCode == 200) {
      Document document = parse(response.body);
      List<Element> pages = document.querySelectorAll('.music_month > a');

      return pages.map((Element f) {
        return int.tryParse(f.text.trim());
      }).toList();
    } else {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getDocumentList(
      Document document, SystemService service) async {
    var result = <Map<String, dynamic>>[];
    List<Element> items = document.querySelectorAll('dl.clearfix[id]');
    for (int i = 0; i < items.length; i++) {
      var id = items[i].id.trim().replaceAll('program', '');
      var filename = "${items[i].querySelector("dd").text.trim()}.mp3";
      Map<String, dynamic> obj = {
        "id": id,
        "title": items[i].querySelector("dt").text.trim(),
        "filename": filename,
        "url": "https://www.loveq.cn/program_download.php?id=$id&dl=1"
      };

      var tasks = await service.fileService.getTaskByFilename(filename);
      if (tasks.length > 0) {
        if (tasks.first.status == DownloadTaskStatus.complete &&
            !File("${tasks.first.savedDir}/${tasks.first.filename}")
                .existsSync()) {
          await service.fileService.removeTask(tasks[0].taskId);
        } else {
          obj["taskId"] = tasks[0].taskId;
          obj["status"] = tasks[0].status;
          obj["progress"] = tasks[0].progress;
        }
      }
      result.add(obj);
    }

    return result;
  }

  static Future<List<Map<String, dynamic>>> getList(
      int year, SystemService service) async {
    var url = "https://www.loveq.cn/program.php?&cat_id=1&year=$year";
    var response = await http.get(url);
    var result = <Map<String, dynamic>>[];
    if (response.statusCode == 200) {
      Document document = parse(response.body);
      result.addAll(await getDocumentList(document, service));
      List<Element> pages = document.querySelectorAll('.page > a');
      for (int i = 2; i < pages.length; i++) {
        var url =
            "https://www.loveq.cn/program.php?&cat_id=1&year=$year&page=$i";
        var response = await http.get(url);
        Document document = parse(response.body);
        result.addAll(await getDocumentList(document, service));
      }

      return result;
    } else {
      return result;
    }
  }
}
