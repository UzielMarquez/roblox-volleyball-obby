# FISICA — Física y mecánicas del juego (estilo Volleyball Legends)

Este documento PREVALECE sobre VOLEIBOL.md en todo lo que tenga que ver con controles, física del balón, golpes, movimiento y estadísticas. Lo demás de VOLEIBOL.md (lobby, cola, flujo, reglas, datos, interfaz) sigue igual. Si ya existe código que contradice este documento, actualízalo.

## 1. Qué se sabe y qué no
Referencia: el juego "Volleyball Legends" de Roblox. Las guías públicas describen controles, mecánicas y estadísticas, pero NO publican valores numéricos de física (velocidades, gravedad del balón, medidas de cancha en studs). Por eso:
- Lo cualitativo de abajo (cómo se comporta cada acción) viene de guías públicas.
- Todos los números de este documento son valores iniciales propuestos por mí para empezar a afinar. No son datos de ese juego.
- Todo debe quedar en Config y ser ajustable en vivo (ver sección 9).
- No copies nada de su propiedad intelectual: ni nombres, ni personajes, ni estilos o habilidades con nombres del anime que lo inspira, ni skins de balón, ni arte, ni música. Copiar mecánicas está bien; copiar contenido no. Crea estilos, nombres y estética propios.

## 2. Esquema de controles (reemplaza a los de VOLEIBOL.md)
Contextual, con apuntado hacia donde apunta el cursor. Todo reasignable.
- Mover: WASD / stick izquierdo. Saltar: Espacio / A.
- Clic izquierdo / RT: Pase (bump) en el suelo; Remate (spike) en el aire. También inicia y detiene la barra de potencia del saque.
- Q / LT: Colocar (set) en el suelo; Bloqueo (block) en el aire.
- Ctrl / X: Lanzarse (dive).
- Shift / Y: ShiftLock (el personaje mira hacia donde apunta la cámara). Durante el partido debe estar activo por defecto, porque el apuntado depende de él.
- Móvil: botones en pantalla con las mismas acciones contextuales (golpe, colocar o bloquear, saltar, lanzarse).

## 3. Apuntado
- La dirección y el destino de cada golpe salen de un raycast desde la cámara (cursor, centro de pantalla en ShiftLock o stick derecho) contra el plano de la cancha. El resultado es un punto objetivo en el suelo.
- Remate: el balón cae un poco antes del punto apuntado. Resta unos 3 studs en la dirección del golpe y ajusta con una variable AimShort en Config.
- Bloqueo: si el bloqueo conecta, el balón sale hacia el punto apuntado.
- Dive: se apunta hacia donde va a caer el balón.
- Asistencia de apuntado opcional y apagada por defecto.

## 4. Física del balón (arquitectura recomendada)
No dependas de la replicación de física de Roblox para el balón. Usa una trayectoria determinista:
- Cada golpe produce una trayectoria parabólica descrita por: posición inicial, velocidad inicial, gravedad propia del balón, tiempo de inicio (os.clock sincronizado con el servidor), spin y arrastre. El servidor es la autoridad y envía esos parámetros a los clientes; cada cliente reproduce la misma trayectoria localmente. Así el balón se ve fluido aunque haya ping.
- El servidor avanza el balón en Heartbeat y revisa colisiones por raycast entre pasos: piso, red, paredes, techo, postes. No uses Touched para esto.
- Fallback: si algo falla, el balón puede ser una Part con física normal y SetNetworkOwner(nil).
- Valores iniciales (Config.Ball):
  - Diámetro 2.8 studs.
  - Gravedad propia del balón: 90 studs/s² (más baja que los 196.2 del mundo, para arcos legibles).
  - Arrastre del aire: 0.02 por segundo.
  - Rebote visual en el piso: 0.5 (el rally ya terminó, es solo estético).
  - Red: el balón pierde un 70% de su velocidad al tocarla y cae hacia el lado donde iba.
- Spin: el atributo Spin del saque añade aceleración lateral al balón (curva) y un leve cambio de caída. Va de 0 a 1.3 en Config.

## 5. Acciones: forma de la trayectoria
Valores iniciales; todos escalan con la estadística correspondiente (sección 7).
- Pase (bump): lento y de arco alto. Tiempo de vuelo ~1.4 s. Va hacia el punto apuntado; a corta distancia sirve para pasar a un compañero y a larga para pasar la red. Si se golpea cerca de la red, puede sorprender al rival, pero es peor que rematar.
- Colocación (set): arco más alto y más corto que el pase. Apogeo de ~28 a 34 studs sobre el punto de golpe, tiempo de vuelo ~1.1 s, alcance máximo ~22 studs. Si se apunta hacia la red muy cerca de ella, el balón puede pasar al rival y darle una bola fácil.
- Remate (spike): solo en el aire y con el balón por encima de 7 studs. Trayectoria rápida y descendente: velocidad inicial de 60 a 100 studs/s según Spike; tiempo de vuelo ~0.45 a 0.7 s. Cuanto más cerca de la red y más alto el golpe, más pronunciado el ángulo de bajada.
- Saque en dos etapas:
  1. El jugador presiona el botón de golpe para iniciar la barra de potencia (oscila de izquierda a derecha en ~1.2 s) y lo presiona otra vez para detenerla. Lo más a la derecha es máxima potencia.
  2. El balón sube unos 14 studs y se queda un instante (~1.8 s) mientras el jugador salta y remata hacia el punto apuntado, o lo golpea desde el suelo (saque débil y fácil de recibir).
- Bloqueo: solo en el aire, cerca de la red. Ventana de contacto de ~0.25 s alrededor del punto más alto del salto. Si conecta, el balón sale hacia el punto apuntado con ~80% de la velocidad entrante. Lo ideal es saltar justo después de que el rival salte. No cuenta como toque de equipo.
- Lanzarse (dive): impulso corto hacia adelante a ~28 studs/s durante ~0.35 s, con alcance extra de ~4 studs y recuperación de ~0.8 s. Es la acción más exigente: hay que apuntar al lugar de caída y ejecutarla rápido contra balones veloces.

## 6. Reglas de contacto
- Radio de contacto horizontal: 7 studs para pase y colocación; 6 para remate y bloqueo. Altura permitida: pase y colocación con el balón entre 0 y 8 studs sobre el suelo; remate y bloqueo con el balón por encima de 7 (o a la altura de las manos al saltar).
- El servidor valida alcance, estado del rally, turno, cooldown (~0.25 s) y que la acción sea posible (no rematar en el suelo, no bloquear fuera de la zona de la red).
- Tolerancia de latencia: acepta golpes con hasta ~120 ms de retraso comparando contra la posición del balón en ese instante (compensación de lag).
- Calidad (perfecto, bueno, flojo) según distancia al balón y timing; afecta dirección y potencia.
- Las reglas de toques y puntuación son las de VOLEIBOL.md (3 toques, bloqueo no cuenta, rotación, etc.).

## 7. Movimiento y estadísticas
Cada jugador tiene 9 estadísticas (porcentaje; 100% es la línea base y algunas pueden pasar de 100%): Block, Bump, Dive, Jump, Serve, Set, Speed, Spike y Spin.
- Speed: WalkSpeed = 16 + 10 x (Speed/100), entre ~16 y ~26.
- Jump: JumpHeight = 6 + 6 x (Jump/100), alrededor de 12 studs con 100%. Algunos estilos pueden tener dos modos de salto (normal y alto).
- Spike, Serve, Bump, Set, Block, Dive: multiplican potencia, precisión o alcance de su acción. Un valor bajo agranda el error de dirección.
- Spin: curva del saque (sección 4).
- Mantén el rango de cada estadística en Config para balancear sin tocar código.
- Estilos: paquetes de estadísticas. Crea estilos originales (nombres propios) de cuatro rarezas como mínimo, y roles recomendados: Bloqueador, Sacador, Rematador, Colocador, Líbero y Polivalente.
- Habilidades opcionales: efectos que modifican una acción (por ejemplo, salto reforzado o mejora de velocidad del equipo). Es una capa para después, tras tener el núcleo bien afinado.

## 8. Medidas y escala
Valores iniciales; el objetivo es que el juego se sienta ágil y legible para 6 contra 6:
- Personaje R15 de ~5 studs de alto.
- Cada mitad de cancha de 36 x 36 studs (72 x 36 en total) y red con borde superior a ~9 studs. Estas medidas son una propuesta mía; confírmalas jugando y ajusta en Config.
- Línea de ataque a ~12 studs de la red.
- Zona de saque detrás de la línea de fondo.
- La velocidad de movimiento, la altura de salto y el tamaño de cancha deben definirse juntos: que un jugador pueda cubrir su zona de recepción pero no toda la cancha.

## 9. Herramientas de afinación (obligatorias)
- Panel de depuración (solo en Studio): sliders para gravedad del balón, arrastre, velocidades, tiempos de vuelo, radios de contacto, AimShort y estadísticas base, con valores en vivo desde Attributes.
- Telemetría en pantalla: velocidad del balón, altura del apogeo, tiempo de vuelo, ping simulado.
- Modo entrenamiento con balón que se reinicia, para probar cada acción en repetición.
- Comparación: graba un video de Volleyball Legends y de tu juego haciendo la misma acción (pase, colocación, remate) y compara tiempos de vuelo y alturas de apogeo con un cronómetro. Ajusta los valores de Config hasta que se parezcan. Esa medición solo puedes hacerla tú jugando.

## 10. Cambios respecto a VOLEIBOL.md
- Controles: usar los de la sección 2 en lugar de E, F, R, Q y C.
- Mecánica de golpes: usar las secciones 3, 4, 5 y 6 en lugar de la velocidad directa con impulso.
- Saque: usar el saque en dos etapas de la sección 5.
- Estadísticas y estilos: agregar el sistema de la sección 7 al DataService (guardar estilo equipado).
- Medidas de cancha: usar las de la sección 8 en lugar de 32 x 32 studs por mitad.

## 11. Fases de trabajo
1. Núcleo de física: BallService con trayectoria determinista, colisiones por raycast, red y piso, Config y telemetría.
2. Acciones: pase, colocación, remate y bloqueo con apuntado por raycast y validación del servidor.
3. Saque en dos etapas, dive y ShiftLock.
4. Estadísticas y estilos originales; mapeo a movimiento y potencia.
5. Panel de depuración y afinación; compensación de lag; pruebas con 2 o más clientes.
6. Habilidades opcionales y pulido.

## ENTREGA POR FASE
Lista de cambios, cómo probarlos y qué valores de Config conviene afinar.