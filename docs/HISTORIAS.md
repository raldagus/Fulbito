# Historias de usuario

Cada historia va a ser un issue de GitHub (paso 1.6). Los criterios de aceptación se agregan en el paso 1.2.

## Alcance actual

| # | Historia | Reglas |
|---|---|---|
| H1 | Como jugador quiero ver los turnos libres de un día con su precio para elegir el que más me convenga. | R1, R2, R5 |
| H2 | Como jugador quiero reservar un turno libre para asegurarme la cancha. | R1, R2, R3, R4, R5, R6, R9 |
| H3 | Como jugador quiero ver mis reservas para saber cuándo juego y en qué estado está cada una. | — |
| H4 | Como jugador quiero cancelar mi reserva para liberar el turno si no puedo ir y saber si recupero la seña. | R8 |
| H5 | Como dueño quiero confirmar la seña de una reserva para que el turno quede asegurado. | R7, R10 |
| H6 | Como dueño quiero ver la agenda del día con los datos de quien reservó para saber a quién espero y poder contactarlo. | R10 |
| H7 | Como dueño quiero bloquear un horario para hacer mantenimiento sin que nadie lo reserve. | R4, R10 |
| H8 | Como admin quiero dar de alta complejos y dueños para sumar nuevos complejos a la plataforma. | — |

## Para más adelante

Quedan fuera del alcance actual. Si alguna entra, primero se agregan sus reglas al `ROADMAP.md`.

- **Administrar el complejo.** Como dueño quiero configurar mis canchas, horarios y precios para mantener mi oferta actualizada. Por ahora, estos datos salen del seed de la Etapa 3.
- **Reportes.** Como dueño quiero ver la ocupación semanal y mensual de mis canchas para saber cómo va el negocio. Los ingresos comparados pueden ser otra historia.
- **Recordatorios.** Como jugador quiero recibir un recordatorio antes de mi turno para no olvidarme. La Etapa 13 lo plantea por email, el día anterior; acá se pidió 3 horas antes.
- **Turnos fijos.** Como jugador quiero reservar el mismo día y horario todas las semanas para asegurarle la cancha a mi grupo. Choca con R3 (14 días de anticipación) y R9 (2 reservas activas).
- **Cambiar la fecha.** Como jugador quiero mover mi reserva a otro turno para no tener que cancelarla. Falta definir qué pasa con la seña.
