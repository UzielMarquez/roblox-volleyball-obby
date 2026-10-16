# OBBY DE CALENTAMIENTO — Especificación (Roblox)

## ROL
Eres un desarrollador senior de Roblox (Luau). Con las herramientas del servidor MCP de Roblox Studio vas a construir un OBBY llamado "Obby de Calentamiento" dentro del lobby de mi juego de voleibol. Trabaja por FASES. Al terminar cada fase: haz playtest, revisa el Output, corrige errores y dame un resumen.

## REGLAS DE ROBLOX Y TÉCNICAS (obligatorias)
- Luau con --!strict donde sea posible. Lógica en ModuleScripts; Scripts y LocalScripts solo como puntos de entrada. Textos de interfaz y comentarios en español; nombres de código en inglés.
- Todo se crea por código, sin assets externos. Servidor autoritativo: muertes, checkpoints, progreso y recompensas se validan en el servidor. El cliente solo muestra interfaz y efectos.
- No cambies Workspace.Gravity (queda en 196.2) ni los valores por defecto del Humanoid mientras el jugador está en el obby: WalkSpeed 16, JumpHeight 7.2. Si el sistema de partidos los modifica, restáuralos al entrar al obby.
- Física de referencia con esos valores: un salto cubre unos 8.7 studs en horizontal. Límites de diseño (distancia borde a borde entre plataformas al mismo nivel): Zona 1 hasta 4.5 studs, Zona 2 hasta 5.5, Zona 3 hasta 6.5, Zona 4 hasta 7.5. Escalón vertical máximo: 4 studs en Zona 1, 4.5 en Zona 2, 5 en Zona 3 y 5.5 en Zona 4; si un salto combina hueco y subida, reduce ambos. Nunca exijas el límite real del salto. Plataformas de al menos 6x6 studs en Zona 1-2 y de al menos 4x4 en Zona 3-4 (compatibles con móvil).
- Compatibilidad: teclado, gamepad y móvil. Ningún obstáculo debe depender de precisión de mouse.
- Rendimiento: todo Anchored salvo lo estrictamente necesario; desactiva CanTouch y CanQuery en piezas decorativas; usa CollectionService para etiquetar (Checkpoint, KillBrick, Mover, Spinner, Conveyor, Fader, Laser); parámetros en Attributes; objetos en Folders por zona; presupuesto de unas 3000 partes en total. Compatible con StreamingEnabled (que ningún script dependa de instancias lejanas ya cargadas; usa WaitForChild y ModelStreamingMode adecuado en checkpoints y meta).
- Movimiento de plataformas con TweenService sobre partes ancladas o con constraints, y verifica en playtest que el personaje viaje con la plataforma. Los trampolines (si los hay) aplican el impulso en el cliente dueño del personaje (LocalScript) con validación razonable en el servidor, porque el cliente tiene la autoridad de la física de su personaje.
- Contenido apto para todas las edades. Sin marcas, logos ni material con copyright; sin audio externo no verificado (usa solo audio de Roblox permitido o deja IDs configurables en Config).
- Monetización (opcional, apagada por defecto): "Saltar etapa" con Developer Product usando MarketplaceService y ProcessReceipt correctamente. No agregues compras aleatorias.
- Seguridad: limita la frecuencia de cada RemoteEvent, valida tipos y rangos, y aplica los checkpoints solo en orden (etapa actual + 1). Nunca confíes en datos del cliente.
- Arquitectura:
  - ReplicatedStorage/Shared: ObbyConfig (datos de etapas y límites), Remotes
  - ServerScriptService/Server: ObbyService, StageBuilder, HazardService, ObbyDataService, ObbyValidator
  - StarterPlayerScripts/Client: ObbyHUD, ObbyEffects
- Diseño guiado por datos: cada etapa se describe en ObbyConfig (zona, tipo de obstáculo, medidas, dificultad) y StageBuilder construye el obby desde esos datos. ObbyValidator revisa automáticamente que ninguna distancia ni altura entre plataformas consecutivas supere los límites de la zona, y reporta los errores.

## UBICACIÓN E INTEGRACIÓN CON EL JUEGO
- El obby está en el mundo del lobby, en un área separada y bien señalizada. Entrada con un pad "OBBY" (ProximityPrompt) en el lobby; salida con un pad "Volver al lobby" en la meta y un botón en pantalla.
- Mientras el jugador está en el obby puede seguir en la cola de partidos. Si empieza un partido, se guarda su etapa, se marca su atributo InObby como falso y el sistema de partidos lo teletransporta a la cancha. Al volver, retoma desde su último checkpoint.
- Muerte o reinicio del personaje: reaparece en el último checkpoint (CFrame un poco por encima) sin perder progreso. Un botón "Reiniciar etapa" lo regresa al checkpoint sin penalización.

## DISEÑO DE ETAPAS (20 etapas, checkpoint al final de cada una, zonas con piso y colores distintos)

### Zona 1 - Calentamiento (etapas 1-5)
1. Escaleras de bancas con cartel de bienvenida y tutorial corto.
2. Saltos en línea sobre plataformas grandes.
3. Pasarela estrecha de 5 studs de ancho, recta.
4. Zigzag de plataformas alternadas.
5. Plataformas que se desvanecen al pisarlas (1 s) y reaparecen a los 3 s.

### Zona 2 - Cancha (etapas 6-10)
6. Pared de red para trepar con TrussPart.
7. Pasillo con una barredora giratoria baja (brazo de bloqueo) lenta; se salta por encima.
8. Cinta transportadora en contra, con plataformas seguras para descansar.
9. Plataformas móviles horizontales sobre un vacío.
10. Balones gigantes que ruedan por una rampa en intervalos regulares, con nichos para esquivarlos (movidos por Tween o ruta fija, sin física inestable).

### Zona 3 - Gimnasio (etapas 11-15)
11. Plataformas pequeñas en arco.
12. Puertas de láser (partes neón) que se encienden y apagan en ciclos de unos 2 s; se cruza en la ventana segura.
13. Discos giratorios lentos.
14. Pilares de alturas distintas (3 a 5 studs) para saltar en secuencia.
15. Trampolines (colchonetas) para alcanzar la siguiente plataforma.

### Zona 4 - Torneo (etapas 16-20)
16. Elevadores verticales encadenados.
17. Dos barredoras en secuencia con huecos.
18. Plataformas intermitentes con patrón de colores que avisa antes de desaparecer.
19. Salto de precisión largo ("salto de remate") con plataforma de carrera previa; hueco máximo de la Zona 4.
20. Subida al podio con trofeo y efecto de celebración.

- El vacío bajo el obby tiene piso o zona de reaparición con KillBrick de color rojo visible. Los obstáculos peligrosos son claramente distinguibles.

## PROGRESO, TIEMPO Y RECOMPENSAS
- leaderstats con "Etapa". El temporizador del obby empieza al pisar la etapa 1 y termina en la meta; guarda el mejor tiempo.
- ObbyDataService guarda etapa actual, mejor tiempo y obby completado con DataStore (pcall, reintentos y valores por defecto si falla). Recuérdame que hay que activar "Enable Studio Access to API Services" en la configuración del juego para probar el guardado en Studio.
- Meta: otorga una insignia con BadgeService:AwardBadge desde el servidor (deja el ID del badge como placeholder en ObbyConfig; yo lo crearé en el Creator Hub) y desbloquea una estela cosmética para el balón (solo visual, guardada en DataStore).
- Tablero de líderes en el lobby (SurfaceGui) con los mejores tiempos usando OrderedDataStore, con actualización periódica y sin saturar el servicio.

## INTERFAZ
- ObbyHUD: etapa actual (x/20), temporizador, botón "Reiniciar etapa", botón "Salir del obby". Avisos como "¡Checkpoint!" al avanzar. Todo adaptable a móvil.

## FASES
1. Base: ObbyConfig, ObbyService (checkpoints en orden, reaparición, leaderstats), HazardService (KillBrick), entrada y salida del lobby, StageBuilder y las etapas 1-5. ObbyValidator funcionando.
2. Zonas 2 a 4: etapas 6-20 con sus obstáculos móviles, lásers, giratorios, cintas y trampolines.
3. Datos y recompensas: guardado, tiempos, meta, insignia (placeholder), estela, tablero de líderes.
4. Interfaz: ObbyHUD, botones, avisos, soporte móvil y gamepad.
5. Pulido y pruebas: sonidos configurables, iluminación por zona, optimización (conteo de partes, StreamingEnabled), pruebas con 2 o más clientes (Test > Clients and Servers), prueba de que un partido interrumpe y retoma el obby sin errores, y corrección de bugs.

## ENTREGA POR FASE
Lista de scripts e instancias creados, cómo probar lo de esa fase, resultados del ObbyValidator y lo que falta.