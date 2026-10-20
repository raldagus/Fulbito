# Progreso

Claude Code actualiza este archivo al final de cada paso. Vos también podés editarlo.

**Etapa actual:** 0 · Preparación
**Próximo paso:** 0.3 docker-compose con SQL Server y verificar la conexión

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

## Preguntas para repasar

Preguntas de entrevista que costaron. `/siguiente` y `/entrevista` las vuelven a hacer más adelante.

<!-- - (§10) ¿Qué pasa si dos usuarios reservan a la vez? → faltó mencionar el error 2627/2601 de clave duplicada -->
- (§1) Se commiteó un `.env` con contraseña en un repo público y después se agregó al `.gitignore`: ¿está resuelto? → creyó que `.gitignore` oculta el commit. `.gitignore` no oculta nada ni saca archivos ya trackeados; el secreto queda en la historia. Respuesta: **rotar la credencial primero**, `git rm --cached`, limpiar la historia si hace falta (filter-repo/BFG) y prevenir con push protection.
- (§1) ¿Qué pasa con `git push origin main` si `main` está protegida? → respondió que "cambia la rama troncal". En realidad GitHub **rechaza** el push (la regla exige PR); pushear una feature branch sí se acepta y `main` solo cambia al mergear el PR.

## Dudas y notas

<!-- Lo que quedó pendiente de entender o investigar -->
- Identidad de Git: autor = `user.name`/`user.email` de la config global (`raldagus <raldagus98@gmail.com>`); push = cuenta `raldagus` del Git Credential Manager. Verificar que ese mail esté agregado en GitHub (Settings → Emails) para que los commits se vinculen al perfil.
- Contraseña de SQL cambiada en `.env` (antes era la misma de `.env.example`). En el 0.3: si el volumen `sqldata` ya existía, la clave vieja sigue vigente → `docker compose down -v` (hoy no hay datos) y volver a levantar.
- Warning LF→CRLF al commitear: evaluar un `.gitattributes` más adelante.
