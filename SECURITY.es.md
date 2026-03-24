# Política de Seguridad

Idioma: [English](SECURITY.md) | Español

## Alcance

`ffmpeg-video-filesize` es un script Bash local. No:

- Accede a la red
- Recopila ni transmite datos
- Corre un servidor ni escucha en ningún puerto
- Almacena credenciales ni secretos

El script lee un archivo de video local, ejecuta `ffmpeg` y `ffprobe` localmente, y escribe un archivo de salida en disco. Todas las operaciones son locales en tu máquina.

## Reportar una Vulnerabilidad

Si encontrás un problema de seguridad (por ejemplo, manejo inseguro de archivos, inyección de comandos o comportamiento inesperado con nombres de archivo manipulados), reportalo a través del **reporte privado de vulnerabilidades** de GitHub:

1. Andá a la [pestaña Security](https://github.com/andreswatson/ffmpeg-video-filesize/security) de este repositorio
2. Hacé clic en **Report a vulnerability**
3. Describí el problema, los pasos para reproducirlo y el impacto potencial

Vas a recibir una respuesta en un plazo razonable. Por favor, no abras un issue público para vulnerabilidades de seguridad.

## Versiones Soportadas

| Versión | Soportada |
|---------|-----------|
| 1.0.x | Sí |
