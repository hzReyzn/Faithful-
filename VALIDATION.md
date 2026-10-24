# Verificación de Faithful — 24 de octubre de 2026

Revisión: `gothic-reference-framing-20261024`. Versión 1.0.0.

## Resultado

La composición se acerca a la referencia gótica con doble marco de esquinas recortadas, arco superior, filete central, tipografía Garamond y navegación plana. La selección utiliza un indicador vertical y un contorno carmesí; minimizar y cerrar conservan áreas táctiles de 44 px con iconos sin cajas gruesas.

El fondo se encaja completo en el contenido, debajo del título de página y fuera de la cabecera y la barra lateral. El cálculo usa sus dimensiones originales, 1672 × 941, y limita el estiramiento horizontal al 6%. Las diferencias de proporción mayores se absorben con márgenes oscuros. En horizontal, las pantallas bajas reducen también el ancho de la ventana para evitar un panel excesivamente ancho. El tamaño base sigue siendo 780 × 440.

No se modificaron los bytes ni las referencias del fondo, wordmark o logo minimizado. Siguen las cinco categorías limpias, Ultra fijo, el reflejo interno, el contador y el texto gráfico unido a la ventana. No se añadieron opciones de juego ni de calidad, ni volvió el icono inferior izquierdo.

## Comprobaciones ejecutadas

- Base: commit `7a00930ee81d3b5c95d242bcd273a855fdc1b11a`; blob anterior de `Faithful Exploit`: `c5681561f90386746a266f21a0d8ef5e4ca003b9`.
- `npm test`: compilación Luau/WASM de cinco archivos de producción, script autocontenido y prueba nativa opcional. **107 aserciones** pasaron; registro en `tests/validation-output.txt`.
- Encuadre a 360×640, 844×390, 1280×800 y 1920×1080: la imagen queda dentro de su marco, a la derecha de la barra lateral y debajo del título, con deformación entre 0% y 6%. Las composiciones horizontales mantienen el límite de proporción 780:440.
- Navegación rápida, arrastre con ratón/toque, título unido a la ventana, redimensionamiento, foco, reloj, minimizar, reabrir y confirmar cierre siguieron pasando. Treinta ciclos interrumpidos recuperan el estado correcto.
- Los ciclos de VFX reutilizan sus objetos. Ocultar la interfaz detiene efectos y reloj; destruir deja cero conexiones, tweens y tareas pendientes en el doble de APIs.
- Se conservaron las pruebas de selección, reflejo único de botón, reflejo de superficie contenido, brillo limitado, Ultra fijo y movimiento reducido.
- Se comprobó que `Faithful Exploit` coincide con las fuentes mediante `tools/build.py --check` y que `git diff --check` no reporta errores.
- `git diff --exit-code -- assets README.md src/FaithfulAssets.luau` confirmó que los recursos, sus rutas de carga y el README original siguen intactos.
- Como ayuda para revisar proporciones y contraste, se exportó la jerarquía de instancias del doble de APIs y se dibujó una aproximación SVG con los PNG originales a 1100×680, 844×390 y 360×640. Este dibujo aproxima las fuentes y el renderizado; no es una captura de Roblox.

## Límites

No se dispone de Roblox Studio ni de un cliente ejecutable en este entorno. La compilación, simulación y revisión auxiliar no verifican rasterizado, permisos de assets, entrada táctil real ni rendimiento del motor. `tests/StudioSmoke.client.luau` se compiló, pero no se ejecutó dentro de Roblox. Falta revisar allí el resultado con las imágenes cargadas y medir su coste en dispositivos reales.

## Integridad y publicación

SHA-256 de `Faithful Exploit`:

`d0c10047d231310c6e2351dd3c095fc1ee5eeab81e0e4f3edcf739cca81b28c6`

El usuario confirmó explícitamente publicar esta versión y sus archivos de soporte en `hzReyzn/Faithful-`, rama pública `main`, en el chat activo del 24 de octubre de 2026. Se verifica la rama remota antes de actualizarla y se conserva su historial sin forzar la actualización. El repositorio de referencia Reyzn X no se modifica.
