# FFmpeg Recipes and Format Reference

Language: English | [Español](ffmpeg-recipes.es.md)

This is a companion reference for [ffmpeg-video-filesize](../README.md). These are general `ffmpeg` capabilities beyond the size-targeted workflow.

## Native FFmpeg Conversions

This helper script automates one size-targeted video workflow, but `ffmpeg` itself can do much more without any extra wrapper.

With plain `ffmpeg`, you can also:

- convert between video containers and codecs
- extract audio from a video
- export MP3, M4A, WAV, FLAC, OGG, or Opus files
- create animated GIFs
- export still images such as PNG, JPG, or WebP

## Common FFmpeg Formats

Some common formats you can usually convert between with `ffmpeg` are:

- Video containers: `mp4`, `mov`, `mkv`, `avi`, `m4v`, `webm`, `gif`
- Audio formats: `mp3`, `aac`, `m4a`, `wav`, `flac`, `ogg`, `opus`
- Image / animation outputs: `gif`, `png`, `jpg`, `webp`

The exact list depends on how your local `ffmpeg` build was compiled. For the live list supported by your current installation, run:

```bash
ffmpeg -formats
ffmpeg -codecs
ffmpeg -muxers
ffmpeg -demuxers
```

## Direct FFmpeg Recipes

Convert one video container to another:

```bash
ffmpeg -i input.mov output.mp4
ffmpeg -i input.mp4 output.mov
```

Extract audio from a video:

```bash
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
ffmpeg -i input.mp4 -vn -c:a aac -b:a 192k output.m4a
ffmpeg -i input.mp4 -vn -c:a pcm_s16le output.wav
```

Create a GIF directly with `ffmpeg`:

```bash
ffmpeg -ss 00:00:10 -t 3 -i input.mp4 \
  -vf "fps=10,scale=360:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## Email-Safe GIF Example

If someone wants to attach a short animated GIF to an email, `ffmpeg` can do that directly too.

The GIF below was generated locally from `Rick Astley - Never Gonna Give You Up [HQ] [DLzxrzFCyOs].mp4` and kept under `1mb`.

Command used:

```bash
ffmpeg -hide_banner -y \
  -ss 00:00:42.5 -t 3.2 \
  -i "Rick Astley - Never Gonna Give You Up [HQ] [DLzxrzFCyOs].mp4" \
  -vf "fps=10,scale=360:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=96[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
  -loop 0 rick-astley-email-safe.gif
```

Included preview:

![Rick Astley email-safe GIF preview](../assets/rick-astley-email-safe.gif)

Direct MP4 clip:

[assets/rick-astley-preview.mp4](../assets/rick-astley-preview.mp4)

This example GIF is about `756 KB`, which makes it a practical email-friendly animated attachment example.

If you need an even smaller GIF, reduce one or more of these:

- clip duration
- output width
- FPS
- palette size
