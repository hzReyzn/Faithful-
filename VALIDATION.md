# Verificación de Faithful — 24 de octubre de 2026

Revisión: `attached-wordmark-ultra-mist-20261024`. Versión pública 1.0.0.

## Correcciones solicitadas

- **Texto unido a la ventana:** el ImageButton `HeaderWordmark` es hijo de Header. Se eliminó la separación independiente y el seguimiento manual de coordenadas. Arrastrar el texto mueve la ventana completa. El logo del botón minimizado mantiene su arrastre propio.
- **Fondo restaurado:** se eliminó el gradiente que ocultaba el título FAITHFUL. La transparencia base sigue en 0.38 y los PNG permanecen intactos.
- **Páginas limpias y Ultra fijo:** se retiraron los ajustes añadidos a Visuals y Settings, el botón de calidad de cabecera y los perfiles Minimal/Balanced. El método de compatibilidad SetQuality mantiene Ultra ante solicitudes antiguas de otros perfiles. No se ofrece al jugador un selector de calidad. Se conserva el respeto por el movimiento reducido del sistema.
- **Niebla reforzada:** 32 capas reutilizadas en vez de 18: 24 exteriores y 8 interiores. Se aumentaron el tamaño de los volúmenes laterales, el color carmesí y la intensidad predeterminada a 0.90. Las fases de opacidad se solapan durante más tiempo, con deriva y expansión de tres velocidades. Se conserva un único bucle ambiental, limitado a 30 Hz, y 18 partículas.

## Ejecutado realmente

1. Se examinó la captura `1000192173.jpg`, el sprite de niebla existente y la fuente del repositorio. La base es `54b9fe1b0840ec542c8422277e7aecd2cad0b6e1`; el blob anterior de `Faithful Exploit` es `d9ec0b3f9f02dce56ed877f4a0637fb6b996ed9f`. Esta corrección continúa la implementación inspirada en los VFX revisados de Reyzn X; no modifica ese repositorio.
2. `npm test` compiló cinco archivos de producción, el script autocontenido y el test nativo opcional con el compilador Luau/WASM de `luau-web` 1.5.1. Se ejecutaron **100 aserciones** de lógica; el registro está en `tests/validation-output.txt`.
3. Se comprobó que el texto sigue a la ventana con ratón, toque, movimiento directo por código, redimensionamiento, pérdida de foco y reapertura. Se verificaron su parentesco nativo y el desplazamiento relativo de 16 × 6 px.
4. Se comprobó que las cinco páginas no contienen controles de apariencia, no existe el botón de calidad y el fondo no contiene UIGradient. Las solicitudes heredadas de Balanced/Minimal conservan Ultra y su presupuesto completo.
5. Se muestrearon 20 segundos de ciclos de niebla simulados para comprobar que las fases exteriores se solapan sin vaciarse. También se comprobaron el aumento de tamaño lateral, el desplazamiento, la separación de capas y los límites de opacidad interior/exterior. **Es una prueba de estados y geometría, no una medida de densidad visual renderizada.**
6. Se mantuvieron las pruebas de cambio rápido de páginas, 30 aperturas/cierres interrumpidos, reloj, captura de entrada, confirmaciones, notificaciones reutilizadas, singleton, controles genéricos opcionales, límite UTF-8, precarga y asignación asíncrona de imágenes.
7. En ese entorno simulado, el número de descendientes no creció durante los ciclos probados. Destruir dejó cero conexiones, tweens y tareas pendientes. Ocultar o desactivar el ScreenGui desconectó el ambiente y pausó el reloj. No hay conexiones a PreRender.
8. Se comprobó la geometría calculada a 360×640, 844×390, 1280×800 y 1920×1080. El doble de APIs no reproduce el renderizador, todos los detalles de layout o las entradas reales de un teléfono.
9. Se comprobó la igualdad entre las fuentes y `Faithful Exploit`. El empaquetador verifica los cinco scripts de `Faithful.rbxmx` mediante lectura del XML y comprueba CRC/SHA-256 del ZIP. `git diff --check` pasó.
10. Se conservaron los PNG, README, inicializador y mecanismo de carga de imágenes. En FaithfulAssets solo se retiró la opción obsoleta de título incrustado; no se alteraron las URLs, cachés ni validaciones del cargador.

## Pendiente en Roblox y dispositivos reales

- Ejecutar en Studio con los cuatro IDs válidos y comprobar permisos, moderación, precarga y mezcla de transparencias.
- Revisar el aspecto final y la densidad perceptible de la nueva niebla sobre distintos escenarios, así como la legibilidad de los dos textos FAITHFUL y el anclaje visual de la cabecera.
- Probar entrada táctil real, cambios de orientación, áreas seguras, foco, Activated y arrastre de ventana y botón minimizado.
- Ejecutar `tests/StudioSmoke.client.luau` dentro de Studio; aquí se compiló pero no se ejecutó en el motor.
- Probar la ruta opcional de imágenes en el entorno usado por el autor; las pruebas locales simulan el registro de assets.
- Medir FPS, coste CPU/GPU, memoria y overdraw en móvil y escritorio. Aumentar el número y tamaño de capas aumenta el trabajo de dibujo, aunque los objetos se reutilicen. El límite de 30 Hz no demuestra un FPS concreto.

No hubo acceso a una sesión ejecutable de Roblox Studio. No se presenta esta revisión como ya validada visualmente o perfilada en el motor.

## Integridad y publicación

SHA-256 de `Faithful Exploit` y de su copia `Faithful-Standalone.client.luau`:

`b30188c6cba738c8171e669570ea80b697e2ba6cd088362f813f5ca42f4fe3fe`

El usuario mantiene su autorización para realizar y publicar los cambios solicitados. Se vuelve a verificar la revisión remota y se actualiza la rama sin forzarla.
