# FAITHFUL — Gothic UI & Ultra VFX

Interfaz nativa de Roblox en Luau. Solo presenta controles y efectos de la propia interfaz; no altera personajes, jugadores ni mecánicas. Versión 1.0.0, revisión `obsidian-reflection-compact-20261024`.

## Resultado y decisiones visuales

- La tercera imagen guía la distribución: cabecera, navegación izquierda, contenido derecho y bordes finos. Se eliminó el adorno de arco y sigilo de la esquina inferior izquierda por petición del autor.
- La primera imagen se usa como arte de fondo, sin modificar sus píxeles. La segunda se conserva como logo del botón para reabrir la ventana. El nuevo texto gótico `FAITHFUL` ocupa el espacio del logo en la cabecera.
- Solo aparecen **Home, Main, Visuals, Scripts y Settings**. Todas las páginas mantienen su título y espacio limpio; se retiraron los ajustes de apariencia y el selector de calidad; no hay Movement, Player, Protection, Utilities ni funciones de juego.
- No hay un texto FAITHFUL nativo superpuesto: el encabezado usa exclusivamente `assets/FaithfulWordmark.png` (154 × 40 como tamaño de GUI, 108 × 36 en pantallas estrechas).
- La ventana predeterminada pasa a **780 × 440**, frente a los 860 × 480 anteriores, manteniendo adaptación a pantallas pequeñas.
- El fondo mantiene **0.38** de `ImageTransparency` (62% opacidad base), sin gradiente ni máscara sobre su título FAITHFUL. Se conserva el título del arte además del texto gráfico de cabecera, como pidió el autor. Los bytes del PNG permanecen intactos.
- Se reemplaza ONLINE por `HH:MM:SS`. El contador suma el tiempo que la ventana está abierta. Se pausa al minimizar/cerrar o desactivar el ScreenGui, y continúa al volver a mostrarlo. Una sesión nueva comienza en cero.
- Se arrastra la ventana desde la cabecera, el propio texto gráfico FAITHFUL o el área del título de la página con ratón o un dedo. Puede quedar parcialmente fuera de los laterales, manteniendo visible un área de arrastre recuperable. El texto de cabecera es hijo de Header y permanece unido a la ventana en cualquier movimiento, cambio de resolución o reapertura; arrastrarlo mueve la ventana completa. El pequeño botón de reapertura mantiene el logo cuadrado original y también es arrastrable.
- El marco tiene doble borde metálico, biseles de esquina, halo carmesí localizado y sombra suave. Los botones tienen un degradado vertical de carbón, borde neutro fino, selección carmesí localizada y un único reflejo de interacción compartido. Conservan áreas táctiles de 44 px aunque la ventana sea más pequeña.
- Cerrar solicita confirmación y oculta la interfaz. El logo de reapertura permite volver. Destruir el `ScreenGui` retira por completo sus recursos.

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `src/FaithfulTheme.luau` | Paleta, medidas, transparencias, tiempos y calidad predeterminada |
| `src/FaithfulAssets.luau` | Tres IDs configurables y cargador PNG local opcional para ejecutores compatibles |
| `src/FaithfulUI.luau` | Construcción nativa, componentes, entrada, reloj y estado local |
| `src/FaithfulVFX.luau` | Reflejo de superficie, partículas, borde, botones, transiciones y limpieza de animaciones |
| `src/FaithfulMain.client.luau` | Inicialización, instancia única y precarga no bloqueante |
| `Faithful Exploit` | Versión autocontenida generada de las mismas fuentes; destino solicitado en GitHub |
| `Faithful-Standalone.client.luau` | Copia descargable de esa versión, dentro del paquete de entrega |
| `Faithful.rbxmx` | Carpeta nativa importable con los cuatro ModuleScripts y el LocalScript |
| `assets/` | Fondo, logo del botón minimizado, texto de cabecera y referencias originales conservadas |
| `tests/StudioSmoke.client.luau` | Prueba opcional para ejecutar dentro de Studio |
| `tools/build.py` | Regenera el archivo autocontenido sin ejecutar código dinámico |

Las versiones modular y autocontenida usan la misma implementación. Se instala **una de las dos**.

## 1. Configurar las imágenes

No se han publicado imágenes en tu cuenta de Roblox ni se han inventado IDs. **En Roblox Studio**, antes de evaluar el acabado visual:

1. Abre tu experiencia en Roblox Studio y su Asset Manager.
2. Importa `assets/FaithfulBackground.png`, `assets/FaithfulLogo.png`, `assets/FaithfulWordmark.png` como imágenes bajo el propietario o grupo de la experiencia. Conserva el canal alfa del logo y del texto.
3. Obtén los IDs de imagen correspondientes y verifica sus permisos para la experiencia.
4. En `FaithfulAssets`, sustituye los tres marcadores:

```luau
local Assets = {
    Background = "BACKGROUND_ASSET_ID",
    Logo = "LOGO_ASSET_ID",
    Wordmark = "WORDMARK_ASSET_ID",
}
```

Acepta el ID numérico escrito como cadena o `rbxassetid://` seguido de ese ID real. No admite enlaces a GitHub ni URLs de páginas de decals. No reemplaces el módulo entero por el bloque anterior: conserva su función `Resolve` y `return Assets`.

`LayoutReference.png` no se carga en el juego: sus opciones están incrustadas en la imagen. El antiguo sprite `CrimsonMist.png` permanece en assets como archivo histórico, pero no se carga ni se usa. El nuevo reflejo se construye con Frame y UIGradient y no necesita imágenes adicionales. El PNG `FaithfulWordmark.png` procede del nuevo texto aprobado por el autor y se redujo a 1024 × 341 para su uso en la cabecera.

**Alternativa para el `loadstring` en un ejecutor compatible:** si los IDs siguen sin configurar, `FaithfulAssets.LoadFromRepository()` descarga los PNG desde revisiones fijas de este repositorio (`dff138c...` para el fondo y el logo original y `d7b3d9...` para el texto nuevo), comprueba firma/tamaño y los registra mediante `getcustomasset` o `getsynasset` y `writefile`. Se reutiliza una caché local validada cuando existen `isfile` y `readfile`. No se ejecutan scripts Lua externos. En ejecutores sin esas APIs, las imágenes necesitan IDs reales como en Studio.

Sin imágenes disponibles la interfaz sigue funcionando, con fondo oscuro pero sin los recursos personalizados. El estado de los recursos se expone en `AssetBackground`, `AssetLogo` y `AssetWordmark` del `ScreenGui` (`Ready`, `Assigned`, `NeedsRobloxId` o un error de carga).

## 2. Instalación rápida: un LocalScript

1. En Explorer, abre `StarterPlayer > StarterPlayerScripts`.
2. Crea un **LocalScript** llamado `Faithful`.
3. Copia dentro todo `Faithful-Standalone.client.luau`, o todo el archivo `Faithful Exploit` del paquete.
4. En Studio, configura los IDs en el bloque `FaithfulAssets` de ese mismo script. En un ejecutor compatible el cargador de imágenes podrá funcionar sin ese paso.
5. Inicia **Play**, no una ejecución aislada del servidor. El script necesita `Players.LocalPlayer` y crea su `ScreenGui` en `PlayerGui`.

La versión de Studio no requiere HTTP, `loadstring`, APIs de ejecutores ni cambios de servidor. El cargador opcional de imágenes solo se activa en entornos que ofrecen funciones de recursos locales y permite que el `loadstring` use los PNG de GitHub.

## 3. Instalación modular

Puedes usar **Insert from File** sobre `StarterPlayerScripts` e importar `Faithful.rbxmx`. Comprueba en Explorer que `Faithful` sea una carpeta dentro de `StarterPlayerScripts`, con estos hijos:

| Nombre en Explorer | Tipo | Fuente |
| --- | --- | --- |
| `FaithfulTheme` | ModuleScript | `src/FaithfulTheme.luau` |
| `FaithfulAssets` | ModuleScript | `src/FaithfulAssets.luau` |
| `FaithfulUI` | ModuleScript | `src/FaithfulUI.luau` |
| `FaithfulVFX` | ModuleScript | `src/FaithfulVFX.luau` |
| `FaithfulMain` | LocalScript | `src/FaithfulMain.client.luau` |

También puedes crear la carpeta y los cinco scripts manualmente y pegar sus fuentes. Los nombres de los ModuleScripts deben coincidir exactamente, sin la extensión `.luau`. Configura los IDs en `FaithfulAssets` e inicia Play.

## 4. Ultra fijo y componentes reutilizables

La presentación predeterminada contiene únicamente **Home, Main, Visuals, Scripts y Settings**, con páginas limpias. Se quitaron el botón ULTRA de la cabecera y todos los controles de apariencia añadidos en la revisión anterior.

La calidad está fijada en **Ultra**. No hay selector para el jugador ni presets Minimal/Balanced disponibles. El método de compatibilidad `FaithfulVFX:SetQuality(...)` conserva Ultra aunque una integración antigua solicite otro nivel. La preferencia de movimiento reducido de Roblox se sigue respetando; afecta a las animaciones, sin cambiar el preset.

Configuración de desarrollo, dentro de `FaithfulTheme`:

```luau
Quality = "Ultra",              -- Perfil fijo
Reflection = { Duration = 2.4, Interval = 6.5, Opacity = 0.12, TintOpacity = 0.035 },
ReduceMotion = false,
RespectSystemReduceMotion = true,
Effects = { Reflection = true, Embers = true, Border = true },
ShowcaseControls = false,       -- Sin controles de demostración en la entrega
```

Ultra reutiliza **un reflejo de superficie con dos capas y 8 partículas pequeñas**, además de bordes y reflejos de botones. Las 32 capas de humo anteriores se eliminaron. Un único Heartbeat actualiza el ambiente hasta 30 veces por segundo. Al ocultar o desactivar el ScreenGui se desconecta, y el contador se pausa. No hay creación de partículas por ciclo.

Con movimiento reducido se detienen las partículas, el recorrido del borde, los reflejos de superficie y botones, y el pulso continuo. Las transiciones se limitan a un fundido breve y los botones conservan su selección sin compresión.

La biblioteca conserva `Button`, `Toggle`, `Slider`, `Dropdown`, `TextField`, `Separator`, `Tooltip`, `Notify` y `Confirm` para ampliar la interfaz posteriormente. Toggle, Slider y Dropdown devuelven `Set(value, silent)`; TextField expone su `Box` nativo. Los callbacks son explícitos. No se evalúa el texto introducido ni se ejecutan scripts desde la pestaña Scripts.

Solo para probar esos componentes, el desarrollador puede activar `ShowcaseControls` en la fuente; añade una demostración genérica en Main y no añade un selector de calidad. La entrega mantiene esa opción desactivada.

## 5. Cómo están hechos los VFX

**Obsidian Reflection:** sustituye completamente la niebla. Una banda diagonal plateada con un matiz carmesí atraviesa suavemente la superficie durante 2.4 segundos, seguida de una pausa de 6.5 segundos. El contenedor está recortado dentro del panel y sus dos capas quedan por debajo de los textos y controles. La opacidad máxima de las capas es 12% plateada y 3.5% carmesí, antes de aplicar sus gradientes. No cubre toda la ventana de brillo simultáneamente.

Los Frame y UIGradient se crean una vez; se animan Offset y transparencia en el mismo Heartbeat ambiental. Al ocultar la UI, desactivar ScreenGui o activar movimiento reducido, el reflejo se detiene y desaparece. No usa un sprite, descarga adicional, CanvasGroup ni un nuevo bucle de renderizado.

**Crimson Border Flow:** un tramo estrecho viaja alrededor del perímetro. En las esquinas puede repartirse entre dos lados contiguos; nunca ilumina todo el borde a la vez.

**Ghoul Embers:** ocho puntos como máximo, pequeños y semitransparentes, cerca de los laterales. No se crean instancias en cada ciclo.

**Obsidian Transitions:** la última categoría solicitada gana. Se cancelan las animaciones anteriores y se normalizan posición y opacidad para impedir páginas superpuestas o fundidos acumulativos.

**Crimson Pulse y reflejos:** la categoría seleccionada mantiene un lavado carmesí tenue y un gradiente metálico móvil. La presión comprime únicamente la cara del botón a 0.985; no cambia su área de entrada. Un solo reflejo diagonal recorre un botón a la vez, por interacción o aproximadamente cada 6.5 segundos. Con movimiento reducido desaparecen los reflejos, el pulso y la compresión; la selección sigue siendo legible.

**Faithful Entrance:** fundido breve de ventana/fondo, aparición ligeramente retrasada del logo y comienzo del borde y del reflejo de superficie. La reapertura completa no impone una introducción larga.

La opacidad parte de valores base inmutables y factores por grupo. No se usan `CanvasGroup` de pantalla completa. No hay conexiones a `PreRender`, modificaciones de `Lighting` ni efectos 3D sobre el mundo. El único bucle ambiental se desconecta al ocultar o desactivar el ScreenGui. La reducción de movimiento deja la selección estática y detiene el bucle ambiental. Al destruir se cancelan tweens, temporizadores y precarga pendiente, y se desconectan los eventos.

## 6. Pruebas en Roblox Studio

1. **Primera apertura:** revisa Output, carga de las tres imágenes, nitidez, título del fondo visible, texto de cabecera unido a la ventana y reloj en lugar de ONLINE.
2. **Interacciones:** cambia rápidamente entre las cinco categorías; minimiza y reabre varias veces; confirma y cancela el cierre. El estado y el contador deben continuar correctamente.
3. **Arrastre:** mueve la cabecera, el título de página y el propio texto gráfico: los tres deben arrastrar la ventana y mantener el texto en la cabecera. Repite con entrada táctil. Arrastra el botón de reapertura: soltarlo tras moverlo no debe abrir accidentalmente la ventana.
4. **Resoluciones:** prueba teléfono vertical y horizontal, tableta y escritorio con Device Simulator. Verifica áreas seguras, botones de al menos 44 px y navegación desplazable en pantallas bajas.
5. **Texto y componentes:** activa temporalmente `ShowcaseControls`; verifica límites del slider, dropdown expandible, texto UTF-8, notificaciones y confirmaciones. Restáuralo a `false` para la presentación limpia.
6. **Perfil fijo y accesibilidad:** comprueba que no aparecen ajustes de calidad o apariencia y que el atributo `VFXQuality` permanece en Ultra. Prueba la preferencia de movimiento reducido de Roblox; el movimiento ambiental debe desaparecer al activarla.
7. **Rendimiento:** en un teléfono real y en un cliente de escritorio, mide el coste de Ultra con Developer Console/MicroProfiler, comparando la ventana abierta y oculta. Revisa coste de UI, memoria de texturas y comportamiento tras varias reaperturas. Un límite de 30 Hz no sustituye esta medición.
8. **Limpieza:** elimina `PlayerGui.Faithful` durante Play o reinicia la inicialización. Debe quedar una sola instancia propia y no deben producirse errores de callbacks sobre la anterior.

Para la prueba automatizada nativa opcional, desactiva `FaithfulMain`, coloca `tests/StudioSmoke.client.luau` como otro LocalScript en la carpeta Faithful y ejecuta Play. Comprueba los mensajes `[Faithful native check]`. El test destruye su interfaz al terminar. Vuelve a activar `FaithfulMain` y retira el test para el uso normal.

## 7. Reproducir las comprobaciones locales

Requiere Python 3 y Node.js con npm, solo para desarrollo:

```bash
python3 tools/build.py
npm ci
npm test
python3 tools/package.py
```

`npm test` compila con Luau/WASM y ejecuta pruebas de lógica contra un doble de las APIs de Roblox. **No inicia Studio, no dibuja la UI y no mide FPS.** La dependencia de JavaScript se limita a estas herramientas locales; el producto en Roblox es íntegramente Luau.

Consulta `VALIDATION.md` para separar resultados ejecutados de pruebas pendientes. Si editas las fuentes modulares, vuelve a generar el archivo autocontenido y los paquetes; no mantengas dos implementaciones a mano.

## 8. Referencias consultadas

- Código de referencia: [hzReyzn/Experimental — REYZN X UI EXPERIMENTAL](https://github.com/hzReyzn/Experimental/blob/main/REYZN%20X%20UI%20EXPERIMENTAL), blob `64c05792b807afe1fbc12f4234428923684a777c`. Se revisaron especialmente `UpdraftFire`, `NeonFlow`, el sistema de reflejo único y la presión de botones. La revisión actual conserva la inspiración de sus superficies metálicas y reflejos, y sustituye por completo la niebla por un reflejo nativo contenido en el panel. No se trasladaron funciones de juego ni lanzadores externos.
- Destino solicitado: [hzReyzn/Faithful- — Faithful Exploit](https://github.com/hzReyzn/Faithful-/blob/main/Faithful%20Exploit). Esta revisión parte del commit `e207046ebc4c6a8cafffd1e39fce9f3047b6f57b`, cuyo archivo tenía el blob `c45739d9a798f3d1e721631a53814d1a266a0d58`. Conserva el texto unido a la ventana, el título del fondo y Ultra fijo; sustituye la niebla, reduce el tamaño y refina los botones.
- [Roblox: gradientes de UI](https://create.roblox.com/docs/reference/engine/classes/UIGradient).
- [Roblox: carga de ImageLabel](https://create.roblox.com/docs/reference/engine/classes/ImageLabel#IsLoaded).
- [Roblox: animación de UI](https://create.roblox.com/docs/ui/animation).
- [Roblox: áreas seguras de ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui).
- [Roblox: movimiento reducido](https://create.roblox.com/docs/reference/engine/classes/GuiService/ReducedMotionEnabled).
- [Roblox: coste de CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup).
- [Roblox: Asset Manager](https://create.roblox.com/docs/projects/assets/manager).
- [Roblox: pruebas y Device Simulator](https://create.roblox.com/docs/studio/testing-modes).

La versión se preparó y verificó antes de su publicación. El usuario aprobó expresamente publicar el script autocontenido y sus archivos de soporte en este repositorio. El README original y el repositorio de referencia se conservan intactos.
