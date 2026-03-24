# Recetas y Referencia de Formatos FFmpeg

Idioma: [English](ffmpeg-recipes.md) | Español

Esta es una referencia complementaria de [ffmpeg-video-filesize](../README.es.md). Estas son capacidades generales de `ffmpeg` más allá del flujo orientado a tamaño.

## Conversiones Nativas con FFmpeg

Este script automatiza un flujo concreto orientado a tamaño, pero `ffmpeg` por sí mismo puede hacer mucho más sin necesidad de ningún wrapper extra.

Con `ffmpeg` puro también puedes:

- convertir entre contenedores y códecs de video
- extraer el audio de un video
- exportar archivos MP3, M4A, WAV, FLAC, OGG u Opus
- crear GIFs animados
- exportar imágenes fijas como PNG, JPG o WebP

## Formatos Comunes de FFmpeg

Algunos formatos comunes entre los que normalmente puedes convertir con `ffmpeg` son:

- Contenedores de video: `mp4`, `mov`, `mkv`, `avi`, `m4v`, `webm`, `gif`
- Formatos de audio: `mp3`, `aac`, `m4a`, `wav`, `flac`, `ogg`, `opus`
- Salidas de imagen / animación: `gif`, `png`, `jpg`, `webp`

La lista exacta depende de cómo fue compilado tu `ffmpeg` local. Para ver la lista viva soportada por tu instalación actual, ejecuta:

```bash
ffmpeg -formats
ffmpeg -codecs
ffmpeg -muxers
ffmpeg -demuxers
```

## Recetas Directas con FFmpeg

Convertir un contenedor de video a otro:

```bash
ffmpeg -i input.mov output.mp4
ffmpeg -i input.mp4 output.mov
```

Extraer el audio de un video:

```bash
ffmpeg -i input.mp4 -vn -c:a libmp3lame -q:a 2 output.mp3
ffmpeg -i input.mp4 -vn -c:a aac -b:a 192k output.m4a
ffmpeg -i input.mp4 -vn -c:a pcm_s16le output.wav
```

Crear un GIF directamente con `ffmpeg`:

```bash
ffmpeg -ss 00:00:10 -t 3 -i input.mp4 \
  -vf "fps=10,scale=360:-1:flags=lanczos,split[s0][s1];[s0]palettegen[p];[s1][p]paletteuse" \
  output.gif
```

## Ejemplo de GIF Liviano para Email

Si alguien quisiera adjuntar un GIF animado corto en un email, `ffmpeg` también puede hacerlo directamente.

El GIF de abajo se generó localmente a partir de `Rick Astley - Never Gonna Give You Up [HQ] [DLzxrzFCyOs].mp4` y se mantuvo por debajo de `1mb`.

Comando usado:

```bash
ffmpeg -hide_banner -y \
  -ss 00:00:42.5 -t 3.2 \
  -i "Rick Astley - Never Gonna Give You Up [HQ] [DLzxrzFCyOs].mp4" \
  -vf "fps=10,scale=360:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=96[p];[s1][p]paletteuse=dither=bayer:bayer_scale=5" \
  -loop 0 rick-astley-email-safe.gif
```

Vista previa incluida:

![Rick Astley GIF liviano para email](../assets/rick-astley-email-safe.gif)

Clip MP4 directo:

[assets/rick-astley-preview.mp4](../assets/rick-astley-preview.mp4)

Este GIF de ejemplo pesa aproximadamente `756 KB`, lo que lo hace un ejemplo práctico de adjunto animado amigable para email.

Si necesitas un GIF aún más pequeño, reduce una o más de estas variables:

- duración del clip
- ancho de salida
- FPS
- tamaño de la paleta
