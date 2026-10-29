# Progreso

Claude Code actualiza este archivo al final de cada paso. Vos también podés editarlo.

**Etapa actual:** 0 · Preparación
**Próximo paso:** 0.5 Crear el GitHub Project `Fulbito` · después, Etapa 1 · 1.1 Historias de usuario

**GitHub Project:** (pegar acá la URL del Project)

## Etapas

- [ ] 0 · Preparación
- [ ] 1 · Descubrimiento (historias, Gherkin, bocetos, DER)
- [ ] 2 · Dominio con TDD
- [ ] 3 · Persistencia (EF Core + SQL Server + índice anti-superposición)
- [ ] 4 · Casos de uso y API
- [ ] 5 · Tests de integración
- [ ] 6 · Docker (Dockerfile, compose de la app completa, registro)
- [ ] 7 · BDD con Reqnroll
- [ ] 8 · Autenticación y roles
- [ ] 9 · Base del frontend
- [ ] 10 · Funcionalidades del frontend
- [ ] 11 · Tests E2E
- [ ] 12 · CI con GitHub Actions (deploy en Azure, más adelante)
- [ ] 13 · Extras
- [ ] 14 · Portfolio y entrevista

## Pasos completados

<!-- Formato: - [x] 2.1 SeSuperponeCon con Theory de bordes · REPASO §5 §6 · commit abc123 -->
- [x] 0.1 Repo en GitHub: `.gitignore` (plantilla VisualStudio + Node/Vite/Playwright), README y `main` protegida con un ruleset · REPASO §1 · commit 8313763
- [x] 0.2 Kit en GitHub (CLAUDE.md, docs/, .claude/, compose, .env.example) por rama `etapa-0-preparacion` + PR · REPASO §1 · commit 16f21fd
- [x] 0.3 SQL Server 2022 en Docker; conexión desde SSMS a `localhost,1433` con `sa` (`@@VERSION` → Developer Edition on Linux) · REPASO §22 · commit 3ad6a76
- [x] 0.4 Solución `backend/Fulbito.slnx` + 4 proyectos de `src` (Application→Domain, Infrastructure→Application, Api→Application+Infrastructure, sin ejemplos de plantilla) y 4 de `tests` con xUnit v3 + VSTest en net10.0 (Domain.Tests→Domain, Application.Tests→Application, Api.IntegrationTests→Api, Specs→Application). `dotnet build` 0 warnings, `dotnet test` 0 tests con exit code 0 · REPASO §4 §6 · commits 76b7ca2, ccd9882
- [ ] 0.5 GitHub Project `Fulbito` vinculado al repo, con `Status` e `Iteration` (reemplaza a Azure DevOps, el grant de Pipelines y la cuenta de Azure) · **pendiente**
- [x] 0.6 (antes 0.8) Flujo rama → PR → merge practicado con los PRs #1 y #2 (docs) y el PR #3 (`etapa-0-preparacion`: 0.3–0.4, 6 commits) con *Create a merge commit* · REPASO §1 · merge d308f96

## Preguntas para repasar

Preguntas de entrevista que costaron. `/siguiente` y `/entrevista` las vuelven a hacer más adelante.

<!-- - (§10) ¿Qué pasa si dos usuarios reservan a la vez? → faltó mencionar el error 2627/2601 de clave duplicada -->
- (§1) Se commiteó un `.env` con contraseña en un repo público y después se agregó al `.gitignore`: ¿está resuelto? → creyó que `.gitignore` oculta el commit. `.gitignore` no oculta nada ni saca archivos ya trackeados; el secreto queda en la historia. Respuesta: **rotar la credencial primero**, `git rm --cached`, limpiar la historia si hace falta (filter-repo/BFG) y prevenir con push protection.
- (§1) ¿Qué pasa con `git push origin main` si `main` está protegida? → respondió que "cambia la rama troncal". En realidad GitHub **rechaza** el push (la regla exige PR); pushear una feature branch sí se acepta y `main` solo cambia al mergear el PR.
- (§22) ¿Por qué desde SSMS no funciona `Server=sql,1433`? → dijo que "igual usaría localhost". En realidad **no resuelve**: `sql` y `fulbito-sql-1` son nombres del DNS interno de la red de Compose, solo visibles para otros contenedores. Desde el host se entra por el puerto publicado (`localhost,1433`); contenedor a contenedor, por `sql,1433`.
- (§4) ¿A qué referencian los proyectos de tests? → mezcló referencias con "los tests tienen que ser independientes". La independencia es de **estado en ejecución** (un test no depende de otro); las referencias son de **compilación**: cada proyecto de tests referencia la capa que prueba (Domain.Tests→Domain, Application.Tests→Application, Api.IntegrationTests→Api, Specs→Application). Ningún proyecto de `src` referencia a `tests`.
- (§4) Domain referenciando a Infrastructure → acertó el ciclo, pero le faltó el porqué arquitectónico: se pierde el aislamiento del dominio (tests unitarios sin base) y se acoplan las reglas a EF Core. La consulta va en el handler vía interfaz de Application; el dominio recibe los datos (DIP).
- (§6) Primer test y `dotnet test` dice "No hay ninguna prueba disponible": nombró bien método no público, falta de runner y build viejo. Faltó la causa más común (**falta `[Fact]`/`[Theory]`**) y la herramienta de diagnóstico **`dotnet test --list-tests`** (separa descubrimiento de ejecución).
- (§1) ¿Aparecen en el PR #3 los commits de los PRs anteriores? → dijo que sí, por usar merge commit. En realidad **no**: un PR muestra solo los commits que están en la rama y no en la base (`git log main..rama`); esos ya estaban en `main`. La estrategia de merge decide **cómo** entran los commits, no **cuáles**.
- (§1) Merge commit, squash o rebase: eligió bien merge commit, pero argumentó "deja `main` intacto para desplegar" (falso: `main` cambia con cualquier estrategia; lo que lo mantiene desplegable son los PRs revisados y el CI). Argumento correcto: conserva cada commit (la historia `test:` → `feat:` → `refactor:` de TDD).
- (§1) Rebase and merge: acertó que cambian los hashes (cambian el padre y el committer), pero faltó el problema: quien ya tenía la rama queda con commits "duplicados" y conflictos al integrar. Regla: no reescribir historia de ramas compartidas.

## Dudas y notas

<!-- Lo que quedó pendiente de entender o investigar -->
- **Cambio de plan (2026-10-29):** Microsoft bloqueó la creación de la cuenta ("Account creation has been blocked", 2026-10-26) y además Azure DevOps exige una suscripción de Azure con tarjeta para crear la organización. Se reemplaza Azure Boards por **GitHub Projects + Issues** (commits con `#<issue>` en vez de `AB#<id>`) y Azure Pipelines por **GitHub Actions** (gratis en repos públicos, sin grant). Los pasos 0.5–0.7 se reemplazan por el 0.5 (GitHub Project) y el viejo 0.8 pasa a ser 0.6. Azure DevOps y el deploy en Azure pueden sumarse más adelante; si se suma Azure, lo primero es la alerta de presupuesto.
- Identidad de Git: autor = `user.name`/`user.email` de la config global (`raldagus <raldagus98@gmail.com>`); push = cuenta `raldagus` del Git Credential Manager. Verificar que ese mail esté agregado en GitHub (Settings → Emails) para que los commits se vinculen al perfil.
- Contraseña de SQL cambiada en `.env` antes de crear el volumen `sqldata` → la clave nueva es la vigente.
- En la PC hay **otro SQL Server en Windows** (`MSSQLSERVER`, 16.0.1000.6) con TCP deshabilitado (solo DAC en 127.0.0.1:1434), así que no choca con el 1433 de Docker. En SSMS usar siempre `localhost,1433` (o `tcp:localhost,1433`): con `localhost` o `.` a secas puede entrar por Shared Memory a la instancia de Windows. Chequeo: `@@VERSION` dice "on Linux" (Docker) u "on Windows" (local).
- SSMS no pidió *Trust server certificate*: probablemente su versión usa Encrypt=Optional por defecto (conexión sin cifrar). Verificar en Options → Connection Properties.
- El contenedor queda apagado si se cierra Docker Desktop o se reinicia la PC (`Restart=no`). Volver a levantar con `docker compose up -d`. Evaluar `restart: unless-stopped` en la Etapa 6.
- Solución en formato `.slnx` (default del SDK 10). VS 2022 17.14 no soporta .NET 10 → se usa VS Code + C# Dev Kit.
- La plantilla `webapi` agrega el paquete `Microsoft.AspNetCore.OpenApi` (documento OpenAPI). En la Etapa 4 se suma Scalar como UI.
- Tests: xUnit v3 con **VSTest** (`xunit.v3.mtp-off`, `xunit.runner.visualstudio`, `Microsoft.NET.Test.Sdk`), plantillas instaladas con `dotnet new install xunit.v3.templates`. Con VSTest, 0 tests = aviso y exit code 0; con Microsoft.Testing.Platform sería exit code 8. Migrar a MTP más adelante si conviene (cambia paquete + `global.json`).
- **`coverlet.collector` no está instalado** (la plantilla v3 no lo trae): agregarlo en la Etapa 2 a `Domain.Tests` para medir la cobertura >90 %.
- Warning LF→CRLF al commitear: evaluar un `.gitattributes` más adelante.
