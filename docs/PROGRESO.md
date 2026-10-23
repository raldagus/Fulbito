# Progreso

Claude Code actualiza este archivo al final de cada paso. Vos también podés editarlo.

**Etapa actual:** 0 · Preparación
**Próximo paso:** 0.4 Crear la solución y los 8 proyectos vacíos (rama `etapa-0-preparacion`)

**Azure Boards:** (pegar acá la URL del proyecto)
**Grant de parallel jobs pedido el:** (fecha)

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
- [ ] 12 · Azure: deploy y Azure Pipelines
- [ ] 13 · Extras
- [ ] 14 · Portfolio y entrevista

## Pasos completados

<!-- Formato: - [x] 2.1 SeSuperponeCon con Theory de bordes · REPASO §5 §6 · commit abc123 -->
- [x] 0.1 Repo en GitHub: `.gitignore` (plantilla VisualStudio + Node/Vite/Playwright), README y `main` protegida con un ruleset · REPASO §1 · commit 8313763
- [x] 0.2 Kit en GitHub (CLAUDE.md, docs/, .claude/, compose, .env.example) por rama `etapa-0-preparacion` + PR · REPASO §1 · commit 16f21fd
- [x] 0.3 SQL Server 2022 en Docker; conexión desde SSMS a `localhost,1433` con `sa` (`@@VERSION` → Developer Edition on Linux) · REPASO §22 · commit 3ad6a76

## Preguntas para repasar

Preguntas de entrevista que costaron. `/siguiente` y `/entrevista` las vuelven a hacer más adelante.

<!-- - (§10) ¿Qué pasa si dos usuarios reservan a la vez? → faltó mencionar el error 2627/2601 de clave duplicada -->
- (§1) Se commiteó un `.env` con contraseña en un repo público y después se agregó al `.gitignore`: ¿está resuelto? → creyó que `.gitignore` oculta el commit. `.gitignore` no oculta nada ni saca archivos ya trackeados; el secreto queda en la historia. Respuesta: **rotar la credencial primero**, `git rm --cached`, limpiar la historia si hace falta (filter-repo/BFG) y prevenir con push protection.
- (§1) ¿Qué pasa con `git push origin main` si `main` está protegida? → respondió que "cambia la rama troncal". En realidad GitHub **rechaza** el push (la regla exige PR); pushear una feature branch sí se acepta y `main` solo cambia al mergear el PR.
- (§22) ¿Por qué desde SSMS no funciona `Server=sql,1433`? → dijo que "igual usaría localhost". En realidad **no resuelve**: `sql` y `fulbito-sql-1` son nombres del DNS interno de la red de Compose, solo visibles para otros contenedores. Desde el host se entra por el puerto publicado (`localhost,1433`); contenedor a contenedor, por `sql,1433`.

## Dudas y notas

<!-- Lo que quedó pendiente de entender o investigar -->
- Identidad de Git: autor = `user.name`/`user.email` de la config global (`raldagus <raldagus98@gmail.com>`); push = cuenta `raldagus` del Git Credential Manager. Verificar que ese mail esté agregado en GitHub (Settings → Emails) para que los commits se vinculen al perfil.
- Contraseña de SQL cambiada en `.env` antes de crear el volumen `sqldata` → la clave nueva es la vigente.
- En la PC hay **otro SQL Server en Windows** (`MSSQLSERVER`, 16.0.1000.6) con TCP deshabilitado (solo DAC en 127.0.0.1:1434), así que no choca con el 1433 de Docker. En SSMS usar siempre `localhost,1433` (o `tcp:localhost,1433`): con `localhost` o `.` a secas puede entrar por Shared Memory a la instancia de Windows. Chequeo: `@@VERSION` dice "on Linux" (Docker) u "on Windows" (local).
- SSMS no pidió *Trust server certificate*: probablemente su versión usa Encrypt=Optional por defecto (conexión sin cifrar). Verificar en Options → Connection Properties.
- El contenedor queda apagado si se cierra Docker Desktop o se reinicia la PC (`Restart=no`). Volver a levantar con `docker compose up -d`. Evaluar `restart: unless-stopped` en la Etapa 6.
- Warning LF→CRLF al commitear: evaluar un `.gitattributes` más adelante.
