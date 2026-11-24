# Guía de Entorno Híbrido — Fleetlog System

Esta configuración permite tener **Fleetlog** corriendo de forma idéntica en tu **servidor Linux** y verlo/editarlo en vivo desde **esta PC**, además de exponer la API lista para la **app móvil**.

---

## 1. En tu Servidor Linux (Producción / Staging)

Solo necesitas **Docker** y **Docker Compose** instalados en el servidor.

```bash
git clone https://github.com/MiasCNStudio/fleetlog-system.git
cd fleetlog-system
cp .env.example .env
```

Edita `.env` con la URL real de tu servidor:
```env
APP_ENV=production
APP_DEBUG=false
APP_PORT=8080
APP_URL=http://IP_DE_TU_SERVIDOR:8080   # o https://fleetlog.tudominio.com
DB_PASSWORD=una_clave_segura
DB_ROOT_PASSWORD=otra_clave_segura
CORS_ALLOWED_ORIGINS=*
AUTO_SEED=true
```

Levanta todo con un solo comando:
```bash
chmod +x fleetlog.sh
./fleetlog.sh up
```

Esto automáticamente:
- Compila Vue 3 + Tailwind (`npm run build`)
- Levanta Nginx + PHP 8.3 + MySQL 8.0
- Genera `APP_KEY` si falta, enlaza `storage`, ejecuta migraciones y crea los usuarios iniciales:
  - **Admin:** `admin@fleetlog.test` / `password`
  - **Motorista demo:** `motorista@fleetlog.test` / `password`

---

## 2. En esta PC (Modo Híbrido — ver lo que estás haciendo sin instalar PHP/MySQL)

En esta PC ya tienes **Node.js** instalado. Puedes editar las vistas Vue y ver los cambios en vivo conectados directamente a la API y base de datos de tu **servidor Linux**:

1. En tu `.env` local (en esta PC), pon la dirección de tu servidor Linux:
   ```env
   VITE_API_TARGET=http://IP_DE_TU_SERVIDOR:8080
   ```
2. Ejecuta:
   ```bash
   ./fleetlog.sh remote
   ```
3. Abre `http://localhost:5173` en tu navegador.
   - Todo el frontend se recarga en tiempo real desde esta PC.
   - Todas las llamadas `/api/*` y `/storage/*` se redirigen automáticamente a tu servidor Linux.

*(Opcional: si instalas Docker en esta PC, también puedes correr `./fleetlog.sh dev` para tener tu propia base de datos local aislada en `http://localhost:8080`.)*

---

## 3. Conectar tu Servidor Linux con esta PC y Móviles de forma segura

- **Red local (LAN):** Usa la IP local del servidor (ej. `http://192.168.1.50:8080`).
- **Desde cualquier lugar (recomendado):**
  - **Tailscale** en el servidor Linux y en tu PC/celular (cero puertos abiertos al público).
  - O **Cloudflare Tunnel / Caddy** con dominio HTTPS (`FORCE_HTTPS=true` en `.env`).

---

## 4. Roles disponibles en el sistema

| Rol | Permisos |
| :--- | :--- |
| `admin` | Acceso total: usuarios, vehículos, bitácoras, incidencias y dashboard. |
| `despachador` | Vehículos (alta/edición), bitácoras (alta/edición), incidencias (seguimiento) y dashboard. |
| `motorista` | Registrar salidas/regresos, reportar incidencias, consultar vehículos y dashboard. |
