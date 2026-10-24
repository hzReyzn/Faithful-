# FAITHFUL — Gothic UI & Ultra VFX

Interfaz nativa de Roblox en Luau. Solo presenta controles y efectos de la propia interfaz; no altera personajes, jugadores ni mecánicas. Versión 1.0.0.

## Resultado y decisiones visuales

- La tercera imagen guía la distribución: cabecera, navegación izquierda, contenido derecho, bordes finos, arcos y detalles góticos discretos. Se reconstruye con objetos nativos. No se coloca la captura como fondo porque contiene textos y opciones que se pidieron eliminar.
- La primera imagen se usa como arte de fondo, sin modificar sus píxeles. La segunda es el logo original con transparencia.
- Solo aparecen **Home, Main, Visuals, Scripts y Settings**. Las páginas contienen su título y espacio limpio; no hay Movement, Player, Protection, Utilities ni funciones de juego.
- El título de cabecera se oculta cuando carga el fondo que ya contiene FAITHFUL. En pantallas estrechas se priorizan logo, reloj y botones.
- La ventana predeterminada pasa a **940 × 528** (aproximadamente 16:9), manteniendo adaptación a pantallas pequeñas.
- El fondo usa **0.38** de `ImageTransparency` (62% opacidad) para que la ilustración resulte visible, sin modificar los píxeles del PNG.
- Se reemplaza ONLINE por `HH:MM:SS`. El contador suma el tiempo que la ventana está abierta. Se pausa al minimizar/cerrar y continúa al reabrir. Una sesión nueva comienza en cero.
- Se arrastra la ventana desde la cabecera con ratón o un dedo. Puede quedar parcialmente fuera de los laterales, manteniendo un tramo de cabecera recuperable. El logo puede arrastrarse por separado a cualquier punto visible; tras moverlo deja de seguir a la ventana. El pequeño botón de reapertura también es arrastrable.
- Cerrar solicita confirmación y oculta la interfaz. El logo de reapertura permite volver. Destruir el `ScreenGui` retira por completo sus recursos.

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `src/FaithfulTheme.luau` | Paleta, medidas, transparencias, tiempos y calidad predeterminada |
| `src/FaithfulAssets.luau` | Tres IDs configurables y cargador PNG local opcional para ejecutores compatibles |
| `src/FaithfulUI.luau` | Construcción nativa, componentes, entrada, reloj y estado local |
| `src/FaithfulVFX.luau` | Niebla, partículas, borde, pulsos, transiciones y limpieza de animaciones |
| `src/FaithfulMain.client.luau` | Inicialización, instancia única y precarga no bloqueante |
| `Faithful Exploit` | Versión autocontenida generada de las mismas fuentes; destino solicitado en GitHub |
| `Faithful-Standalone.client.luau` | Copia descargable de esa versión, dentro del paquete de entrega |
| `Faithful.rbxmx` | Carpeta nativa importable con los cuatro ModuleScripts y el LocalScript |
| `assets/` | Fondo, logo, referencia de distribución y sprite transparente de niebla |
| `tests/StudioSmoke.client.luau` | Prueba opcional para ejecutar dentro de Studio |
| `tools/build.py` | Regenera el archivo autocontenido sin ejecutar código dinámico |

Las versiones modular y autocontenida usan la misma implementación. Se instala **una de las dos**.

## 1. Configurar las imágenes

No se han publicado imágenes en tu cuenta de Roblox ni se han inventado IDs. **En Roblox Studio**, antes de evaluar el acabado visual:

1. Abre tu experiencia en Roblox Studio y su Asset Manager.
2. Importa `assets/FaithfulBackground.png`, `assets/FaithfulLogo.png` y `assets/CrimsonMist.png` como imágenes bajo el propietario o grupo de la experiencia. Conserva el canal alfa del logo y de la niebla.
3. Obtén los IDs de imagen correspondientes y verifica sus permisos para la experiencia.
4. En `FaithfulAssets`, sustituye los tres marcadores:

```luau
local Assets = {
    Background = "BACKGROUND_ASSET_ID",
    Logo = "LOGO_ASSET_ID",
    Smoke = "SMOKE_ASSET_ID",
    BackgroundContainsTitle = true,
}
```

Acepta el ID numérico escrito como cadena o `rbxassetid://` seguido de ese ID real. No admite enlaces a GitHub ni URLs de páginas de decals. No reemplaces el módulo entero por el bloque anterior: conserva su función `Resolve` y `return Assets`.

`LayoutReference.png` no se carga en el juego: sus opciones están incrustadas en la imagen. El sprite `CrimsonMist.png` es el único arte nuevo; se tiñe y anima en `FaithfulVFX`, detrás de los controles. No añade personajes ni símbolos al diseño.

**Alternativa para el `loadstring` en un ejecutor compatible:** si los IDs siguen sin configurar, `FaithfulAssets.LoadFromRepository()` descarga los PNG del commit fijo `dff138c...` de este repositorio, comprueba firma/tamaño y los registra mediante `getcustomasset` o `getsynasset` y `writefile`. Se reutiliza una caché local validada cuando existen `isfile` y `readfile`. Esto replica el principio del cargador visual de Reyzn X, sin descargar ni ejecutar scripts Lua externos. En ejecutores sin esas APIs, las imágenes necesitan IDs reales como en Studio.

Sin imágenes disponibles la interfaz sigue funcionando, con fondo oscuro y un sigilo nativo de respaldo. El estado de los recursos se expone en `AssetBackground`, `AssetLogo` y `AssetSmoke` del `ScreenGui` (`Ready`, `Assigned`, `NeedsRobloxId` o un error de carga).

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

## 4. Calidad y controles reutilizables

En `FaithfulTheme`:

```luau
Quality = "Ultra",               -- "Minimal", "Balanced" o "Ultra"
ReduceMotion = false,
RespectSystemReduceMotion = true,
MistIntensity = 0.24,
ShowcaseControls = false,        -- Mantiene la presentación limpia solicitada
```

| Nivel | Niebla | Partículas | Borde y pulso | Bucle ambiental |
| --- | --- | --- | --- | --- |
| Minimal | 0 | 0 | Selección fija y transiciones básicas | Ninguno |
| Balanced | 0 | Hasta 6 | Animados | Un Heartbeat, actualizaciones limitadas a 30 Hz |
| Ultra | Hasta 12 capas | Hasta 14 | Animados | El mismo Heartbeat, 30 Hz |

Las doce capas y catorce partículas se crean una sola vez y se reutilizan. Cambiar la calidad no crea un nuevo conjunto. Los niveles cambian la actividad, no prometen un FPS concreto. La frecuencia de actualización de los efectos es independiente de la frecuencia de renderizado del dispositivo.

Con movimiento reducido, se detienen la niebla, las partículas, el recorrido del borde y el pulso continuo. Las transiciones se limitan a un fundido breve, sin desplazamiento de páginas. También se respeta la preferencia de accesibilidad de Roblox cuando la API está disponible.

Si activas `ShowcaseControls`, **Main** muestra botón, toggle, slider, dropdown, campo de texto, separador, tooltip, notificación y confirmación. **Settings** ofrece calidad, movimiento reducido e intensidad de niebla. Los ejemplos solo afectan a estado local de la UI. Esta opción permanece desactivada en la entrega para mantener únicamente las cinco categorías visibles.

La API de construcción incluye `Button`, `Toggle`, `Slider`, `Dropdown`, `TextField`, `Separator`, `Tooltip`, `Notify` y `Confirm`. Toggle, Slider y Dropdown devuelven `Set(value, silent)`; TextField expone su `Box` nativo. Los callbacks son explícitos. No se evalúa el texto de los cuadros de entrada ni se ejecutan scripts desde la pestaña Scripts.

## 5. Cómo están hechos los VFX

**Crimson Mist:** un sprite transparente compartido, doce capas en tres profundidades, ciclos de aproximadamente 8–16 segundos, deriva lateral sinusoidal, expansión gradual y una envolvente de opacidad que llega a cero antes de reiniciar. Las emisiones se concentran en las zonas inferiores izquierda y derecha. El núcleo luminoso es el de menor opacidad; no hay mezcla aditiva ni una llama sólida.

**Crimson Border Flow:** un tramo estrecho viaja alrededor del perímetro. En las esquinas puede repartirse entre dos lados contiguos; nunca ilumina todo el borde a la vez.

**Ghoul Embers:** catorce puntos como máximo, pequeños y semitransparentes, cerca de los laterales. No se crean instancias en cada ciclo.

**Obsidian Transitions:** la última categoría solicitada gana. Se cancelan las animaciones anteriores y se normalizan posición y opacidad para impedir páginas superpuestas o fundidos acumulativos.

**Crimson Pulse:** el borde de la categoría seleccionada varía suavemente; la selección sigue siendo legible al desactivar el movimiento.

**Faithful Entrance:** fundido breve de ventana/fondo, aparición ligeramente retrasada del logo y comienzo del borde y de la niebla. La reapertura completa no impone una introducción larga.

La opacidad parte de valores base inmutables y factores por grupo. No se usan `CanvasGroup` de pantalla completa. No hay conexiones a `PreRender`, modificaciones de `Lighting` ni efectos 3D sobre el mundo. El bucle ambiental se desconecta al ocultar. Al destruir se cancelan tweens, temporizadores y precarga pendiente, y se desconectan los eventos.

## 6. Pruebas en Roblox Studio

1. **Primera apertura:** revisa Output, carga de las tres imágenes, nitidez, título no duplicado y el reloj en lugar de ONLINE.
2. **Interacciones:** cambia rápidamente entre las cinco categorías; minimiza y reabre varias veces; confirma y cancela el cierre. El estado y el contador deben continuar correctamente.
3. **Arrastre:** mueve la cabecera, luego el logo por separado. Repite con entrada táctil. Arrastra el botón de reapertura: soltarlo tras moverlo no debe abrir accidentalmente la ventana.
4. **Resoluciones:** prueba teléfono vertical y horizontal, tableta y escritorio con Device Simulator. Verifica áreas seguras, botones de al menos 44 px y navegación desplazable en pantallas bajas.
5. **Texto y componentes:** activa temporalmente `ShowcaseControls`; verifica límites del slider, dropdown expandible, texto UTF-8, notificaciones y confirmaciones. Restáuralo a `false` para la presentación limpia.
6. **Accesibilidad:** alterna los tres niveles y la reducción de movimiento. El movimiento ambiental debe desaparecer con esta última activada.
7. **Rendimiento:** en un teléfono real y en un cliente de escritorio, compara Minimal y Ultra con Developer Console/MicroProfiler. Revisa coste de UI, memoria de texturas y comportamiento tras varias reaperturas. Un límite de 30 Hz no sustituye esta medición.
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

- Código de referencia: [hzReyzn/Experimental — REYZN X UI EXPERIMENTAL](https://github.com/hzReyzn/Experimental/blob/main/REYZN%20X%20UI%20EXPERIMENTAL), blob `64c05792b807afe1fbc12f4234428923684a777c`. Se revisaron especialmente `UpdraftFire`, reutilización de capas, opacidad y actualización ambiental. No se trasladaron funciones de juego ni lanzadores externos.
- Destino solicitado: [hzReyzn/Faithful- — Faithful Exploit](https://github.com/hzReyzn/Faithful-/blob/main/Faithful%20Exploit). El archivo remoto examinado estaba vacío salvo un salto de línea; su blob era `8b137891791fe96927ad78e64b0aad7bded08bdc`.
- [Roblox: animación de UI](https://create.roblox.com/docs/ui/animation).
- [Roblox: áreas seguras de ScreenGui](https://create.roblox.com/docs/reference/engine/classes/ScreenGui).
- [Roblox: movimiento reducido](https://create.roblox.com/docs/reference/engine/classes/GuiService/ReducedMotionEnabled).
- [Roblox: coste de CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup).
- [Roblox: Asset Manager](https://create.roblox.com/docs/projects/assets/manager).
- [Roblox: pruebas y Device Simulator](https://create.roblox.com/docs/studio/testing-modes).

La versión se preparó y verificó antes de su publicación. El usuario aprobó expresamente publicar el script autocontenido y sus archivos de soporte en este repositorio. El README original y el repositorio de referencia se conservan intactos.
