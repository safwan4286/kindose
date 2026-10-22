import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';


/// The welcome screen's demo: a real screen recording of the app
/// (assets/video/welcome_demo.mp4, made by tool/welcome_video/record.sh),
/// played muted on a loop inside the phone.
///
/// It plays only while the welcome screen is on screen and the app is in
/// front, and shows the still poster (the clip's first frame) when the
/// phone asks to reduce motion or the video can't play.
class DemoVideo extends StatefulWidget {
  const DemoVideo({super.key, required this.builder});

  /// Builds the screen around the demo; hand [video] to [DemoScreen]. It
  /// is null until the clip is ready (and stays null when it can't play),
  /// and then the poster shows.
  final Widget Function(BuildContext context, VideoPlayerController? video)
  builder;

  static const String asset = 'assets/video/welcome_demo.mp4';
  static const String poster = 'assets/video/welcome_demo.jpg';

  /// Width ÷ height of the clip (and the phone's screen).
  static const double aspect = 540 / 1174;

  @override
  State<DemoVideo> createState() => _DemoVideoState();
}

class _DemoVideoState extends State<DemoVideo> with WidgetsBindingObserver {
  VideoPlayerController? _video;
  bool _ready = false;
  bool _motion = true;
  bool _onScreen = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _load();
  }

  Future<void> _load() async {
    final video = VideoPlayerController.asset(
      DemoVideo.asset,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _video = video;
    try {
      await video.initialize();
      await video.setVolume(0);
      await video.setLooping(true);
    } catch (_) {
      // No video (tests, an odd device): the poster stays.
      return;
    }
    if (!mounted) return;
    setState(() => _ready = true);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _motion = !MediaQuery.disableAnimationsOf(context);
    // Off while another route covers the welcome screen.
    _onScreen = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final video = _video;
    if (!_ready || video == null) return;
    final play = _motion && _onScreen && _foreground;
    if (play && !video.value.isPlaying) {
      video.play();
    } else if (!play && video.value.isPlaying) {
      video.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _video?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _ready && _motion ? _video : null);
}

/// What the phone's screen shows: the clip, or its poster until it plays.
class DemoScreen extends StatelessWidget {
  const DemoScreen({super.key, required this.video});

  final VideoPlayerController? video;

  @override
  Widget build(BuildContext context) {
    final v = video;
    final poster = Image.asset(
      DemoVideo.poster,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      excludeFromSemantics: true,
      gaplessPlayback: true,
    );
    if (v == null) return poster;
    return Stack(
      fit: StackFit.expand,
      children: [
        poster,
        FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: v.value.size.width,
            height: v.value.size.height,
            child: VideoPlayer(v),
          ),
        ),
      ],
    );
  }
}
