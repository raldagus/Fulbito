# Roadmap del proyecto — Fulbito · Reservas de canchas

App para reservar canchas de pádel y fútbol 5, gestionada con GitHub Projects y con CI en GitHub Actions. Hay tres roles:

- **Jugador:** busca un horario libre, reserva, paga la seña y puede cancelar.
- **Dueño:** administra su complejo, sus canchas y precios, confirma señas y ve la agenda.
- **Admin:** da de alta complejos y dueños.

Cada etapa dice qué se construye, qué temas del `REPASO.md` aplica, qué tests lleva y cuándo está terminada.
Los números entre corchetes, por ejemplo [paso 12], son los pasos del roadmap general .NET + React.

---

## Reglas de negocio (la fuente de verdad)

Todo test y toda feature Gherkin sale de esta lista. Si aparece una regla nueva, primero se agrega acá.

| # | Regla |
|---|---|
| R1 | Un turno tiene que estar dentro del horario de apertura del complejo. |
| R2 | La duración del turno es la de la cancha (60 o 90 min) y el inicio cae en la grilla (cada 30 min). |
| R3 | No se puede reservar en el pasado ni con más de 14 días de anticipación. |
| R4 | No puede haber dos reservas activas (pendiente de seña o confirmada) superpuestas en la misma cancha. Tampoco se puede reservar sobre un bloqueo (mantenimiento). |
| R5 | Precio: pico si el turno empieza en horario pico del complejo, o si es sábado o domingo. Si no, valle. |
| R6 | La seña es un porcentaje del precio (por defecto 30 %). La reserva nace como **Pendiente de seña**. |
| R7 | Si la seña no se confirma en 30 minutos, la reserva se libera sola. |
| R8 | Cancelar con 24 h o más de anticipación devuelve la seña; con menos, la seña se pierde. |
| R9 | Un jugador puede tener como máximo 2 reservas activas a futuro. |
| R10 | Solo el dueño del complejo puede confirmar señas, bloquear horarios y marcar "no asistió". |

---

## Etapa 0 · Preparación

**Objetivo:** dejar el repo listo para trabajar con orden desde el primer día.

1. Crear el repo en GitHub (público) con README, `.gitignore` (VisualStudio + Node) y la rama `main` protegida.
2. Copiar este kit: `CLAUDE.md`, `docs/`, `.claude/commands/`.
3. `docker-compose.yml` con SQL Server 2022 y verificar la conexión desde SSMS o la extensión mssql de VS Code (`localhost,1433`, usuario `sa`, *Trust server certificate*).
4. Crear la solución y los 8 proyectos vacíos (4 de `src`, 4 de `tests`) con sus referencias.
5. **GitHub Project:** crear el Project `Fulbito` (vista de tablero), vinculado al repo, con los campos `Status` e `Iteration` (sprints de 2 semanas).
6. Primer commit y primer PR, aunque sea trivial, para practicar el flujo.

> **Cambio de plan:** Azure DevOps exige una suscripción de Azure con tarjeta para crear la organización, así que usamos **GitHub Projects + Issues** en lugar de Azure Boards y **GitHub Actions** en lugar de Azure Pipelines (en repos públicos es gratis y no hace falta pedir ningún grant). Azure DevOps y el deploy en Azure (§24) pueden sumarse más adelante; si se suma Azure, lo primero es crear una alerta de presupuesto (Cost Management → Budgets).

- **Repaso:** §1 Git · §4 Arquitectura · §25 GitHub Projects y Actions
- **Listo cuando:** `dotnet build backend` compila, `dotnet test backend` corre (0 tests), SQL Server levanta con Docker y el GitHub Project existe vinculado al repo.

---

## Etapa 1 · Descubrimiento (antes de programar)

**Objetivo:** entender el problema y escribir los criterios de aceptación que después se convierten en tests.

1. Escribir 6 a 8 historias de usuario. Ejemplo: "Como jugador quiero ver los turnos libres de un día para elegir uno".
2. Para cada historia, sus criterios de aceptación.
3. Pasar las reglas R1, R4, R5 y R8 a features Gherkin en `docs/features/`. No se ejecutan todavía.
4. Bocetos a mano o en Figma de 4 pantallas: grilla de turnos, confirmar reserva, mis reservas y agenda del dueño.
5. Diagrama entidad-relación: Complejo, Cancha, Reserva, TurnoOcupado, Bloqueo, Usuario.
6. **GitHub Project + Issues:**
   - cada etapa del roadmap como un *Milestone* (≈ Epic)
   - cada historia como un *Issue*, con sus criterios de aceptación en la descripción (≈ User Story)
   - los pasos como *sub-issues* o una lista de tareas dentro del issue (≈ Tasks)
   - sprints de 2 semanas con el campo `Iteration` del Project
   - `#<número>` en un commit enlaza el issue, y `Closes #<número>` en el PR lo cierra al mergear

- **Repaso:** §14 BDD y Gherkin · §19 UX/UI · §25 GitHub Projects y Actions
- **Listo cuando:** las features se leen como algo que entendería el dueño de una cancha, sin términos técnicos, y el primer sprint está planificado en el GitHub Project.

---

## Etapa 2 · Dominio con TDD [pasos 2, 4, 10, 11]

**Objetivo:** las reglas de negocio funcionando y testeadas, sin base de datos ni HTTP. Es la etapa más importante para aprender TDD.

Orden sugerido. Cada regla es uno o más ciclos 🔴🟢🔵:

1. `Reserva.SeSuperponeCon(inicio, fin)` → R4. Un `[Theory]` con los bordes: termina justo cuando la otra empieza, una contiene a la otra, etc.
2. `Cancha.PrecioPara(inicioLocal)` → R5 (pico, valle, fin de semana).
3. `Reserva.Crear(...)`: estado inicial y cálculo de seña → R6.
4. Validar horario de apertura y grilla de 30 min → R1, R2.
5. Validar pasado y 14 días, con el "ahora" recibido por parámetro → R3.
6. `Reserva.Cancelar(ahora)` → R8, y qué pasa si ya estaba cancelada.
7. `Reserva.EstaVencida(ahora)` → R7.
7b. `Reserva.Slots()`: los bloques de 30 min que ocupa la reserva (90 min → 3 slots). Se usa en la Etapa 3 para que la base impida superposiciones.
8. Introducir `Result<T>` y `Error` cuando aparezca el primer error de negocio.
9. **Tu turno:** R9 la escribe Agustina sola, test primero.

- **Repaso:** §2 C# moderno · §3 POO y SOLID · §5 TDD · §6 xUnit · §8 Manejo del tiempo · §11 Result pattern
- **Listo cuando:** todas las reglas R1–R9 tienen tests en verde, el proyecto Domain no referencia ningún paquete externo y la cobertura del dominio es mayor al 90 %.

---

## Etapa 3 · Persistencia [paso 6]

**Objetivo:** guardar y leer las entidades en SQL Server, con la base protegiéndose sola contra reservas duplicadas.

1. `AppDbContext` con el proveedor de SQL Server y configuraciones con `IEntityTypeConfiguration<T>`.
2. Primera migración y revisión del SQL generado (`dotnet ef migrations script`).
3. Tabla `TurnosOcupados (CanchaId, SlotInicio, ReservaId)` con **clave primaria compuesta** `(CanchaId, SlotInicio)`: la base rechaza dos reservas que ocupen el mismo bloque (R4 doble protección). Al cancelar o vencer una reserva se borran sus slots.
4. Concurrencia optimista con `rowversion` en `Reserva`. Índices: `Reservas (CanchaId, Inicio)`, `Reservas (ClienteId, Estado)`.
5. Implementar `IReservaRepository` y `ICanchaRepository`.
6. Seed de datos de ejemplo: un complejo, 3 canchas y algunas reservas.

- **Repaso:** §9 EF Core · §10 SQL Server y concurrencia
- **Listo cuando:** la base se crea desde cero con `dotnet ef database update` e insertar a mano dos slots iguales para la misma cancha da error de clave duplicada.

---

## Etapa 4 · Casos de uso y API [pasos 5, 12]

**Objetivo:** exponer la funcionalidad por HTTP, con validaciones y errores claros.

1. `ObtenerDisponibilidadHandler` (turnos de una cancha en una fecha, con estado y precio). TDD con NSubstitute.
2. `CrearReservaHandler`. Tests con repositorio mockeado y `FakeTimeProvider`.
3. `CancelarReservaHandler` y `ConfirmarSenaHandler`.
4. Controllers: `CanchasController` y `ReservasController`. Mapear `Result` a 200, 201, 400, 404 o 409 con ProblemDetails.
5. FluentValidation para los requests: formato, campos obligatorios.
6. Manejo global de excepciones, logging con `ILogger` y OpenAPI con Scalar.
7. Endpoint `/health` con chequeo de la base.

- **Repaso:** §7 Mocks · §11 Result · §12 ASP.NET Core
- **Listo cuando:** desde Scalar o un archivo `.http` se puede ver la disponibilidad, reservar, cancelar y confirmar la seña, y cada error devuelve un ProblemDetails entendible.

---

## Etapa 5 · Tests de integración [paso 12]

**Objetivo:** probar la API real contra un SQL Server real, el mismo motor que Azure SQL.

1. `ApiFactory` con WebApplicationFactory y Testcontainers (SQL Server).
2. Respawn para limpiar la base entre tests.
3. Tests por endpoint: caso feliz, validación (400), no encontrado (404) y conflicto (409).
4. **Test de concurrencia:** dos `POST /reservas` simultáneos al mismo turno → uno da 201 y el otro 409.
5. Medir la cobertura con coverlet y ReportGenerator.

- **Repaso:** §13 Tests de integración · §10 concurrencia
- **Listo cuando:** `dotnet test` levanta el contenedor solo y todo pasa en verde dos veces seguidas. Desde ahora, el workflow de CI de GitHub Actions (§25) corre estos tests en cada PR.

---

## Etapa 6 · Docker [paso 16]

**Objetivo:** que toda la app (base, API y front) se levante con un solo comando, y que la API viaje a producción como imagen de contenedor.

1. Conceptos con la terminal: imagen vs contenedor, `docker run`, `ps`, `logs`, `exec`, `stop` y `rm`, usando el contenedor de SQL Server que ya existe.
2. `backend/Dockerfile` **multi-stage** para la API: restore aprovechando la caché de capas, publish y una imagen final de runtime que corre con usuario no root.
3. `.dockerignore`, para no copiar `bin/`, `obj/`, `node_modules/` ni archivos `.env`.
4. Construir la imagen, correrla a mano conectada al SQL Server del compose y comparar el tamaño de la imagen del SDK con la de runtime.
5. Ampliar `docker-compose.yml`: servicio `api` con variables de entorno, `depends_on` con *healthcheck* de SQL, red interna (la API llega a la base por el nombre `sql`) y volumen persistente.
6. Secretos fuera del compose: archivo `.env` (ignorado por Git) y un `.env.example` versionado.
7. **Tu turno:** `frontend/Dockerfile` multi-stage (Node para compilar y nginx para servir), con `nginx.conf` que soporte las rutas de React Router. Se hace al terminar la Etapa 9.
8. Subir la imagen de la API a un registro (Docker Hub gratis) con tags por versión.

- **Repaso:** §22 Docker
- **Listo cuando:** en una PC limpia, `docker compose up --build` levanta base, API y front funcionando, y `docker images` muestra la imagen de la API por debajo de ~150 MB.

---

## Etapa 7 · BDD con Reqnroll [paso 11]

**Objetivo:** que las features de la Etapa 1 se ejecuten como tests.

1. Configurar Reqnroll en `Fulbito.Specs` con features en español.
2. Implementar los steps de `reservar.feature` contra la capa Application, usando fakes en memoria y `FakeTimeProvider`.
3. Agregar `cancelar.feature` con un *Esquema del escenario* (tabla de anticipaciones → seña devuelta o perdida).
4. **Tu turno:** `precios.feature` completa, escrita y conectada por Agustina.

- **Repaso:** §14 BDD
- **Listo cuando:** cambiar una regla en el dominio rompe el escenario correspondiente con un mensaje que se entiende.

---

## Etapa 8 · Autenticación y roles [paso 14]

1. ASP.NET Core Identity con sus tablas en la misma base.
2. Registro y login que devuelven un JWT con el rol.
3. Roles Jugador, Dueño y Admin, y políticas de autorización.
4. R10: el dueño solo opera sobre **su** complejo (autorización por recurso, dentro del handler).
5. Tests de integración: 401 sin token, 403 con otro rol o con el dueño de otro complejo.
6. CORS configurado solo para el dominio del front.

- **Repaso:** §15 Seguridad
- **Listo cuando:** cada endpoint tiene un test que verifica quién puede y quién no puede usarlo.

---

## Etapa 9 · Base del frontend [pasos 7, 8, 9]

1. Vite + React + TypeScript + Tailwind. Estructura por features (`features/reservas`, `features/canchas`).
2. Definir los tokens de diseño en Tailwind (colores de estado: libre, ocupado, pendiente, bloqueado) y una tipografía.
3. React Router: rutas públicas, rutas de jugador y rutas de dueño, con protección por rol.
4. Cliente HTTP con el token y TanStack Query configurado.
5. Vitest + Testing Library + MSW configurados, con un primer test trivial que pase.
5b. El front se puede correr con `npm run dev` contra la API del compose (`docker compose up sql api`).
6. Layout responsive mobile-first y navegación accesible con teclado.

- **Repaso:** §16 React + TS · §17 TanStack Query · §19 UX/UI · §20 Testing React
- **Listo cuando:** la app navega entre pantallas vacías, `npm test` corre y Lighthouse da más de 90 en accesibilidad.

---

## Etapa 10 · Funcionalidades del frontend [pasos 8, 9, 13]

Cada pantalla se hace con su test al lado; cuando se pueda, el test primero.

1. **Grilla de turnos:** selector de fecha y cancha, y celdas con estado y precio. Las ocupadas no se pueden elegir.
2. **Confirmar reserva:** resumen, precio, seña y botón. Cubrir los estados de carga, éxito y error (409 → "Ese turno se acaba de ocupar").
3. **Mis reservas:** lista con estado, botón cancelar y aviso de si la seña se devuelve o no **antes** de confirmar.
4. **Login y registro** con React Hook Form + Zod.
5. **Panel del dueño:** agenda del día, confirmar seña, bloquear horario.
6. Estados vacíos y de error diseñados, no improvisados.

- **Repaso:** §17 · §18 Formularios · §19 · §20
- **Listo cuando:** cada pantalla tiene tests de comportamiento con MSW y funciona con teclado y en el celular.

---

## Etapa 11 · Tests E2E [paso 13]

1. Playwright contra la app completa levantada con `docker compose up --build`, el mismo stack que en la Etapa 6.
2. Flujo del jugador: login → elegir turno → reservar → verlo en "Mis reservas".
3. Flujo del dueño: login → confirmar seña → el turno aparece confirmado.
4. Opcional: un escenario Gherkin ejecutado con playwright-bdd.

- **Repaso:** §21 Playwright
- **Listo cuando:** los dos flujos pasan en local y en CI.

---

## Etapa 12 · CI con GitHub Actions (y deploy en Azure, más adelante) [paso 16]

**Objetivo:** un CI que no deja pasar nada sin tests. El deploy en Azure queda para más adelante, porque requiere una suscripción de Azure con tarjeta.

En la práctica, el CI (pasos 1–3) conviene armarlo apenas termine la Etapa 5, cuando ya hay tests que valga la pena correr.

**CI (GitHub Actions)**

1. `.github/workflows/ci.yml`: jobs de tests de back (con Testcontainers, el runner `ubuntu-latest` trae Docker) y de front, con resultados y cobertura subidos como artefactos, y en `main` **build y push de la imagen Docker de la API** a Docker Hub con el número de corrida como tag.
2. GitHub: en el ruleset de `main`, exigir que los checks del CI pasen (*required status checks*).
3. Badge del workflow en el README.

**Más adelante (opcional): deploy en Azure.** Requiere suscripción de Azure. Antes de crear cualquier recurso: alerta de presupuesto (Cost Management → Budgets) de unos pocos dólares. Si además se quiere usar Azure DevOps, Boards y Pipelines reemplazan a Projects y Actions con los mismos conceptos (tabla de equivalencias en §25).

**Recursos en Azure** (todo en un resource group `rg-fulbito`, región cercana, tiers gratuitos)

Nombres: `rg-fulbito`, `sql-fulbito` (base `fulbito`), `app-fulbito-api`, `kv-fulbito` e imagen `<usuario-dockerhub>/fulbito-api`. Si se usa Azure DevOps, la service connection se llama `sc-fulbito`.

> ⚠️ `sql-fulbito`, `app-fulbito-api` y `kv-fulbito` forman parte de una URL pública (`*.database.windows.net`, `*.azurewebsites.net`, `*.vault.azure.net`), así que tienen que ser **únicos en todo Azure**. Si al crearlos ya están tomados, agregar un sufijo corto (ej. `kv-fulbito-ra`) y actualizar los docs y el workflow con el nombre real.

4. **Azure SQL Database** con la oferta gratuita (serverless con auto-pausa). Reglas de firewall y autenticación con Microsoft Entra.
5. **App Service para contenedores** (Linux, plan F1 o B1) que corre la imagen de la API, con *health check* en `/health`. Alternativa: Azure Container Apps.
6. **Static Web Apps** (plan Free) para el front, con la URL de la API como variable de build.
7. **Key Vault** para la clave del JWT, y **Managed Identity** del App Service para leer Key Vault y conectarse a Azure SQL **sin contraseñas**.
8. **Application Insights**: logs, errores, tiempos de respuesta y un *availability test* sobre `/health` (reemplaza a UptimeRobot).

**Deploy (GitHub Actions)**

9. Login a Azure con **OIDC** (`azure/login` con una *federated credential*): el workflow obtiene tokens de corta duración y no guarda secretos.
10. Job **deploy**, solo desde `main` y después del CI:
    - migraciones con un *EF migrations bundle*
    - el App Service pasa a la imagen nueva (`azure/webapps-deploy`)
    - deploy del front a Static Web Apps
11. *Environment* `produccion` con *required reviewers*: el deploy espera un OK manual.
12. CORS de la API solo para el dominio de Static Web Apps.

- **Repaso:** §22 Docker · §25 GitHub Projects y Actions · §24 Azure (si se suma el deploy)
- **Listo cuando:** un PR con un test roto no se puede mergear y cada merge a `main` publica la imagen de la API en Docker Hub. Con el deploy en Azure: un merge a `main` llega a producción después de la aprobación, la API no tiene ninguna contraseña en su configuración y Application Insights muestra los requests.

---

## Etapa 13 · Extras (elegir 1 o 2)

- **Liberar señas vencidas (R7)** con un `BackgroundService` o, en versión Azure, con una **Azure Function con Timer Trigger** cada minuto. En los dos casos la lógica se testea con `FakeTimeProvider`.
- **Infraestructura como código con Bicep:** describir en `infra/main.bicep` todos los recursos de Azure de la Etapa 12 y desplegarlos desde GitHub Actions (requiere el deploy en Azure). Así el entorno se puede recrear desde cero.
- **Recordatorios por email** el día anterior con Azure Communication Services.
- **Grilla en tiempo real** con SignalR: si alguien reserva, la celda se ocupa en otras pantallas.
- **Turnos fijos semanales** ("todos los martes 20:00"): es una buena regla nueva para hacer TDD sin ayuda.
- **Pago de seña con Mercado Pago** (checkout y webhook).
- **Asistente con IA:** "¿qué hay libre el sábado a la tarde en pádel?" → consulta la disponibilidad real.

- **Repaso:** §23 Extras

---

## Etapa 14 · Portfolio y entrevista

1. README con capturas, un GIF del flujo, el diagrama de arquitectura, cómo correrlo y, si hay deploy, los links de producción.
2. Sección "Decisiones técnicas": por qué la tabla de slots con clave primaria compuesta, por qué el Result pattern, por qué TimeProvider y (si se sumó Azure) por qué Managed Identity.
2b. Captura del workflow de GitHub Actions y del tablero del GitHub Project. Si se sumó el deploy, diagrama de la arquitectura en Azure (App Service, Static Web Apps, Azure SQL, Key Vault, Application Insights).
3. Usuarios demo (jugador y dueño) para quien revise el proyecto.
4. Correr `/entrevista` varias veces y practicar la explicación del proyecto en 2 minutos.

**Listo cuando:** alguien que no conoce el proyecto lo entiende leyendo el README en 3 minutos.
