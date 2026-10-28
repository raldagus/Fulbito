# Repaso · Lo que hay que saber y cómo se aplica en Fulbito

Cada sección tiene tres partes:

- **Qué tenés que saber:** la teoría mínima.
- **Cómo se aplica:** un ejemplo con el código de este proyecto.
- **Preguntas de entrevista:** las respuestas están ocultas. Intentá contestar en voz alta antes de abrirlas.

El código es orientativo: Claude Code lo va construyendo con vos paso a paso y puede variar un poco.

## Índice

| Base | Backend | Testing | Frontend | Entrega |
|---|---|---|---|---|
| [1 Git](#1-git-y-flujo-de-trabajo) | [9 EF Core](#9-ef-core) | [5 TDD](#5-tdd) | [16 React + TS](#16-react-con-typescript) | [22 Docker](#22-docker) |
| [2 C# moderno](#2-c-moderno) | [10 SQL Server y concurrencia](#10-sql-server-y-concurrencia) | [6 xUnit](#6-xunit-y-shouldly) | [17 TanStack Query](#17-tanstack-query) | [23 Extras](#23-extras) |
| [3 POO y SOLID](#3-poo-y-solid-en-el-dominio) | [11 Result pattern](#11-result-pattern) | [7 Mocks](#7-mocks-con-nsubstitute) | [18 Formularios](#18-formularios-con-react-hook-form--zod) | [24 Azure](#24-azure-servicios-del-proyecto) |
| [4 Arquitectura](#4-arquitectura-en-capas-clean-architecture) | [12 ASP.NET Core](#12-aspnet-core-web-api) | [13 Integración](#13-tests-de-integración) | [19 UX/UI](#19-uxui-y-accesibilidad) | [25 Azure DevOps](#25-azure-devops-boards-y-pipelines) |
| [8 Tiempo](#8-manejo-del-tiempo) | [15 Seguridad](#15-seguridad) | [14 BDD](#14-bdd-con-gherkin-y-reqnroll) | [20 Testing React](#20-testing-en-react) | |
| | | [21 Playwright](#21-e2e-con-playwright) | | |

---

## 1. Git y flujo de trabajo

**Qué tenés que saber**

- Una rama por etapa, con un PR a `main` cuando la etapa termina. En el PR se revisa el diff completo.
- Commits chicos con Conventional Commits: `test: superposición de reservas en los bordes`, `feat: precio pico en fin de semana`.
- En TDD, los commits cuentan la historia: primero `test:` (rojo), después `feat:` (verde) y después `refactor:`.

**Cómo se aplica:** cada paso del ciclo de Claude Code termina con un commit propuesto que vos aprobás.

<details><summary>¿Merge o rebase?</summary>

Merge conserva la historia tal cual pasó y agrega un commit de merge. Rebase reescribe tus commits encima de la rama destino y deja una historia lineal. Regla práctica: rebase en tu rama local antes de abrir el PR, nunca sobre ramas compartidas que otros ya bajaron.
</details>

---

## 2. C# moderno

**Qué tenés que saber**

- `record` para datos inmutables (DTOs, comandos): tienen igualdad por valor.
- Nullable reference types: `string?` puede ser null y `string` no. El compilador te avisa.
- `DateTimeOffset` en lugar de `DateTime`: guarda el instante junto con el desfase horario.
- Pattern matching y switch expressions para reglas legibles.
- Constructores primarios (C# 12) para inyectar dependencias sin repetir campos.

**Cómo se aplica**

```csharp
public sealed record CrearReservaCommand(Guid CanchaId, string ClienteId, DateTimeOffset Inicio);

public enum EstadoReserva { PendienteSena, Confirmada, Cancelada, Completada, NoAsistio }

// R5 con pattern matching
private bool EsHorarioPico(DateTimeOffset inicioLocal) => inicioLocal switch
{
    { DayOfWeek: DayOfWeek.Saturday or DayOfWeek.Sunday } => true,
    _ => TimeOnly.FromDateTime(inicioLocal.DateTime) >= InicioPico
};
```

<details><summary>¿Diferencia entre class y record?</summary>

Las dos son tipos por referencia, pero el record compara por valor: dos records con los mismos datos son iguales. Además trae `ToString` legible y `with` para crear copias modificadas. Sirve para DTOs y comandos. Para entidades con identidad y comportamiento, como `Reserva`, se usa `class`.
</details>

<details><summary>¿Por qué DateTimeOffset y no DateTime?</summary>

`DateTime` puede ser Local, Utc o Unspecified, y eso genera errores silenciosos al guardar o comparar. `DateTimeOffset` siempre representa un instante exacto. En un sistema de turnos, un error de 3 horas es un turno reservado en el horario equivocado.
</details>

---

## 3. POO y SOLID en el dominio

**Qué tenés que saber**

- **Entidad rica vs anémica.** En una entidad anémica las propiedades tienen `set` público y las reglas viven en servicios. En una entidad rica, la misma entidad protege sus reglas. Acá usamos entidades ricas.
- **Encapsulamiento:** `private set` y métodos con nombre de negocio (`Cancelar`, `ConfirmarSena`) en lugar de `reserva.Estado = ...`.
- **SOLID** en una línea cada uno:
  - S: una razón para cambiar.
  - O: extender sin modificar.
  - L: los subtipos se pueden usar en lugar del padre.
  - I: interfaces chicas.
  - D: depender de abstracciones.

**Cómo se aplica**

```csharp
public sealed class Reserva
{
    public Guid Id { get; private set; }
    public Guid CanchaId { get; private set; }
    public DateTimeOffset Inicio { get; private set; }
    public DateTimeOffset Fin { get; private set; }
    public EstadoReserva Estado { get; private set; }
    public decimal Precio { get; private set; }
    public decimal Sena { get; private set; }

    public bool EstaActiva => Estado is EstadoReserva.PendienteSena or EstadoReserva.Confirmada;

    public bool SeSuperponeCon(DateTimeOffset inicio, DateTimeOffset fin) =>
        Inicio < fin && inicio < Fin;   // intervalos [inicio, fin)

    private Reserva() { } // para EF Core
}
```

La D de SOLID es la que más se ve: los handlers dependen de `IReservaRepository` y de `TimeProvider`, no de EF ni del reloj del sistema. Por eso se pueden testear.

<details><summary>¿Qué problema tiene poner `public set` en todas las propiedades?</summary>

Cualquier parte del código puede dejar la entidad en un estado inválido, por ejemplo una reserva cancelada con seña confirmada. Las reglas terminan repetidas en varios lugares. Con métodos de negocio, la regla está en un solo lugar y está testeada.
</details>

<details><summary>Explicá Inversión de Dependencias con un ejemplo del proyecto</summary>

`CrearReservaHandler` (Application) necesita guardar reservas, pero no conoce EF. Depende de `IReservaRepository`, definido en Application, y la implementación concreta vive en Infrastructure. Así la regla de alto nivel no depende del detalle de bajo nivel, y en los tests se reemplaza el repositorio por un mock.
</details>

---

## 4. Arquitectura en capas (Clean Architecture)

**Qué tenés que saber:** las dependencias apuntan hacia adentro.

```
Api ──► Application ──► Domain
 │            ▲
 └──► Infrastructure (implementa las interfaces de Application)
```

- **Domain:** entidades y reglas. No conoce a nadie.
- **Application:** casos de uso. Define interfaces (`IReservaRepository`) y DTOs.
- **Infrastructure:** EF Core, Identity y servicios externos.
- **Api:** HTTP. Arma la inyección de dependencias y traduce `Result` a códigos de estado.

**Cómo se aplica:** si en `Domain` aparece un `using Microsoft.EntityFrameworkCore`, algo está mal ubicado.

<details><summary>¿No es demasiado para una app chica?</summary>

Puede serlo, y conviene decirlo. Acá se justifica por dos razones: el dominio tiene reglas reales que queremos testear aisladas, y es un proyecto para aprender la estructura que usan muchas empresas .NET. En un proyecto chico real, un monolito con carpetas por feature también es válido.
</details>

---

## 5. TDD

**Qué tenés que saber**

- El ciclo:
  - 🔴 escribir un test que falle
  - 🟢 escribir el mínimo código que lo haga pasar
  - 🔵 refactorizar con los tests en verde
- **Baby steps:** el test más chico posible. Si te cuesta escribir el test, el paso es muy grande.
- El test se escribe pensando en **qué** tiene que pasar, no en cómo se implementa.
- TDD no es "tener tests". Es usar los tests para diseñar el código.

**Cómo se aplica (R4, superposición)**

🔴 Primer test:

```csharp
[Fact]
public void SeSuperponeCon_TurnoQueEmpiezaEnElMedio_DevuelveTrue()
{
    // Arrange: reserva de 18:00 a 19:00
    var reserva = ReservaBuilder.Nueva().De("18:00").A("19:00").Build();

    // Act
    var resultado = reserva.SeSuperponeCon(Hora("18:30"), Hora("19:30"));

    // Assert
    resultado.ShouldBeTrue();
}
```

🟢 La primera implementación puede ser incluso `return true;`. El siguiente test, uno que **no** se superpone, obliga a escribir la condición real.

🔵 Cuando aparecen varios casos parecidos, se refactoriza a un `[Theory]` (ver §6).

<details><summary>¿Qué ventajas tiene TDD? ¿Y desventajas?</summary>

Ventajas: diseño más simple y desacoplado (si algo es difícil de testear, está mal diseñado), cobertura alta casi sin esfuerzo y confianza para refactorizar. Desventajas: al principio es más lento, no sirve igual para todo (UI muy visual, prototipos descartables) y mal hecho produce tests acoplados a la implementación.
</details>

<details><summary>¿Por qué escribir código "feo" en verde?</summary>

Porque el objetivo del paso verde es tener una red de seguridad lo antes posible. Con el test en verde, el refactor es seguro. Si intentás diseñar y hacer pasar el test al mismo tiempo, mezclás dos problemas.
</details>

---

## 6. xUnit y Shouldly

**Qué tenés que saber**

- `[Fact]` es un caso único. `[Theory]` con `[InlineData]` es el mismo test con varios datos.
- xUnit crea una instancia nueva de la clase por cada test: el constructor hace las veces de setup.
- Shouldly da mensajes de error legibles: `precio.ShouldBe(24000m)`.
- Un *Test Data Builder* (`ReservaBuilder`) evita repetir la construcción de objetos en cada test.

**Cómo se aplica (R4 con todos los bordes)**

```csharp
// Reserva existente: 18:00 a 19:00
[Theory]
[InlineData("17:00", "18:00", false)] // termina justo cuando empieza la otra
[InlineData("19:00", "20:00", false)] // empieza justo cuando termina la otra
[InlineData("18:30", "19:30", true)]
[InlineData("17:30", "18:30", true)]
[InlineData("17:00", "20:00", true)]  // la contiene
[InlineData("18:15", "18:45", true)]  // queda adentro
public void SeSuperponeCon_DistintosHorarios(string desde, string hasta, bool esperado)
{
    var reserva = ReservaBuilder.Nueva().De("18:00").A("19:00").Build();

    reserva.SeSuperponeCon(Hora(desde), Hora(hasta)).ShouldBe(esperado);
}
```

<details><summary>¿Qué casos de borde tiene una superposición de horarios?</summary>

Que uno termine exactamente cuando el otro empieza (no se superponen si los intervalos son `[inicio, fin)`), uno contenido en el otro, uno que contiene al otro, superposición parcial por izquierda y por derecha, e intervalos iguales. Nombrarlos en una entrevista muestra que pensás en los bordes.
</details>

---

## 7. Mocks con NSubstitute

**Qué tenés que saber**

| Tipo | Para qué sirve |
|---|---|
| **Stub** | Devuelve datos preparados. |
| **Mock** | Verificás que se lo llamó (o que no). |
| **Fake** | Una implementación simple real, por ejemplo un repositorio en memoria. |

- Se mockean las dependencias externas (repositorio, servicios) y **nunca** la clase que estás testeando.
- No mockees entidades del dominio: usá las reales.

**Cómo se aplica**

```csharp
[Fact]
public async Task Handle_HorarioOcupado_DevuelveErrorYNoGuarda()
{
    // Arrange
    var reservas = Substitute.For<IReservaRepository>();
    reservas.ExisteSuperposicionAsync(CanchaId, Arg.Any<DateTimeOffset>(), Arg.Any<DateTimeOffset>(), Arg.Any<CancellationToken>())
            .Returns(true);
    var tiempo = new FakeTimeProvider(new DateTimeOffset(2026, 11, 2, 12, 0, 0, TimeSpan.Zero));
    var handler = new CrearReservaHandler(reservas, canchasConUnaCancha, tiempo);

    // Act
    var resultado = await handler.Handle(comando, CancellationToken.None);

    // Assert
    resultado.EsExito.ShouldBeFalse();
    resultado.Error.Codigo.ShouldBe("Reserva.HorarioNoDisponible");
    await reservas.DidNotReceive().AgregarAsync(Arg.Any<Reserva>(), Arg.Any<CancellationToken>());
}
```

<details><summary>¿Qué riesgo tiene usar demasiados mocks?</summary>

Los tests terminan verificando cómo está implementado el código y no qué hace. Cualquier refactor los rompe aunque el comportamiento siga igual. Además, un mock puede devolver algo que la implementación real nunca devolvería. Por eso los tests de integración (§13) complementan a los unitarios.
</details>

---

## 8. Manejo del tiempo

**Qué tenés que saber**

- Nunca uses `DateTime.Now` en lógica de negocio: hace que los tests dependan de la hora en que corren.
- .NET 8+ trae `TimeProvider`. En producción se usa `TimeProvider.System`; en los tests, `FakeTimeProvider` (paquete `Microsoft.Extensions.TimeProvider.Testing`), que se puede adelantar a mano.
- Se guarda en **UTC**, en columnas `datetimeoffset` de SQL Server. Guardar todo con offset 0 evita comparaciones raras entre offsets distintos.
- Las reglas que dependen de la hora local (pico, apertura) convierten a la zona del complejo (`America/Argentina/Catamarca`).

**Cómo se aplica (R8 cancelación)**

```csharp
// En el dominio, el "ahora" llega por parámetro
public Result<ResultadoCancelacion> Cancelar(DateTimeOffset ahora)
{
    if (!EstaActiva) return ReservaErrores.NoActiva;

    Estado = EstadoReserva.Cancelada;
    return Inicio - ahora >= TimeSpan.FromHours(24)
        ? ResultadoCancelacion.SenaDevuelta
        : ResultadoCancelacion.SenaPerdida;
}

// En el test
var tiempo = new FakeTimeProvider(inicioReserva.AddHours(-25));
reserva.Cancelar(tiempo.GetUtcNow()).Valor.ShouldBe(ResultadoCancelacion.SenaDevuelta);
tiempo.Advance(TimeSpan.FromHours(2)); // ahora faltan 23 h
```

<details><summary>¿Cómo testearías algo que depende de la hora actual?</summary>

Inyectando el reloj como dependencia (`TimeProvider`) en lugar de leerlo directamente. En el test uso un reloj falso fijado en el momento que necesito y lo adelanto para simular el paso del tiempo. Así el test da siempre el mismo resultado, sin importar cuándo se corra.
</details>

---

## 9. EF Core

**Qué tenés que saber**

- Las configuraciones van en clases `IEntityTypeConfiguration<T>`, no en atributos sobre el dominio.
- Las migraciones son código versionado. Revisá siempre el SQL que generan.
- Para consultas de solo lectura: `AsNoTracking()` y proyección con `Select` a DTOs.
- **Problema N+1:** traer una lista y después consultar una relación por cada elemento. Se soluciona con `Include` o con una proyección.
- Con propiedades `private set`, EF necesita un constructor privado y mapea por campos.

**Cómo se aplica**

```csharp
public sealed class ReservaConfig : IEntityTypeConfiguration<Reserva>
{
    public void Configure(EntityTypeBuilder<Reserva> b)
    {
        b.ToTable("Reservas");
        b.HasKey(r => r.Id);
        b.Property(r => r.Precio).HasPrecision(12, 2);
        b.Property(r => r.Sena).HasPrecision(12, 2);
        b.HasIndex(r => new { r.CanchaId, r.Inicio });
    }
}

// Disponibilidad: solo lectura, proyección directa
var ocupados = await db.Reservas
    .AsNoTracking()
    .Where(r => r.CanchaId == canchaId && r.Inicio < finDia && r.Fin > inicioDia
             && (r.Estado == EstadoReserva.PendienteSena || r.Estado == EstadoReserva.Confirmada))
    .Select(r => new { r.Inicio, r.Fin })
    .ToListAsync(ct);
```

<details><summary>¿Qué es el change tracker y cuándo conviene AsNoTracking?</summary>

El change tracker guarda una copia de cada entidad que cargás para detectar cambios al llamar a `SaveChanges`. Tiene costo de memoria y CPU. Si solo vas a leer y mostrar (por ejemplo, la grilla de disponibilidad), `AsNoTracking` lo evita.
</details>

---

## 10. SQL Server y concurrencia

**Qué tenés que saber**

- Validar "no hay superposición" en el código **no alcanza**. Dos requests simultáneos pueden consultar al mismo tiempo, ver el turno libre y guardar los dos. Es una *race condition*.
- La solución es que **la base** rechace el segundo. SQL Server (y Azure SQL) no tiene restricciones de rangos como Postgres, así que se **discretiza el tiempo**:
  - cada reserva ocupa bloques de 30 minutos (*slots*)
  - esos bloques se guardan en `TurnosOcupados` con clave única `(CanchaId, SlotInicio)`
  - dos reservas que compartan un bloque chocan contra la clave
  - los bloqueos de mantenimiento también ocupan slots
- Un duplicado devuelve el error **2627** (PK o unique constraint) o el **2601** (índice único). Se captura y se traduce a 409 Conflict.
- Alternativa clásica: una transacción con `WITH (UPDLOCK, HOLDLOCK)` sobre la consulta de superposición. Funciona, pero bloquea más y es fácil equivocarse. Conviene saber explicarla.
- **Concurrencia optimista** para editar una misma fila: una columna `rowversion` que SQL Server cambia sola en cada update. EF la incluye en el `WHERE` del update y lanza `DbUpdateConcurrencyException` si alguien la modificó antes.

**Cómo se aplica**

Dominio (con TDD, Etapa 2):

```csharp
public IEnumerable<DateTimeOffset> Slots()
{
    for (var t = Inicio; t < Fin; t = t.AddMinutes(30))
        yield return t;
}

[Fact]
public void Slots_ReservaDe90Minutos_OcupaTresBloques()
{
    var reserva = ReservaBuilder.Nueva().De("18:00").A("19:30").Build();

    reserva.Slots().ShouldBe([Hora("18:00"), Hora("18:30"), Hora("19:00")]);
}
```

EF Core (Etapa 3):

```csharp
public sealed class TurnoOcupadoConfig : IEntityTypeConfiguration<TurnoOcupado>
{
    public void Configure(EntityTypeBuilder<TurnoOcupado> b)
    {
        b.ToTable("TurnosOcupados");
        b.HasKey(t => new { t.CanchaId, t.SlotInicio }); // la clave ES la regla R4
    }
}

// En ReservaConfig
b.Property<byte[]>("Version").IsRowVersion();
```

Repositorio:

```csharp
catch (DbUpdateException ex) when (ex.InnerException is SqlException { Number: 2627 or 2601 })
{
    return ReservaErrores.HorarioNoDisponible;
}
```

<details><summary>Dos usuarios reservan el mismo turno al mismo tiempo. ¿Qué pasa en tu sistema?</summary>

Los dos pasan la validación en el código, porque consultan antes de que el otro guarde. Pero cada reserva inserta sus bloques de 30 minutos en `TurnosOcupados`, que tiene clave única por cancha y horario. El primero que llega gana; el segundo recibe el error 2627 dentro de la misma transacción, se hace rollback y la API responde 409 "Horario no disponible". Hay un test de integración que lo comprueba disparando los dos requests en paralelo.
</details>

<details><summary>¿Por qué slots de 30 minutos y no guardar solo inicio y fin?</summary>

Porque una clave única compara valores iguales, no rangos. Al partir el tiempo en bloques fijos, "se superponen" pasa a ser "comparten un bloque", y eso sí lo puede garantizar la clave primaria compuesta `(CanchaId, SlotInicio)`. Funciona porque los turnos siempre empiezan en la grilla de 30 minutos (R2). En Postgres existiría una alternativa nativa: las exclusion constraints con rangos.
</details>

<details><summary>¿Concurrencia optimista vs pesimista?</summary>

La pesimista bloquea el registro mientras lo usás (`UPDLOCK`, `HOLDLOCK` o `SELECT ... FOR UPDATE` en otros motores): es segura, pero reduce el rendimiento y puede generar deadlocks. La optimista no bloquea: al guardar verifica que la versión (`rowversion`) no haya cambiado, y si cambió, falla y se reintenta o se avisa. La optimista es la opción habitual en aplicaciones web.
</details>

---

## 11. Result pattern

**Qué tenés que saber:** los errores de negocio esperables (horario ocupado, reserva ya cancelada) no son excepciones. Se devuelven como resultado. Las excepciones quedan para lo inesperado, como que se caiga la base.

**Cómo se aplica**

```csharp
public enum TipoError { Validacion, NoEncontrado, Conflicto, Prohibido }
public sealed record Error(string Codigo, string Mensaje, TipoError Tipo);

public sealed class Result<T>
{
    public T? Valor { get; }
    public Error? Error { get; }
    public bool EsExito => Error is null;

    private Result(T? valor, Error? error) { Valor = valor; Error = error; }

    public static implicit operator Result<T>(T valor) => new(valor, null);
    public static implicit operator Result<T>(Error error) => new(default, error);
}

public static class ReservaErrores
{
    public static readonly Error HorarioNoDisponible =
        new("Reserva.HorarioNoDisponible", "Ese horario ya está reservado.", TipoError.Conflicto);
}
```

<details><summary>¿Por qué no lanzar una excepción y listo?</summary>

Las excepciones son caras, cortan el flujo y no aparecen en la firma del método: quien llama no sabe qué errores esperar. Con `Result`, el error es parte del contrato, el compilador obliga a manejarlo y el test lo verifica sin `try/catch`.
</details>

---

## 12. ASP.NET Core Web API

**Qué tenés que saber**

- **Lifetimes de inyección de dependencias:**

  | Lifetime | Cuánto vive | Ejemplo en el proyecto |
  |---|---|---|
  | Singleton | Uno para toda la app | `TimeProvider` |
  | Scoped | Uno por request | `DbContext`, handlers |
  | Transient | Uno nuevo cada vez | Servicios livianos sin estado |

- **Códigos de estado:** 200 OK, 201 Created, 204 No Content, 400 Bad Request, 401 Unauthorized, 403 Forbidden, 404 Not Found, 409 Conflict.
- **ProblemDetails:** formato estándar (RFC 9457) para errores HTTP.
- **Validación:** FluentValidation para el formato del request; el dominio valida las reglas de negocio.
- **OpenAPI:** desde .NET 9 se genera con `Microsoft.AspNetCore.OpenApi` y se visualiza con Scalar, que reemplaza a Swagger UI.

**Cómo se aplica**

```csharp
[HttpPost]
public async Task<IActionResult> Crear(CrearReservaRequest request, CancellationToken ct)
{
    var resultado = await handler.Handle(request.ToCommand(User.GetId()), ct);

    return resultado.EsExito
        ? CreatedAtAction(nameof(Obtener), new { id = resultado.Valor!.Id }, resultado.Valor)
        : Problem(
            title: resultado.Error!.Mensaje,
            statusCode: resultado.Error.Tipo switch
            {
                TipoError.NoEncontrado => 404,
                TipoError.Conflicto => 409,
                TipoError.Prohibido => 403,
                _ => 400
            });
}
```

<details><summary>¿Qué pasa si inyectás un servicio Scoped dentro de un Singleton?</summary>

El servicio Scoped queda "capturado" y vive para siempre, compartido entre requests. Con un `DbContext`, eso provoca errores de concurrencia y datos viejos. ASP.NET Core lo detecta en desarrollo y lanza una excepción al arrancar.
</details>

<details><summary>¿400 o 409 para "el horario está ocupado"?</summary>

409 Conflict: el request está bien formado, pero choca con el estado actual del recurso. 400 es para requests mal formados o inválidos en sí mismos, por ejemplo una fecha con formato incorrecto.
</details>

---

## 13. Tests de integración

**Qué tenés que saber**

- `WebApplicationFactory<Program>` levanta la API en memoria y te da un `HttpClient`.
- Testcontainers crea un SQL Server real en Docker solo para los tests.
- Respawn borra los datos entre test y test sin recrear la base.
- Prueban lo que los unitarios no: el mapeo de EF, las migraciones, la serialización, la autenticación y la clave única de `TurnosOcupados`.

**Cómo se aplica**

```csharp
public sealed class ApiFactory : WebApplicationFactory<Program>, IAsyncLifetime
{
    private readonly MsSqlContainer _db = new MsSqlBuilder()
        .WithImage("mcr.microsoft.com/mssql/server:2022-latest").Build();

    protected override void ConfigureWebHost(IWebHostBuilder builder) =>
        builder.UseSetting("ConnectionStrings:Default", _db.GetConnectionString());

    public async ValueTask InitializeAsync() => await _db.StartAsync(); // xUnit v3 usa ValueTask

    public override async ValueTask DisposeAsync()
    {
        await _db.DisposeAsync();
        await base.DisposeAsync();
    }
}
```

Para que la factory encuentre la API, en `Program.cs` hay que agregar `public partial class Program { }`.

```csharp
[Fact]
public async Task Post_DosReservasSimultaneasMismoTurno_UnaCreadaYOtraConflicto()
{
    var request = new { canchaId, inicio = "2026-11-03T21:00:00Z" };

    var respuestas = await Task.WhenAll(
        clienteA.PostAsJsonAsync("/api/reservas", request),
        clienteB.PostAsJsonAsync("/api/reservas", request));

    respuestas.Select(r => r.StatusCode).ShouldBe(
        [HttpStatusCode.Created, HttpStatusCode.Conflict], ignoreOrder: true);
}
```

<details><summary>¿Por qué no usar una base en memoria (InMemory o SQLite) para los tests?</summary>

Porque no se comporta como SQL Server. El proveedor InMemory de EF ni siquiera respeta claves únicas, así que el test de concurrencia pasaría aunque la protección no exista. SQLite traduce consultas y tipos de fecha distinto. El test pasa y producción falla. Con Testcontainers, el test usa el mismo motor que Azure SQL.
</details>

---

## 14. BDD con Gherkin y Reqnroll

**Qué tenés que saber**

- BDD (Behavior-Driven Development) parte de conversaciones con negocio. Los ejemplos concretos se escriben en Gherkin y se convierten en tests ejecutables.
- Estructura: `Dado` (contexto), `Cuando` (acción), `Entonces` (resultado esperado).
- Gherkin funciona en español con `# language: es`. Las palabras clave son `Característica`, `Antecedentes`, `Escenario`, `Esquema del escenario`, `Ejemplos`, `Dado`, `Cuando`, `Entonces`, `Y` y `Pero`.
- Reqnroll es el sucesor open source de SpecFlow, que dejó de mantenerse.
- TDD guía el diseño desde adentro (el código). BDD guía desde afuera (el comportamiento que espera el usuario). Se complementan.

**Cómo se aplica (`docs/features/cancelar.feature`)**

```gherkin
# language: es
Característica: Cancelar una reserva
  Como jugador
  Quiero cancelar una reserva
  Para liberar el turno si no puedo ir

  Esquema del escenario: La seña depende de la anticipación
    Dado que tengo una reserva confirmada para el sábado a las 20:00
    Y faltan <horas> horas para el turno
    Cuando cancelo la reserva
    Entonces la seña es <resultado>

    Ejemplos:
      | horas | resultado |
      | 48    | devuelta  |
      | 24    | devuelta  |
      | 23    | perdida   |
      | 1     | perdida   |
```

```csharp
[Binding]
public sealed class CancelarSteps(ContextoReserva ctx)
{
    [Given("faltan {int} horas para el turno")]
    public void FaltanHoras(int horas) =>
        ctx.Tiempo.SetUtcNow(ctx.Reserva.Inicio.AddHours(-horas));

    [When("cancelo la reserva")]
    public void Cancelo() => ctx.Resultado = ctx.Reserva.Cancelar(ctx.Tiempo.GetUtcNow());

    [Then("la seña es {word}")]
    public void LaSenaEs(string esperado) =>
        ctx.Resultado.Valor.ShouldBe(esperado == "devuelta"
            ? ResultadoCancelacion.SenaDevuelta
            : ResultadoCancelacion.SenaPerdida);
}
```

<details><summary>¿Diferencia entre TDD y BDD?</summary>

TDD es una técnica de desarrollo: escribo un test unitario que falla y después el código, en ciclos cortos. Lo usa el desarrollador para diseñar. BDD es una práctica de equipo: se acuerdan ejemplos de comportamiento con negocio en lenguaje natural (Gherkin), y esos ejemplos se automatizan. Uno puede usar TDD para implementar lo que pide un escenario BDD.
</details>

<details><summary>¿Qué hace bueno a un escenario?</summary>

Describe comportamiento y no la interfaz ("cancelo la reserva", no "hago clic en el botón rojo"). Tiene un solo `Cuando`, se entiende sin leer el código y usa datos concretos.
</details>

---

## 15. Seguridad

**Qué tenés que saber**

- **Autenticación** responde quién sos (login → JWT). **Autorización** responde qué podés hacer (roles y políticas).
- Un JWT está firmado, no cifrado: cualquiera puede leer su contenido. Nunca pongas datos sensibles adentro.
- 401: no estás autenticado. 403: estás autenticado pero no tenés permiso.
- **Autorización por recurso:** el rol "Dueño" no alcanza. Además, el complejo tiene que ser suyo (R10). Eso se verifica en el handler.
- Los secretos (clave de firma del JWT, connection string) van en user-secrets o variables de entorno, nunca en el repo.

**Cómo se aplica**

```csharp
builder.Services.AddAuthorizationBuilder()
    .AddPolicy(Politicas.SoloDuenos, p => p.RequireRole(Roles.Dueno));

// En ConfirmarSenaHandler (R10)
if (complejo.DuenoId != comando.UsuarioId)
    return ReservaErrores.NoEsDuenoDelComplejo; // TipoError.Prohibido → 403
```

<details><summary>¿Dónde guardás el JWT en el front y qué riesgos hay?</summary>

En `localStorage` es simple, pero queda expuesto a XSS: un script inyectado lo puede leer. En una cookie HttpOnly no lo lee JavaScript, pero hay que cuidarse de CSRF (SameSite, tokens anti-CSRF). Para un proyecto de aprendizaje, `localStorage` con tokens de vida corta es aceptable si sabés explicar el trade-off.
</details>

---

## 16. React con TypeScript

**Qué tenés que saber** (comparando con Angular)

| Angular | React |
|---|---|
| Componente con `@Input` | Componente con props tipadas |
| Servicio inyectable con estado | Custom hook o Context |
| `*ngFor` / `@for` | `.map()` con `key` |
| Router de Angular | React Router |
| HttpClient + RxJS | `fetch` + TanStack Query |

- La UI se deriva del estado. No hace falta guardar en el estado algo que se puede calcular.
- `useEffect` no es para pedir datos (de eso se encarga TanStack Query) ni para calcular valores derivados.

**Cómo se aplica**

```tsx
type EstadoTurno = 'libre' | 'ocupado' | 'pendiente' | 'bloqueado';
type Turno = { hora: string; estado: EstadoTurno; precio?: number };

type Props = { turnos: Turno[]; onElegir: (hora: string) => void };

export function GrillaTurnos({ turnos, onElegir }: Props) {
  return (
    <ul className="grid grid-cols-3 gap-2 sm:grid-cols-6">
      {turnos.map(t => (
        <li key={t.hora}>
          <BotonTurno turno={t} onElegir={onElegir} />
        </li>
      ))}
    </ul>
  );
}
```

<details><summary>¿Para qué sirve la `key` en una lista?</summary>

React la usa para identificar cada elemento entre renders y saber cuál se agregó, se movió o se borró. Si usás el índice y la lista cambia de orden, React puede mezclar el estado entre elementos. Tiene que ser estable y única, como `t.hora` o un id.
</details>

---

## 17. TanStack Query

**Qué tenés que saber**

- **Estado del servidor ≠ estado de la UI.** TanStack Query maneja el del servidor: caché, carga, errores y reintentos.
- `queryKey` identifica los datos. Cuando algo cambia, se invalida la key y se vuelven a pedir.
- `useMutation` sirve para escribir (POST, PUT, DELETE).

**Cómo se aplica**

```ts
export function useDisponibilidad(canchaId: string, fecha: string) {
  return useQuery({
    queryKey: ['disponibilidad', canchaId, fecha],
    queryFn: () => api.get<Turno[]>(`/canchas/${canchaId}/disponibilidad?fecha=${fecha}`),
  });
}

export function useCrearReserva() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (datos: NuevaReserva) => api.post<Reserva>('/reservas', datos),
    onSuccess: (_, datos) =>
      queryClient.invalidateQueries({ queryKey: ['disponibilidad', datos.canchaId] }),
  });
}
```

<details><summary>¿Por qué no hacer fetch en un useEffect?</summary>

Tenés que manejar a mano la carga, los errores, la cancelación, las race conditions (llega primero la respuesta vieja), el caché y la revalidación. TanStack Query ya resuelve todo eso, y la propia documentación de React recomienda usar una librería para pedir datos.
</details>

---

## 18. Formularios con React Hook Form + Zod

**Qué tenés que saber:** Zod define el esquema y de él se obtiene el tipo de TypeScript. React Hook Form maneja el formulario sin re-renderizar en cada tecla.

**Cómo se aplica**

```ts
const loginSchema = z.object({
  email: z.string().email('Ingresá un email válido'),
  password: z.string().min(8, 'Mínimo 8 caracteres'),
});
type LoginForm = z.infer<typeof loginSchema>;

const { register, handleSubmit, formState: { errors, isSubmitting } } =
  useForm<LoginForm>({ resolver: zodResolver(loginSchema) });
```

<details><summary>Si validás en el front, ¿hace falta validar en el back?</summary>

Sí, siempre. La validación del front es para la experiencia de usuario; la del back es la seguridad. Cualquiera puede llamar a la API directamente sin pasar por el formulario.
</details>

---

## 19. UX/UI y accesibilidad

**Qué tenés que saber**

- **Mobile-first:** la mayoría va a reservar desde el celular.
- **Jerarquía visual:** lo más importante (hora, estado) se ve primero; lo secundario (precio) después.
- **El color nunca es la única señal:** un turno ocupado se distingue también por texto o ícono y por estar deshabilitado. Así lo entiende alguien daltónico o con lector de pantalla.
- **Feedback:** cada acción muestra carga, éxito o error. Los estados vacíos explican qué hacer ("No hay turnos libres este día. Probá con otra fecha").
- **Accesibilidad:** HTML semántico (`button`, `ul`, `label`), etiquetas descriptivas, foco visible, contraste AA y uso completo con teclado.
- **Heurísticas de Nielsen** más aplicadas acá:
  - visibilidad del estado del sistema
  - prevención de errores (avisar que la seña se pierde **antes** de cancelar)
  - reconocimiento antes que recuerdo

**Cómo se aplica**

```tsx
const etiqueta: Record<EstadoTurno, string> = {
  libre: 'libre', ocupado: 'ocupado', pendiente: 'pendiente de seña', bloqueado: 'no disponible',
};

<button
  type="button"
  disabled={turno.estado !== 'libre'}
  aria-label={`${turno.hora}, ${etiqueta[turno.estado]}${turno.precio ? `, $${turno.precio}` : ''}`}
  onClick={() => onElegir(turno.hora)}
  className="... focus-visible:ring-2 disabled:cursor-not-allowed"
>
  <span className="font-semibold">{turno.hora}</span>
  <span className="text-xs">{etiqueta[turno.estado]}</span>
</button>
```

<details><summary>¿Cómo comprobás que tu app es accesible?</summary>

Recorriéndola solo con el teclado (Tab, Enter, Escape), pasando Lighthouse o axe DevTools, revisando el contraste y escuchando al menos una pantalla con el lector de pantalla del sistema (NVDA o VoiceOver). Además, los tests con Testing Library buscan elementos por rol y nombre: si un test no encuentra el botón por su nombre, probablemente un lector de pantalla tampoco.
</details>

---

## 20. Testing en React

**Qué tenés que saber**

- Se testea lo que ve y hace el usuario, no el estado interno ni los detalles de implementación.
- **Prioridad de queries:** `getByRole` > `getByLabelText` > `getByText` > `getByTestId` (este último, como último recurso).
- `user-event` simula interacciones reales: clics y tipeo.
- MSW intercepta las llamadas HTTP y devuelve respuestas falsas. Así se testean componentes con datos reales sin backend.

**Cómo se aplica**

```tsx
test('un turno ocupado no se puede elegir', () => {
  render(<GrillaTurnos turnos={[{ hora: '18:00', estado: 'ocupado' }]} onElegir={vi.fn()} />);

  expect(screen.getByRole('button', { name: /18:00, ocupado/i })).toBeDisabled();
});

test('al elegir un turno libre avisa la hora', async () => {
  const onElegir = vi.fn();
  const user = userEvent.setup();
  render(<GrillaTurnos turnos={[{ hora: '19:30', estado: 'libre', precio: 24000 }]} onElegir={onElegir} />);

  await user.click(screen.getByRole('button', { name: /19:30, libre/i }));

  expect(onElegir).toHaveBeenCalledWith('19:30');
});
```

```ts
// MSW: el turno se ocupó mientras el usuario decidía
http.post('/api/reservas', () =>
  HttpResponse.json({ title: 'Ese horario ya está reservado.' }, { status: 409 }));
```

<details><summary>¿Por qué evitar getByTestId?</summary>

Porque el usuario no ve los `data-testid`. Si buscás por rol y nombre, el test además verifica que el elemento sea accesible, y no se rompe si cambiás la estructura del HTML.
</details>

---

## 21. E2E con Playwright

**Qué tenés que saber:** los tests E2E son pocos, lentos y valiosos. Cubren los flujos que, si se rompen, hacen que la app no sirva. Playwright espera solo a que los elementos estén listos, sin `sleep`.

**Cómo se aplica**

```ts
test('un jugador reserva un turno libre', async ({ page }) => {
  await loginComo(page, 'jugador@demo.com');
  await page.getByRole('link', { name: 'Reservar' }).click();
  await page.getByRole('button', { name: /19:30, libre/ }).click();
  await page.getByRole('button', { name: 'Confirmar reserva' }).click();

  await expect(page.getByText('Pendiente de seña')).toBeVisible();
});
```

<details><summary>¿Por qué no hacer todo con E2E si prueban la app completa?</summary>

Son lentos, más frágiles y cuando fallan cuesta encontrar la causa. La pirámide propone muchos unitarios (rápidos y precisos), una capa media de integración y pocos E2E para los flujos críticos.
</details>

---

## 22. Docker

**Qué tenés que saber**

- **Imagen vs contenedor:** la imagen es la plantilla, de solo lectura (como una clase); el contenedor es una instancia corriendo de esa imagen (como un objeto). De una imagen salen muchos contenedores.
- **Capas y caché:** cada instrucción del Dockerfile crea una capa. Si una capa no cambió, Docker la reutiliza. Por eso primero se copian los `.csproj` o el `package.json` y se restauran dependencias, y recién después se copia el código: cambiar código no obliga a descargar paquetes de nuevo.
- **Instrucciones principales:**

  | Instrucción | Qué hace |
  |---|---|
  | `FROM` | Imagen base |
  | `WORKDIR` | Carpeta de trabajo |
  | `COPY` | Copia archivos al contenedor |
  | `RUN` | Ejecuta un comando al **construir** |
  | `ENV` | Variable de entorno |
  | `ARG` | Variable solo de build |
  | `EXPOSE` | Documenta el puerto |
  | `USER` | Usuario con el que corre |
  | `ENTRYPOINT` / `CMD` | Qué se ejecuta al **arrancar** |

- **Multi-stage build:** se compila en una etapa con el SDK, que es pesado, y se copia solo el resultado a una imagen de runtime liviana. La imagen final no tiene compilador ni código fuente.
- **`.dockerignore`:** evita mandar a Docker `bin/`, `obj/`, `node_modules/` y archivos `.env`. El build es más rápido y no se filtran secretos.
- **Volúmenes:** los datos de un contenedor se pierden al borrarlo. Un volumen los guarda afuera; por eso la base usa `sqldata`.
- **Redes:** en Docker Compose todos los servicios comparten una red y se encuentran **por nombre**. La API se conecta a `sql,1433`, no a `localhost`: dentro del contenedor de la API, `localhost` es la API misma.
- **Puertos:** `"5000:8080"` significa puerto 5000 de tu PC → puerto 8080 del contenedor. Desde .NET 8, las imágenes de ASP.NET escuchan en 8080 por defecto.
- **Healthcheck y `depends_on`:** `depends_on` solo espera a que el otro contenedor *arranque*. Con `condition: service_healthy`, espera a que esté *listo*, por ejemplo a que SQL Server acepte conexiones.
- **Registro:** donde se publican imágenes (Docker Hub, GitHub Container Registry, Azure Container Registry). Los tags identifican versiones; conviene no depender solo de `latest`.
- **Seguridad:** correr con usuario no root, no meter secretos en la imagen (se pasan como variables al correr) y usar imágenes base oficiales.

**Comandos que hay que manejar**

```bash
docker build -t fulbito-api ./backend           # construir una imagen
docker images                                   # listar imágenes y tamaños
docker run -d -p 5000:8080 --name api fulbito-api
docker ps / docker ps -a                        # contenedores corriendo / todos
docker logs -f api                              # ver logs
docker exec -it api sh                          # entrar a un contenedor
docker stop api && docker rm api
docker compose up --build / down / down -v      # -v borra también los volúmenes
docker system prune                             # limpiar lo que no se usa
```

**Cómo se aplica: `backend/Dockerfile`**

```dockerfile
# Etapa 1: compilar con el SDK
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Primero solo los .csproj → esta capa se cachea mientras no cambien las dependencias
COPY src/Fulbito.Domain/*.csproj         src/Fulbito.Domain/
COPY src/Fulbito.Application/*.csproj    src/Fulbito.Application/
COPY src/Fulbito.Infrastructure/*.csproj src/Fulbito.Infrastructure/
COPY src/Fulbito.Api/*.csproj            src/Fulbito.Api/
RUN dotnet restore src/Fulbito.Api/Fulbito.Api.csproj

# Después el código
COPY src/ src/
RUN dotnet publish src/Fulbito.Api -c Release -o /app --no-restore

# Etapa 2: imagen final, solo runtime
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app .
# Usuario no root que ya trae la imagen oficial
# (en un Dockerfile los comentarios van en su propia línea)
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "Fulbito.Api.dll"]
```

**`docker-compose.yml` de la app completa** (desde la Etapa 6)

```yaml
services:
  sql:
    image: mcr.microsoft.com/mssql/server:2022-latest
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: ${SQL_PASSWORD}          # viene del archivo .env
    ports: ["1433:1433"]
    volumes: [sqldata:/var/opt/mssql]
    healthcheck:
      test: /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" -b
      interval: 10s
      retries: 10
      start_period: 20s

  api:
    build: ./backend
    environment:
      ASPNETCORE_ENVIRONMENT: Development
      ConnectionStrings__Default: "Server=sql,1433;Database=fulbito;User Id=sa;Password=${SQL_PASSWORD};TrustServerCertificate=True"
    ports: ["5000:8080"]
    depends_on:
      sql: { condition: service_healthy }

  web:
    build:
      context: ./frontend
      args: { VITE_API_URL: "http://localhost:5000" }  # la usa el navegador, por eso localhost
    ports: ["3000:80"]
    depends_on: [api]

volumes:
  sqldata:
```

**`frontend/Dockerfile`** (el "tu turno" de la Etapa 6)

```dockerfile
FROM node:22-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
RUN npm run build

FROM nginx:alpine
# nginx.conf lleva try_files $uri /index.html para que funcionen las rutas de React Router
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html
```

**CI/CD en una línea cada concepto**

- **CI:** cada push o PR corre build y tests.
- **Entrega continua:** siempre queda listo para desplegar, con un botón.
- **Despliegue continuo:** se despliega solo.
- **Build once, deploy many:** la misma imagen que pasó los tests es la que llega a producción. El pipeline está en §25.

<details><summary>¿Diferencia entre imagen y contenedor?</summary>

La imagen es un paquete inmutable con el sistema base, las dependencias y la app compilada. El contenedor es un proceso aislado que corre a partir de esa imagen, con su propia capa de escritura encima. Podés tener varios contenedores de la misma imagen, y borrar un contenedor no borra la imagen.
</details>

<details><summary>¿Para qué sirve un multi-stage build?</summary>

Para separar compilar de ejecutar. La etapa de build tiene el SDK y el código; la final solo tiene el runtime y los binarios publicados. La imagen final pesa varias veces menos, arranca más rápido y tiene menos superficie de ataque, porque no incluye compilador ni fuentes.
</details>

<details><summary>¿Por qué se copian primero los .csproj y después el resto del código?</summary>

Por la caché de capas. El restore de NuGet es lento y solo cambia cuando cambian las dependencias. Si los `.csproj` no cambiaron, Docker reutiliza la capa del restore y solo recompila el código.
</details>

<details><summary>La API en Docker no se conecta a la base con `localhost`. ¿Por qué?</summary>

Porque dentro del contenedor, `localhost` es el propio contenedor de la API, no tu PC ni el de SQL Server. En Compose, los servicios están en la misma red y se resuelven por nombre, así que la connection string usa `Server=sql,1433`.
</details>

<details><summary>¿Docker vs máquina virtual?</summary>

Una VM virtualiza el hardware y corre un sistema operativo completo, con su kernel. Un contenedor comparte el kernel del host y solo aísla procesos, archivos y red. Es mucho más liviano y arranca en segundos, a cambio de un aislamiento menor que el de una VM.
</details>

<details><summary>¿Cómo manejás los secretos con Docker?</summary>

Nunca dentro de la imagen: cualquiera que tenga la imagen puede leerlos. Se pasan al correr el contenedor. En local, con un archivo `.env` ignorado por Git más un `.env.example` versionado. En Azure, con la configuración del App Service, Key Vault y Managed Identity.
</details>

---

## 23. Extras

- **BackgroundService (R7):** la lógica "liberar señas vencidas" va en un método testeable que recibe el `ahora`. El servicio solo lo llama cada minuto con `PeriodicTimer`. Como el servicio es Singleton, el `DbContext` se obtiene con `IServiceScopeFactory`.
- **Azure Function con Timer Trigger:** la misma lógica, pero fuera de la API (`[TimerTrigger("0 */1 * * * *")]`). Ventaja: no depende de que el App Service esté despierto.
- **Bicep:** infraestructura como código. Un archivo describe el resource group completo y el pipeline lo despliega, así el entorno se recrea igual siempre.
- **SignalR:** cuando se crea una reserva, el servidor avisa al grupo `cancha-{id}-{fecha}` y la grilla invalida su query.
- **Turnos fijos:** una regla nueva ideal para practicar TDD de punta a punta sin ayuda.
- **IA:** `Microsoft.Extensions.AI` con *tool calling*. El modelo no inventa disponibilidad: llama a tu `ObtenerDisponibilidadHandler`.

<details><summary>¿Por qué no se puede inyectar el DbContext directo en un BackgroundService?</summary>

El BackgroundService vive toda la aplicación (Singleton) y el DbContext es Scoped. Hay que crear un scope en cada ejecución con `IServiceScopeFactory`, obtener el DbContext de ese scope y liberarlo al terminar.
</details>

---

## 24. Azure: servicios del proyecto

**Qué tenés que saber**

- **Jerarquía:** suscripción (donde se factura) → *resource group* (carpeta lógica, se borra todo junto) → recursos.
- **IaaS, PaaS y SaaS:** todo lo que usamos es PaaS. Azure administra el servidor y vos solo subís la app.
- **Servicios que usa el proyecto:**

  | Servicio | Para qué | Equivale a lo que ya usaste | Tier sugerido |
  |---|---|---|---|
  | App Service (Linux, contenedor) | Correr la imagen Docker de la API | Render | F1 (gratis) o B1 |
  | Static Web Apps | Hostear el front React | Vercel | Free |
  | Azure SQL Database | La base | Supabase, pero SQL Server | Oferta gratuita serverless |
  | Key Vault | Secretos (clave del JWT) | Variables de entorno de Render | Standard (centavos) |
  | Managed Identity | Que la API se autentique sin contraseñas | — | Gratis |
  | Application Insights | Logs, errores, métricas, disponibilidad | UptimeRobot + logs de Render | Capa gratuita mensual |
  | Functions (extra) | Tareas programadas (liberar señas) | Cron | Consumo |

- **Los tiers gratuitos tienen límites.** El F1 de App Service tiene cuota diaria de CPU y no tiene *Always On*. Azure SQL serverless se pausa solo, y la primera request después de la pausa tarda, igual que Supabase gratis. Los límites cambian: verificalos en la calculadora de precios y **creá la alerta de presupuesto antes de crear cualquier recurso**.
- **Managed Identity:** Azure le da una identidad a tu App Service. Con ella se conecta a Azure SQL y a Key Vault, y no hay contraseñas en ningún archivo ni variable.
- **`DefaultAzureCredential`** prueba varias formas de autenticarse en orden: en Azure usa la Managed Identity y en tu PC usa tu sesión de `az login` o de Visual Studio. El mismo código funciona en los dos lados.

**Cómo se aplica**

Connection string de producción, **sin contraseña** (se configura en el App Service):

```
Server=tcp:sql-fulbito.database.windows.net,1433;Database=fulbito;Authentication=Active Directory Default;Encrypt=True;
```

Permisos mínimos en Azure SQL para la identidad de la API (se ejecuta una vez, como admin de Entra):

```sql
CREATE USER [app-fulbito-api] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [app-fulbito-api];
ALTER ROLE db_datawriter ADD MEMBER [app-fulbito-api];
-- Las migraciones las corre el pipeline con otra identidad que sí tiene db_ddladmin
```

`Program.cs`:

```csharp
builder.Services.AddDbContext<AppDbContext>(o =>
    o.UseSqlServer(builder.Configuration.GetConnectionString("Default"),
                   sql => sql.EnableRetryOnFailure())); // reintenta errores transitorios de la nube

builder.Services.AddOpenTelemetry().UseAzureMonitor(); // Application Insights
```

Secretos con **Key Vault references**: en la configuración del App Service, la variable `Jwt__Clave` toma el valor `@Microsoft.KeyVault(SecretUri=https://kv-fulbito.vault.azure.net/secrets/jwt-clave/)`. El código sigue leyendo `builder.Configuration["Jwt:Clave"]` como siempre.

<details><summary>¿Qué es una Managed Identity y por qué es mejor que una contraseña en la connection string?</summary>

Es una identidad que Azure le asigna a un recurso, como el App Service, y que Azure rota y administra. La app pide tokens a Azure en lugar de usar una contraseña. No hay secreto que se pueda filtrar en el repo, en los logs o en una captura, no hay que rotarlo a mano y los permisos se dan con roles específicos.
</details>

<details><summary>¿Por qué `EnableRetryOnFailure` en Azure SQL?</summary>

En la nube hay errores transitorios: un failover, la base despertando de la pausa serverless, un corte de red breve. Reintentar con espera progresiva los resuelve sin que el usuario lo note. Ojo: con reintentos activados, las transacciones manuales tienen que ir dentro de una *execution strategy*.
</details>

<details><summary>¿Por qué la primera request del día tarda varios segundos?</summary>

Por dos *cold starts*: el App Service F1 se descarga si no tiene uso, y Azure SQL serverless se pausa por inactividad. Se mitiga con un tier pago con Always On y SQL provisionado, o aceptándolo en un proyecto de portfolio y explicándolo en el README.
</details>

---

## 25. Azure DevOps: Boards y Pipelines

**Qué tenés que saber**

- **Azure Boards**
  - Jerarquía (proceso Agile): Epic → Feature → User Story → Task. En el proceso Scrum, el User Story se llama *Product Backlog Item*.
  - **Sprints:** iteraciones de 2 semanas. Se planifica qué historias entran y se estima en *story points*.
  - **Definition of Done** del proyecto: tests en verde, PR aprobado, pipeline pasando y `PROGRESO.md` actualizado.
  - Escribir `AB#123` en un commit o PR de GitHub lo vincula al work item.
- **Repos:** el código queda en GitHub para que sea visible en el portfolio. Azure Pipelines y Boards funcionan igual conectados a GitHub.
- **Azure Pipelines, conceptos**

  | Concepto | Qué es |
  |---|---|
  | `trigger` / `pr` | Cuándo corre el pipeline |
  | Stage | Etapa grande (CI, Deploy) |
  | Job | Corre en un agente |
  | Step / task | Un paso concreto |
  | Agente | Microsoft-hosted o self-hosted (tu PC) |
  | Artefacto | Lo compilado que pasa del CI al deploy |
  | Environment | Destino del deploy, con aprobaciones |
  | Service connection | Permiso del pipeline sobre Azure, idealmente con *workload identity federation* (sin secretos) |
  | Variable group | Variables compartidas, que pueden venir de Key Vault |

- **Equivalencias con GitHub Actions:**

  | GitHub Actions | Azure Pipelines |
  |---|---|
  | workflow | pipeline |
  | job | job |
  | action | task |
  | secrets | secret variables / variable groups |
  | environments | environments |

- **Costo:** para usar los agentes Microsoft-hosted gratis hay que pedir el *free grant* con un formulario. Pedilo en la Etapa 0, porque puede tardar días.

**Cómo se aplica (`azure-pipelines.yml`, resumido)**

```yaml
trigger:
  branches: { include: [main] }
pr:
  branches: { include: [main] }

variables:
  buildConfiguration: Release

stages:
- stage: CI
  jobs:
  - job: Backend
    pool: { vmImage: ubuntu-latest }   # trae Docker: Testcontainers funciona
    steps:
    - task: UseDotNet@2
      inputs: { packageType: sdk, version: 10.0.x }
    - script: dotnet test backend -c $(buildConfiguration) --logger trx --collect:"XPlat Code Coverage"
      displayName: Tests backend
    - task: PublishTestResults@2
      condition: succeededOrFailed()
      inputs: { testResultsFormat: VSTest, testResultsFiles: '**/*.trx' }
    - task: PublishCodeCoverageResults@2
      inputs: { summaryFileLocation: '**/coverage.cobertura.xml' }
    - script: |
        dotnet tool restore
        dotnet ef migrations bundle -p backend/src/Fulbito.Infrastructure -s backend/src/Fulbito.Api \
          -o $(Build.ArtifactStagingDirectory)/migraciones/efbundle --self-contained -r linux-x64
      displayName: Bundle de migraciones
    - publish: $(Build.ArtifactStagingDirectory)/migraciones
      artifact: migraciones
    - task: Docker@2                      # la imagen de la API (§22)
      displayName: Build y push de la imagen
      condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
      inputs:
        command: buildAndPush
        containerRegistry: sc-dockerhub    # service connection al registro
        repository: $(dockerUser)/fulbito-api
        Dockerfile: backend/Dockerfile
        buildContext: backend
        tags: |
          $(Build.BuildId)
          latest

  - job: Frontend
    pool: { vmImage: ubuntu-latest }
    steps:
    - task: NodeTool@0
      inputs: { versionSpec: 22.x }
    - script: |
        npm ci
        npm test -- --run
        npm run build
      workingDirectory: frontend
      env: { VITE_API_URL: $(apiUrl) }
    - publish: frontend/dist
      artifact: web

- stage: Deploy
  dependsOn: CI
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  jobs:
  - deployment: Produccion
    environment: produccion            # acá se configura la aprobación manual
    pool: { vmImage: ubuntu-latest }
    strategy:
      runOnce:
        deploy:
          steps:
          - task: AzureCLI@2
            displayName: Migraciones
            inputs:
              azureSubscription: sc-fulbito
              scriptType: bash
              scriptLocation: inlineScript
              inlineScript: |
                chmod +x $(Pipeline.Workspace)/migraciones/efbundle
                $(Pipeline.Workspace)/migraciones/efbundle --connection "$(sqlConnection)"
          - task: AzureWebAppContainer@1    # el App Service pasa a la imagen nueva
            inputs:
              azureSubscription: sc-fulbito
              appName: app-fulbito-api
              containers: docker.io/$(dockerUser)/fulbito-api:$(Build.BuildId)
          - task: AzureStaticWebApp@0
            inputs:
              workingDirectory: $(Pipeline.Workspace)/web
              app_location: /
              skip_app_build: true
              azure_static_web_apps_api_token: $(swaToken)
```

Se despliega el tag `$(Build.BuildId)` y no `latest`, para saber exactamente qué versión está en producción y poder volver atrás. Docker Hub es gratis para imágenes públicas (la imagen no lleva secretos). Azure Container Registry es la alternativa privada, con costo mensual.

`apiUrl`, `dockerUser`, `sqlConnection` y `swaToken` son variables del pipeline: las dos últimas marcadas como secretas o tomadas de un variable group vinculado a Key Vault. Para `dotnet tool restore` hace falta el manifiesto `.config/dotnet-tools.json` con `dotnet-ef`.

<details><summary>¿Cuál es la diferencia entre stage, job y step?</summary>

El step es una acción concreta (correr un comando, una task). Un job es un conjunto de steps que corre en un mismo agente. Un stage agrupa jobs y marca una fase del proceso, como CI o Deploy. Los stages pueden depender entre sí y tener condiciones; los jobs de un mismo stage pueden correr en paralelo.
</details>

<details><summary>¿Cómo evitás tener secretos en el pipeline?</summary>

La conexión a Azure usa una service connection con *workload identity federation*: el pipeline obtiene tokens de corta duración y no guarda ninguna clave. Los secretos que sí hacen falta van como variables secretas o en un variable group vinculado a Key Vault, nunca en el YAML. Y en runtime la app usa Managed Identity.
</details>

<details><summary>¿Por qué desplegar una imagen Docker y no el código compilado?</summary>

Porque la imagen es exactamente lo que se probó: mismo runtime, mismas dependencias, misma configuración base. Corre igual en tu PC, en el pipeline y en Azure, se vuelve a una versión anterior cambiando el tag y la misma imagen se puede llevar a otro servicio (Container Apps, Kubernetes) sin cambios.
</details>

<details><summary>¿Por qué las migraciones con un bundle y no `dotnet ef database update` en el deploy?</summary>

El bundle es un ejecutable generado en el CI junto con el resto del artefacto. El deploy no necesita el código fuente ni el SDK, y lo que se aplica es exactamente lo que se compiló y testeó (build once, deploy many).
</details>

<details><summary>¿Qué aporta Azure Boards si ya tenés el roadmap en un markdown?</summary>

Trazabilidad y forma de trabajo de equipo. Cada commit y PR queda vinculado a una historia, se ve qué entró en cada sprint y cuánto se avanzó, y se practica Scrum como en una empresa. En entrevistas suelen preguntar cómo trabajás con historias, sprints y PRs: poder mostrar el tablero real ayuda.
</details>
