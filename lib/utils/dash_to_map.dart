import 'dart:io';

class SegmentHelper {
  int width;
  int height;
  String frameRate;
  String sar;
  String id;
  int bandwidth;
  String codecs;
  String mimeType;
  String url;
  String indexRange;
  String initialization;

  int startWithSAP;

  SegmentHelper({
    this.width = 0,
    this.height = 0,
    this.frameRate = "30",
    this.sar = "N/A",
    this.startWithSAP = 0,
    required this.id,
    required this.bandwidth,
    required this.codecs,
    required this.mimeType,
    required this.url,
    required this.indexRange,
    required this.initialization,
  });

  String toXml() {
    var extra = "";
    var isVideo = mimeType.startsWith("video");

    if (isVideo) {
      extra =
          'width="$width" height="$height" frameRate="$frameRate" sar="$sar"';
    }

    var xml = '''<Representation
      id="$id"
      bandwidth="$bandwidth"
      codecs="$codecs"
      mimeType="$mimeType"
      startWithSAP="$startWithSAP"
      $extra
    >
      ${isVideo ? '' : '<AudioChannelConfiguration schemeIdUri="urn:mpeg:dash:23003:3:audio_channel_configuration:2011" value="2" />'}
      <BaseURL>${url.replaceAll("&", "&amp;")}</BaseURL>
      <SegmentBase indexRange="$indexRange">
        <Initialization range="$initialization" />
      </SegmentBase>
    </Representation>''';

    return xml;
  }

  static SegmentHelper formBili(Map segment) {
    Map vodAudioId = {"30280": 192000, "30232": 132000, "30216": 64000};
    String id = segment["id"].toString();
    String codecs = segment["codecs"].toString();
    return SegmentHelper(
      width: segment["width"],
      height: segment["height"],
      frameRate: segment["frameRate"],
      sar: segment["sar"],
      id: "${id}_$codecs",
      startWithSAP: segment["startWithSap"],
      bandwidth: vodAudioId[id] ?? segment["bandwidth"],
      codecs: codecs,
      mimeType: segment["mimeType"],
      url: segment["baseUrl"],
      indexRange: segment["segment_base"]["index_range"],
      initialization: segment["segment_base"]["initialization"],
    );
  }
}

class DashHelper {
  int mediaPresentationDuration;
  double minBufferTime;
  List<SegmentHelper> audios;
  List<SegmentHelper> videos;

  DashHelper({
    required this.mediaPresentationDuration,
    required this.minBufferTime,
    required this.audios,
    required this.videos,
  });

  static DashHelper formBili(Map dash) {
    List audios = dash["audio"];
    List videos = dash["video"];

    return DashHelper(
      mediaPresentationDuration: dash["duration"],
      minBufferTime: dash["minBufferTime"],
      audios:
          audios.map((item) {
            return SegmentHelper.formBili(item);
          }).toList(),
      videos:
          videos.map((item) {
            return SegmentHelper.formBili(item);
          }).toList(),
    );
  }

  String toXml() {
    var xml = '''<?xml version="1.0" encoding="UTF-8"?>
<MPD 
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  
    xmlns="urn:mpeg:dash:schema:mpd:2011"
    xmlns:xlink="http://www.w3.org/1999/xlink" 
    xsi:schemaLocation="urn:mpeg:DASH:schema:MPD:2011 http://standards.iso.org/ittf/PubliclyAvailableStandards/MPEG-DASH_schema_files/DASH-MPD.xsd" 
    profiles="urn:mpeg:dash:profile:isoff-live:2011"
    type="static"
    mediaPresentationDuration="PT${mediaPresentationDuration}S"
    minBufferTime="PT${minBufferTime}S"
>
  <Period id="0" start="PT0S">
    <AdaptationSet id="0" contentType="video" startWithSAP="1" >
      ${videos.map((item) => item.toXml()).join("\n      ")}
    </AdaptationSet>
    <AdaptationSet id="1" contentType="audio" startWithSAP="1" >
      ${audios.map((item) => item.toXml()).join("\n      ")}
    </AdaptationSet>
  </Period>
</MPD>''';

    return xml;
  }

  saveXml(String filepath) async {
    File file = File(filepath);
    Directory parentDir = file.parent;
    if (!parentDir.existsSync()) {
      await parentDir.create(recursive: true);
    }
    await file.writeAsString(toXml());
  }
}
