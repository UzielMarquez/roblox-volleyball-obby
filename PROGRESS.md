# Progreso de implementación

## Corrección de cámara (Tarea 1)

- [x] Diagnóstico: `CameraController` anterior cambiaba a `CameraType.Scriptable` y reescribía `CFrame` cada frame cuando el jugador estaba en un equipo; no se encontraron otros scripts que consumieran los controles estándar de cámara.
- [x] Sincronizado a Studio el controlador con `CameraType.Custom`, zoom de 0.5–25 studs, tecla configurable V para alternar primera persona y el cuerpo oculto localmente en primera persona.
- [x] Añadido selector de modo de giro: ShiftLock (predeterminado durante partido) o rotación estándar con clic derecho; los ajustes y el binding de cámara se guardan mediante la configuración ya existente.
- [x] Playtest y verificación por código: `CameraType.Custom`, `CameraMode.Classic`, zoom 0.5–25, modo V entra/sale de primera persona, el cuerpo se oculta en primera persona, mouse bloqueado al centro en primera persona y durante partido con ShiftLock, y libre en lobby.
- [ ] Pendiente de confirmación del usuario: probar visualmente zoom con rueda, giro con clic derecho/ShiftLock y V durante partido; probar entrada táctil/gamepad. No iniciar los bots de entrenamiento hasta recibir confirmación.

## Voleibol de sala

- [ ] **Voleibol 1 — Mundo:** Mundo modular creado; arranque del constructor probado sin errores propios. Falta revisión visual/física completa en Studio.
- [ ] **Voleibol 2 — Lobby y flujo:** Cola/unirse/cancelar y entrenamiento probados en Studio (solo con DEBUG_ALLOW_SOLO); falta probar partidos completos con varios jugadores, rotaciones y ausencias.
- [ ] **Voleibol 3 — Balón y golpes:** El saque cargado llegó al servidor y produjo velocidad balística; separado el balón del avatar para evitar colisiones al sacar. Se corrigió la aceptación de golpes durante el estado de saque: un intento de "Set" dejó el balón anclado y el saque autorizado sí lo lanzó. Falta probar todos los golpes y los puntos con jugadores reales.
- [ ] **Voleibol 4 — Reglas:** Lógica implementada, pero faltan pruebas completas de rally, faltas, sets y final de partido.
- [ ] **Voleibol 5 — Interfaz y controles:** HUD y cliente cargan; reasignar "Recibir / sacar" a H actualizó la interfaz y el binding de ContextActionService. Mantener/soltar E emitió la confirmación "Released" y pasó por Rally en entrenamiento; faltan validar trayectoria y puntuación de forma controlada, además de móvil/gamepad y persistencia tras reinicio.
- [ ] **Voleibol 6 — Pulido y pruebas:** Pendiente; faltan efectos/sonidos configurables y revisión visual/performance.

## Obby de calentamiento

- [ ] **Obby 1 — Base:** 20 etapas generadas; Validator confirmó huecos/alturas válidos; se probaron entrada, checkpoint 1 y salida. Falta probar reaparición y hazards.
- [ ] **Obby 2 — Zonas 2–4:** Geometría y tipos de obstáculo generados para etapas 6–20; falta recorrer y probar cada hazard.
- [ ] **Obby 3 — Datos y recompensas:** Código y placeholders instalados; DataStore/OrderedDataStore no se pudieron verificar porque Studio tiene deshabilitado el acceso a API Services.
- [ ] **Obby 4 — Interfaz:** HUD muestra etapa, tiempo, reinicio y salida; falta validar diseño adaptable y dispositivos.
- [ ] **Obby 5 — Pulido y pruebas:** Persistencia, presupuesto, rendimiento, multijugador e interrupción/retoma aún requieren pruebas.

## Registro

- Estado actual: VOLEIBOL.md y OBBY.md leídos; arquitectura nueva sincronizada a Studio. El último arranque valida 20 etapas y no muestra errores de sintaxis propios. Se añadió caché inicial/merge para cambios mientras cargan datos y se rechazaron golpes durante el saque para evitar SetNetworkOwner sobre el balón anclado; también se limpian cargas de saque al resetear un punto.
- Pruebas de esta sesión: UI y rebind en Settings, entrenamiento, cola/cancelación, saque por teclado con respuesta del servidor y transición a Rally, saque por RemoteEvent y rechazo de golpe durante saque; también entrada al obby, checkpoint 1 y salida. El rally de entrenamiento terminó en "Balón al piso" y se reinició correctamente.
- Retirados de Studio los scripts de prueba antiguos `ServerScriptService.Script`, `Workspace.Script` y el módulo sin uso `VolleyballService`; el árbol activo conserva un único `Main` de servidor y un único `Main` de cliente.
- Output pendiente de configuración: DataStoreService rechaza operaciones porque **Enable Studio Access to API Services** está desactivado; los avisos FoundationProvider provienen de la interfaz interna de Studio.
- El playtest se dejó detenido en modo Edit.
- Repositorio Git: no disponible en la carpeta de trabajo.
- Pendientes para mí: ID de insignia, IDs de animaciones y sonidos, Developer Product de «Saltar etapa», pruebas con varios jugadores reales y ajuste fino de sensaciones.
