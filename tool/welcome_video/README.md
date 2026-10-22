# Welcome screen video

The phone on the welcome screen plays `assets/video/welcome_demo.mp4`, a
real screen recording of the app (with `welcome_demo.jpg`, its first frame,
as the still for "reduce motion"). Re-record it whenever the screens it
shows change.

```sh
tool/welcome_video/record.sh <iOS simulator udid>
```

What it does:

1. Sets a tidy status bar (9:41, full battery) and reinstalls the app, so
   it starts with no data.
2. Records the simulator while `integration_test/welcome_video_test.dart`
   runs. That script seeds a demo profile (weekly Mounjaro, today is shot
   day) and 16 weeks of debug test data, turns on debug Plus and keeps the
   App Store rating prompt away, then taps through: log the dose → pick a
   spot → dose logged → add protein → Progress → Doctor report. It draws a
   soft finger for each tap.
3. `edit.swift` cuts the recording between the script's start and end
   marks, keeps the whole screen (height = 2.17 × width on an iPhone 17),
   scales it to 540 px wide and cross-fades the end into the start so the
   loop has no jump.

Units and dates follow the simulator's region and today's date.
