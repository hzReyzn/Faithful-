# Verificación de Faithful — 24 de octubre de 2026

## Actualización: ventana compacta y arte automático

- Revisión posterior: se retiraron los sigilos nativos sobre el logo y el botón de reapertura, y se impidió que el texto FAITHFUL de cabecera duplique el título integrado en el PNG aunque `IsLoaded` siga en `false`.
- La ventana ahora mide **940 × 528** en su tamaño base. Se redujeron también la cabecera, la barra lateral y el logo, conservando la lógica de ajuste a pantallas pequeñas.
- El PNG de fondo se presenta con `ImageTransparency = 0.38` para recuperar visibilidad; logo y fondo no se modificaron.
- Con IDs de imagen válidos se mantiene la ruta nativa de Roblox. Sin IDs, ejecutores compatibles pueden descargar **solo** los tres PNG del commit fijo `dff138c05914f15c3c84bca1caef13a11969814b`, validarlos y registrarlos con `getcustomasset`/`getsynasset`. Studio sigue requiriendo los IDs publicados en Roblox.
- `npm test` completó **65 aserciones** en el entorno simulado, incluida la carga y reutilización de PNG, aplicación de fondo, logo, botón de reapertura, niebla y ausencia de sigilos superpuestos; compiló los módulos y comprobó que el bundle `Faithful Exploit` coincide con su fuente.
- Todavía **no** se ha probado visualmente en Roblox ni en un ejecutor real. El apartado histórico siguiente corresponde a la entrega inicial (53 aserciones, sin descarga opcional de imágenes); su hash no describe esta actualización.

## Ejecutado realmente

- Se leyeron las tres imágenes adjuntas y el código completo disponible de Reyzn X. Se revisaron en detalle sus capas de fuego, reutilización de objetos y ciclo de actualización.
- Se examinó el destino `hzReyzn/Faithful-`, rama `main`, commit base `c4a030b3777e3d6bcf940fea1bc115ddd33fa5dc`. El archivo `Faithful Exploit` estaba vacío salvo un salto de línea.
- Se compilaron los cinco archivos de producción, el script autocontenido y el test nativo opcional mediante el compilador Luau incluido en `luau-web` 1.5.1 (WASM).
- Se ejecutaron **53 aserciones de lógica** en Luau con dobles de servicios, señales, objetos, reloj y TweenService. El registro está en `tests/validation-output.txt`.
- Las pruebas cubren la última categoría solicitada, 30 reaperturas interrumpidas, estado del reloj, ocultación, presupuestos de VFX, reducción de movimiento local y del sistema, confirmaciones, arrastre de ratón y táctil, logo independiente, reapertura sin clic accidental después de arrastrar, notificaciones reutilizadas, componentes, límite UTF-8, reinicialización y cancelación de precarga pendiente.
- En ese entorno simulado, el número de descendientes de la GUI no creció en los ciclos probados y la destrucción dejó cero conexiones, tweens y tareas pendientes.
- Se comprobó la geometría calculada de los contenedores a 360×640, 844×390, 1280×800 y 1920×1080. Esta prueba no rasteriza texto, iconos ni imágenes.
- Se verificó que `Faithful Exploit` coincide exactamente con la concatenación generada de los módulos y del inicializador.
- Se revisó estáticamente que el script autocontenido no contiene módulos externos, llamadas de descarga o ejecución de código remoto, acceso a personajes ni conexiones a `PreRender`.
- Se compararon los bytes de las tres imágenes originales con sus copias del paquete: permanecen intactos. El nuevo sprite tiene canal alfa real con valores desde 0 hasta 254.
- El empaquetador verifica la estructura XML de `Faithful.rbxmx`, los nombres/tipos de sus cinco scripts y que sus fuentes sobreviven al ciclo de escritura/lectura sin cambios. También revisa CRC y SHA-256 de los archivos del ZIP.
- Se dejó intacto el README original y no se modificó el repositorio de referencia. La publicación de esta versión fue aprobada expresamente por el usuario después de completar las comprobaciones locales.

## Pendiente en Roblox Studio y dispositivos reales

- Importar el modelo `.rbxmx` en Studio y confirmar que los ModuleScripts y el LocalScript se insertan y ejecutan como se espera.
- Subir las imágenes, configurar IDs reales y verificar permisos, moderación, precarga y renderizado del alfa.
- Revisar el aspecto real de la niebla, mezcla de colores, nitidez del fondo, lectura del título, bordes, recortes, tipografía y orden visual entre controles y efectos.
- Probar el comportamiento real de las señales `Activated`, foco, ratón, multitáctil, teclado virtual, desplazamiento y áreas seguras; el doble de pruebas no reproduce todos los detalles de entrada de Roblox.
- Ejecutar `tests/StudioSmoke.client.luau` dentro de Studio. Solo se compiló aquí; no se afirma que ya haya pasado en el motor.
- Medir FPS, tiempo de CPU/GPU, memoria y coste de las texturas en cliente real, incluidos móviles. No se promete un FPS ni un consumo de memoria basándose únicamente en pools y límites de frecuencia.
- Validar el aspecto con distintas calidades gráficas y las preferencias de accesibilidad reales.

No hubo acceso a una sesión de Roblox Studio ejecutable durante esta entrega. Las pruebas locales permiten detectar errores de sintaxis y estado; no sustituyen la revisión visual ni el perfilado del motor.

## Integridad de la versión preparada

SHA-256 de `Faithful Exploit` y `Faithful-Standalone.client.luau`:

`86757f1eeb5d83df3467f6c5407600287b1a1be36ffabee0fd903de4bfc5fcf5`

El usuario aprobó la publicación del paquete preparado. Antes de publicar se volvió a comprobar el archivo remoto: conservaba el blob base `8b137891791fe96927ad78e64b0aad7bded08bdc` y el commit base indicado arriba. Para actualizaciones futuras, comprueba nuevamente el estado remoto antes de escribir.
