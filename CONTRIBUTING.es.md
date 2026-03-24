# Contribuir

Idioma: [English](CONTRIBUTING.md) | Español

## Reportar bugs

Abrí un issue usando la plantilla de bug report. Incluí pasos para reproducir, comportamiento esperado vs real, y tu entorno (OS, ffmpeg, bash).

## Sugerir funcionalidades

Abrí un issue primero para describir la idea y el caso de uso antes de enviar un pull request.

## Estilo de código

- Solo Bash; mantener los scripts portables en lo posible.
- Los cambios deben pasar ShellCheck sin warnings (`shellcheck ffmpeg-filesize.sh`).
- Evitar comentarios innecesarios; preferir nombres claros y buena estructura.

## Testing

Antes de abrir un PR:

- `bash -n ffmpeg-filesize.sh`
- `./ffmpeg-filesize.sh --help`
- Correr el script contra un video de prueba corto y relevante al cambio.

## Licencia

Las contribuciones se aceptan bajo los mismos términos del proyecto: la licencia MIT.
