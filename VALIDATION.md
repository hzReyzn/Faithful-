# Verificación de Faithful — 24 de octubre de 2026

Revisión: `obsidian-reflection-compact-20261024`. Versión pública 1.0.0.

## Cambios solicitados

- Se eliminaron la niebla, sus 32 ImageLabels, sus contenedores y el código de animación/carga del sprite. El PNG original se conserva como archivo histórico del repositorio, sin descargarse ni usarse durante la inicialización.
- Se añadió **Obsidian Reflection**, un barrido diagonal plateado con matiz carmesí dentro de la superficie. Dos capas reutilizadas con UIGradient, opacidades máximas de 12% y 3.5%, duración de 2.4 segundos y pausa de 6.5 segundos. Los textos y controles se dibujan por encima.
- La ventana base pasa de **860 × 480 a 780 × 440**. Cabecera, texto gráfico, navegación y título se ajustaron; los botones táctiles conservan 44 px de alto. Se mantiene la adaptación a resoluciones pequeñas.
- Los botones usan una superficie de carbón con degradado vertical más uniforme, borde neutro fino, contorno carmesí de selección y lavado carmesí lateral. El reflejo del botón es más tenue y la presión reduce su cara a 0.985, conservando el área interactiva.
- Continúan las cinco categorías limpias, Ultra fijo, el texto unido a Header, el título del fondo visible, el contador y el botón minimizado arrastrable. Las partículas pequeñas se redujeron de 18 a 8. No se modificó ninguna mecánica del juego.

## Ejecutado realmente

1. Se examinó la captura `1000192174.jpg` y la fuente vigente. La base es `e207046ebc4c6a8cafffd1e39fce9f3047b6f57b`; el blob anterior de `Faithful Exploit` es `c45739d9a798f3d1e721631a53814d1a266a0d58`. No se modificó el repositorio de referencia Reyzn X.
2. `npm test` compiló cinco archivos de producción, el script autocontenido y el test nativo opcional con Luau/WASM (`luau-web` 1.5.1). Pasaron **100 aserciones** de lógica; el registro está en `tests/validation-output.txt`.
3. Se comprobó que ya no existen nodos/capas de niebla ni una solicitud AssetSmoke. La prueba de carga opcional solo suministra fondo, logo y texto, y rechazaría una solicitud inesperada del sprite retirado.
4. Se comprobaron los límites geométricos del reflejo, su ZIndex por debajo de los textos, desplazamiento, alternancia entre barrido y pausa y límites de opacidad. Se muestrearon 12 segundos de estado animado. Estas pruebas no rasterizan el efecto ni certifican su aspecto visual.
5. Se comprobaron el nuevo contorno de selección, la presión del botón, el reflejo único de interacción y el mínimo táctil de 44 px. El movimiento reducido detuvo todos los reflejos y la compresión.
6. Se mantuvieron las pruebas de texto unido a la ventana —ratón, toque, movimiento por código, redimensionamiento, foco y reapertura—, fondo sin máscara, Ultra fijo y páginas sin ajustes añadidos.
7. Cambios rápidos de categoría, 30 aperturas/cierres interrumpidos, reloj, confirmaciones, notificaciones, singleton, componentes opcionales, texto UTF-8 y precarga siguieron pasando. Los ciclos de efectos no incrementaron los descendientes de la GUI; destruir dejó cero conexiones, tweens y tareas pendientes en el entorno simulado.
8. Se comprobó la geometría a 360×640, 844×390, 1280×800 y 1920×1080. El doble de APIs no reproduce todas las reglas de layout, renderizado y entrada del motor real.
9. El generador verificó que `Faithful Exploit` coincide con las fuentes. El empaquetador comprobó el XML y las fuentes de los cinco scripts del modelo, junto con CRC/SHA-256 del ZIP. `git diff --check` pasó.
10. Se conservaron los bytes de todos los archivos en assets y el README original. Los recursos activos conservan las mismas URLs fijas y validaciones de caché; solo se eliminó del código la ruta de humo.

## Pendiente en Roblox y dispositivos reales

- Ejecutar en Studio con los tres IDs de imagen válidos y comprobar permisos, moderación, precarga y renderizado.
- Revisar que el reflejo se perciba suave, quede dentro del panel y conserve la lectura del arte, texto y botones en distintos fondos del juego.
- Probar tacto, orientación, áreas seguras, foco, Activated y arrastre en dispositivos reales.
- Ejecutar `tests/StudioSmoke.client.luau` en Studio; aquí se compiló pero no se ejecutó en el motor.
- Verificar la carga opcional de imágenes en el entorno usado por el autor; aquí se simula el registro de assets.
- Medir FPS, tiempo CPU/GPU y memoria. Se retiraron las capas de humo y se redujeron objetos animados, pero esto no equivale a un perfilado ni demuestra una cifra de FPS.

No hubo acceso a una sesión ejecutable de Roblox Studio. No se presenta esta revisión como validada visualmente ni perfilada en el motor.

## Integridad y publicación

SHA-256 de `Faithful Exploit` y de su copia `Faithful-Standalone.client.luau`:

`1116581298272f0bfef59b9677874771ab2acca8bad6586aa7f0f5091f118d04`

El usuario mantiene su autorización para realizar y publicar los cambios solicitados. Se vuelve a verificar la rama remota y se publica sin forzarla.
