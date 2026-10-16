VOLEIBOL — Especificación del juego (Roblox)
ROL

Eres un desarrollador senior de Roblox (Luau). Con las herramientas del servidor MCP de Roblox Studio (crear instancias, escribir scripts, ejecutar playtests, leer el Output) vas a construir un juego completo de VOLEIBOL DE SALA (indoor). Trabaja por FASES. Al terminar cada fase: haz playtest, revisa el Output, corrige errores y dame un resumen. Si el proyecto ya tiene scripts llamados BallServer, CourtSetup o HitClient, úsalos solo como referencia y reemplázalos por la arquitectura de abajo.

REGLAS TÉCNICAS
Luau, con --!strict donde sea posible. Toda la lógica en ModuleScripts; Scripts y LocalScripts solo como puntos de entrada.
Todo se crea por código, sin assets externos. Parámetros ajustables en un módulo Config.
Servidor autoritativo: balón, reglas, puntos y rotaciones solo en el servidor. El cliente solo envía intenciones de input y recibe estado. Valida todo en el servidor (tipos, rangos, cooldowns, distancia, turno). Balón con SetNetworkOwner(nil). Limita la frecuencia de cada RemoteEvent.
Textos de interfaz y comentarios en español; nombres de código en inglés.
Estructura:
ReplicatedStorage/Shared: Config, Remotes, Types, Rules (lógica pura de reglas)
ServerScriptService/Server: Main, GameService, MatchService, BallService, CourtService, LobbyService, DataService
StarterPlayerScripts/Client: InputController, CameraController, HUD, LobbyUI, SettingsUI, Effects, Animations
MUNDO (un solo place, lobby y cancha separados en el mismo mundo)
Cancha: cada mitad de 32x32 studs (64x32 en total), piso con cara superior en y=0. Red con borde superior a ~9 studs (ajusta salto o JumpHeight para que un remate alcance el borde), postes, línea central, línea de ataque a ~10.7 studs de la red, paredes y techo invisibles como respaldo.
Zonas (partes invisibles o chequeos de posición): dentro de cancha por lado (las líneas cuentan como dentro), zona de saque detrás de la línea de fondo de cada lado, plano de la red.
Lobby: edificio sencillo alejado de la cancha, con SpawnLocation donde el jugador aparece y puede caminar. Incluye un pad o portal "JUGAR" (ProximityPrompt), otro "ENTRENAMIENTO", y un panel o cartel "CONTROLES" que abre el menú de ajustes. Decoración simple.
Posiciones de partida: 6 posiciones por equipo (P1 zaguero derecho que saca, P2 delantero derecho, P3 delantero centro, P4 delantero izquierdo, P5 zaguero izquierdo, P6 zaguero centro). Define el layout para 6 jugadores y para 3 y 2 (según TEAM_SIZE).
FLUJO (máquina de estados en GameService)

Lobby -> Cola -> Cuenta regresiva -> Preparación (teleport y posiciones) -> Preparar saque -> Rally -> Fin de punto -> (Fin de set) -> Fin de partido -> Resultados -> Regreso al lobby.

Al pulsar JUGAR el jugador entra a una cola (UI: "En cola x/y", con botón cancelar).
TEAM_SIZE configurable (por defecto 3; real: 6). Bandera de debug en Studio que permite iniciar con 1 jugador para pruebas.
Con jugadores suficientes: cuenta regresiva de 10 s, equipos balanceados (A = lado izquierdo, B = lado derecho), teleport a sus posiciones, movimiento bloqueado hasta el saque.
Si alguien se va a mitad de partido: lo reemplaza alguien de la cola, o se declara forfeit si un equipo queda vacío.
Modo entrenamiento: un jugador en un lado, balón que se reinicia, sin marcador.
Al terminar: pantalla de resultados con estadísticas y botón "Volver al lobby" (teleport automático tras unos segundos).
REGLAS (módulo Rules, puntuación por rally)
Cada rally da punto. Set a 25 con ventaja de 2. Mejor de 3 sets (configurable); set decisivo a 15. Cambio de lado entre sets.
Gana el rally = saca el siguiente. Si gana quien recibía (side-out), su equipo rota en sentido horario: cada jugador pasa a la siguiente posición.
Saque: desde la zona de saque, el balón debe cruzar la red; si toca la red y pasa, es válido. Falta si no cruza o cae fuera. Límite de 8 s para sacar (configurable); si se pasa, punto al rival.
Máximo 3 toques por equipo; el mismo jugador no puede tocar dos veces seguidas. El bloqueo no cuenta como toque (el bloqueador sí puede tocar después).
Fuera: el balón cae fuera de la cancha o toca pared, techo o algo fuera de límites. Dentro: cae dentro del lado (líneas incluidas).
Durante el juego, el balón puede tocar la red y seguir, salvo que ya sea el tercer toque y no cruce (falta).
Falta si un jugador toca la red.
Falta por cuarto toque, doble contacto, balón al piso propio, balón fuera.
Restricción de zagueros (no rematar desde delante de la línea de ataque) como opción apagada por defecto.
BallService registra: último equipo y jugador que tocó, contador de toques, si cruzó la red. Detecta el cruce de la red por posición entre frames, y el aterrizaje por posición, no solo por Touched.
CONTROLES (todos reasignables)
Mover: WASD / stick izquierdo / joystick móvil. Correr: Shift.
Saltar: Espacio / A / botón.
Pase o recibo (bump): E / X / botón.
Colocar (set): F / Y / botón.
Remate (spike): R en el aire / B / botón.
Bloqueo: Q cerca de la red (salto con brazos arriba) / L1 / botón.
Lanzarse (dive) para balones bajos: C / R1 / botón.
Saque: mantener E para cargar la barra de potencia, soltar para sacar; la dirección sale de la cámara. Opción de saque flotante o potente.
Cámara con mouse. Menú de ajustes con Esc o desde el lobby.
Usa ContextActionService y un módulo Keybinds. El menú de Controles permite reasignar teclas, ajustar sensibilidad y volumen, y restaurar valores por defecto. Se guarda con DataStore.
MECÁNICA DE GOLPES
El cliente envía: acción, dirección de cámara y timestamp. El servidor valida: radio de contacto (~6 studs), altura permitida según acción (bump bajo, set sobre la cabeza, spike en el aire, bloqueo en la red), cooldown, estado del rally y turno del equipo.
Calidad del golpe (perfecto, bueno, flojo) según distancia al balón, orientación y timing; la calidad añade un error controlado de dirección y potencia.
No uses impulsos crudos: calcula la velocidad de lanzamiento balística para llegar a un punto objetivo con un arco y tiempo de vuelo definidos.
Bump: arco alto hacia el colocador o centro de la cancha.
Set: arco alto y suave hacia el punto de ataque.
Spike: trayectoria rápida y descendente hacia el lado contrario según la mira.
Bloqueo: reflejo o amortiguación.
Saque: potencia según la barra.
Asistencia de apuntado opcional (configurable).
Balón: gravedad propia más ligera que la de los jugadores, rozamiento aéreo leve, rebote realista en piso, red y paredes.
INTERFAZ Y CÁMARA
HUD: marcador, sets ganados, indicador de quién saca, contador de toques del equipo, barra de potencia de saque, sugerencias de teclas, avisos ("¡Fuera!", "Cuatro toques", "Red"), pantalla de resultados.
Cámara en tercera persona mirando hacia la red; opción de seguir al balón.
Soporte de teclado, gamepad y móvil (botones táctiles).
DATOS, AUDIO Y ANIMACIÓN
DataService: guardar keybinds y estadísticas (partidos, victorias, puntos, aces, remates, bloqueos) con DataStore, pcall y reintentos; valores por defecto si falla.
Sonidos: golpe, silbato, red. Partículas leves en remates.
Animaciones: módulo Animations con IDs fáciles de cambiar; mientras tanto, poses simples de brazos con tweens.
FASES
Mundo: lobby, cancha, red, límites, zonas, spawns y Config.
Lobby y flujo: UI de JUGAR, cola, entrenamiento, máquina de estados, equipos, teleport, rotaciones, regreso al lobby.
Balón y golpes: BallService, input, mecánica de golpes, calidad, saque con barra.
Reglas: módulo Rules, detección de puntos y faltas, marcador, sets, cambio de lado, fin de partido.
Interfaz y controles: HUD, ajustes con reasignación, móvil y gamepad, DataStore.
Pulido y pruebas: sonidos, efectos, balance, pruebas con 2 o más clientes (pestaña Test > Clients and Servers), corrección de bugs y optimización.
ENTREGA POR FASE

Lista de scripts e instancias creados, cómo probar lo de esa fase y qué falta.