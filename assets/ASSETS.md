# Recursos de Faithful

| Archivo | Procedencia | Uso |
| --- | --- | --- |
| FaithfulBackground.png | Primera imagen adjunta; copia de bytes intacta | Fondo de la ventana |
| FaithfulLogo.png | Segunda imagen adjunta; copia de bytes intacta | Solo botón de reapertura/minimizado |
| FaithfulWordmark.png | Nuevo texto FAITHFUL adjunto por el usuario; copia de 1024 × 341 optimizada para UI, con transparencia | Cabecera, reemplaza el logo cuadrado |
| LayoutReference.png | Tercera imagen adjunta; copia de bytes intacta | Referencia de composición, no se carga en Roblox |
| CrimsonMist.png | Sprite nuevo generado con Imagegen integrado, fondo transparente | Textura compartida de las doce capas de niebla Ultra |

Los PNG no contienen IDs de Roblox. Para Roblox Studio, impórtalos a la experiencia y configura los cuatro IDs en `FaithfulAssets.luau`.

En un ejecutor que admita `getcustomasset` (o `getsynasset`) y `writefile`, el script autocontenido intenta cargar automáticamente **solo estos cuatro PNG**, desde revisiones fijas de GitHub. Comprueba su firma PNG y tamaño antes de escribirlos en caché. Si el ejecutor no ofrece esas APIs, seguirá necesitando los IDs de Roblox. No se descarga ni ejecuta código Lua adicional.

## Prompt utilizado para el sprite

Use case: stylized-concept. Asset type: single reusable 2D VFX smoke sprite for Roblox ImageLabel, tinted in code. Generate one soft grayscale white/silver supernatural smoke wisp on true transparent background, square canvas. A wide irregular curling fog puff with delicately layered swirling translucent vapor, diffuse feathered edges fading smoothly to complete alpha zero and generous empty transparent margin on all sides. Soft horizontal mass with gentle upward curling tendrils, not flame-shaped. Mid-gray and white neutral vapor only; no baked red, black background, shadows, illumination bloom, stars, sparks, symbols, characters, text, frame or checkerboard. Keep wispy semi-transparent interior detail and low density; no solid cloud. Production alpha sprite, single puff centered, not a sprite sheet. This sprite will be expanded and tinted dark crimson by code behind UI controls.

Método: herramienta Imagegen integrada; no se utilizó una API externa ni el modo CLI. Se conservó intacto el alfa generado. Los colores carmesí y el movimiento se aplican exclusivamente en Luau.
