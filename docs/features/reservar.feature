# language: es
Característica: Reservar una cancha
  Como jugador
  Quiero reservar un turno libre
  Para asegurarme la cancha a la hora que quiero jugar

  Antecedentes:
    Dado un complejo abierto de 09:00 a 23:30 con horario pico desde las 18:00
    Y la "Cancha 1" de pádel con turnos de 90 minutos, precio valle 18000 y pico 24000
    Y hoy es lunes 2 de noviembre a las 12:00

  Escenario: Reserva en horario pico
    Cuando reservo la "Cancha 1" el martes a las 19:30
    Entonces la reserva queda "Pendiente de seña"
    Y el precio es 24000
    Y la seña es 7200

  Escenario: No se puede reservar un horario ocupado
    Dado que la "Cancha 1" está reservada el martes de 19:30 a 21:00
    Cuando reservo la "Cancha 1" el martes a las 20:00
    Entonces la reserva es rechazada con "Ese horario ya está reservado."

  Escenario: No se puede reservar fuera del horario del complejo
    Cuando reservo la "Cancha 1" el martes a las 23:00
    Entonces la reserva es rechazada con "El turno está fuera del horario del complejo."
