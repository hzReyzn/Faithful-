# Verificación de Faithful — 24 de octubre de 2026

Revisión: `crimson-mist-polish-20261024`. Versión pública 1.0.0.

## Cambios de esta revisión

- Tamaño base de **860 × 480**, frente a 940 × 528. Ajuste automático al área segura y slider de tamaño adicional.
- Doble borde metálico, biseles de esquina, sombra, recorrido carmesí localizado, botones con caras metálicas y un solo reflejo compartido. Se revisaron `NeonFlow`, reflejos, presión de botones y `UpdraftFire` de Reyzn X para orientar la implementación nueva.
- **Crimson Mist**: 18 capas reutilizadas, 12 exteriores y 6 interiores, con expansión, deriva y fases de distinta velocidad. La superficie de controles recorta su contenido; el contenedor exterior permite que la atmósfera salga por los bordes. Las partículas quedan detrás de los elementos interactivos.
- Se retiró la condición que mantenía la niebla invisible hasta `IsLoaded`: ahora la URI configurada habilita las capas y la carga real sigue siendo responsabilidad de Roblox. Es una corrección de lógica; no se afirma haber reproducido un bloqueo del cargador en un cliente real.
- Visuals y Settings controlan la propia apariencia: calidad, niebla, intensidad, partículas, bordes, fondo, movimiento reducido, tamaño y restablecimiento de posición. Home, Main y Scripts permanecen limpios por defecto.
- El texto FAITHFUL de cabecera y el logo del botón minimizado se conservan como recursos distintos. Se mantiene eliminado el adorno inferior izquierdo. No se cambiaron los PNG ni el cargador opcional de imágenes.
- El título de página ofrece otra zona de arrastre. Se conserva la captura táctil del slider al redimensionar. Los límites de arrastre mantienen un área recuperable al acercar la ventana a los extremos.
- Un gradiente de alfa atenúa el título incrustado en la franja superior del fondo, sin cambiar la imagen fuente. La transparencia base del fondo sigue en **0.38**.

## Verificado realmente

1. Se revisó la captura actual adjunta y la fuente remota de Faithful. La base de esta revisión fue el commit `3da081c62a7d6110e5941bdcef94c00f1b787757`, que ya incluía la sustitución del logo por el texto de cabecera. El blob anterior de `Faithful Exploit` era `8e3984743d400afab931a411f519223a2df4b605`.
2. Se revisó el código de referencia `hzReyzn/Experimental / REYZN X UI EXPERIMENTAL`, blob `64c05792b807afe1fbc12f4234428923684a777c`. No se escribieron cambios en ese repositorio.
3. `npm test` compiló **cinco archivos de producción, el script autocontenido y el test nativo opcional** con el compilador Luau/WASM de `luau-web` 1.5.1. Es compilación, no análisis estático completo de tipos de Studio.
4. Se ejecutaron **96 aserciones** con dobles de las APIs de Roblox en Luau. El registro completo está en `tests/validation-output.txt`.
5. Se comprobó el cambio rápido de categorías, 30 ciclos interrumpidos de cierre/reapertura, pausa/reanudación del reloj, calidad y movimiento reducido local/del sistema, confirmaciones, singleton, notificaciones y cancelación de precarga pendiente.
6. Las nuevas pruebas cubren los controles reales de apariencia, capas interiores/exteriores, límites de alfa, independencia de los interruptores, texto del dropdown por encima del acabado, presión y reflejo único, limpieza al perder el foco, slider táctil de tamaño, arrastre desde el título y suspensión al desactivar `ScreenGui.Enabled`.
7. Los cambios de calidad, efectos, categorías y apertura mantuvieron estable el número de descendientes de la GUI en el entorno simulado. Destruir dejó **cero conexiones, tweens y tareas pendientes** en ese entorno. Los pools se crean una vez; Ultra usa hasta 18 capas y 18 partículas, Balanced 6 partículas y Minimal ningún bucle ambiental. No se usan conexiones a PreRender.
8. Se comprobó la geometría calculada a **360×640, 844×390, 1280×800 y 1920×1080**. La simulación no rasteriza texto, iconos o imágenes, no aplica todos los detalles del motor de layout y no modela gestos reales de dispositivos.
9. El generador comprueba que `Faithful Exploit` coincide exactamente con las fuentes modulares y el inicializador. El empaquetador verifica el XML de `Faithful.rbxmx`, sus cinco fuentes y la integridad CRC/SHA-256 de los archivos del ZIP. Esa comprobación no equivale a importarlo en Studio.
10. `git diff --check` pasó. Los archivos de `assets/`, `README.md`, `FaithfulAssets.luau` y `FaithfulMain.client.luau` coinciden con la base: se conservaron el arte, la ruta de carga de imágenes y la inicialización existente.

## Pendiente en Roblox y dispositivos reales

- Importar y ejecutar el modelo o LocalScript en Studio con IDs válidos; comprobar permisos y moderación de las cuatro imágenes.
- Evaluar el aspecto real de la niebla, el sombreado metálico, los reflejos, la máscara del título del fondo, el orden visual, los recortes y la legibilidad.
- Verificar Activated, foco, teclado virtual, desplazamiento, multitáctil, áreas seguras y arrastre en hardware real. Las señales simuladas no equivalen al sistema de entrada de Roblox.
- Ejecutar `tests/StudioSmoke.client.luau` dentro de Studio; aquí solo se compiló. El test opcional se actualizó para esta revisión.
- Probar el cargador PNG opcional en el entorno que usa el autor. Las pruebas locales usan respuestas PNG simuladas y no ejecutan APIs reales de registro local.
- Medir FPS, tiempo de CPU/GPU, memoria y coste de las texturas en clientes reales, incluidos móviles. Los pools acotados y la actualización a 30 Hz no demuestran un FPS concreto.

No hubo acceso a una sesión ejecutable de Roblox Studio. Se entregan código y comprobaciones de lógica; no una captura renderizada de esta revisión ni resultados de rendimiento del motor.

## Integridad y publicación

SHA-256 de `Faithful Exploit` y de su copia descargable `Faithful-Standalone.client.luau`:

`ba338220df2db2c418574e092edda9b80fce124015f0df176a58082d0a2f7b87`

El usuario autorizó la realización y publicación de los cambios solicitados. La actualización se prepara sobre la revisión remota examinada y se publica sin forzar la rama, comprobando de nuevo su SHA antes de escribir.
