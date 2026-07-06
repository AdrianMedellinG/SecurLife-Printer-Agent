# SecurLife Printer Agent - Brother QL-800 / QL-810W

Agente local para imprimir etiquetas de visitas desde un sistema React web en Internet.

## Requisitos en Windows 11

1. Primero instalar los drivers de la impresora Brother QL-800 / QL-810W desde [`bsq16aw1101cus.exe`](https://github.com/AdrianMedellinG/SecurLife-Printer-Agent/blob/main/bsq16aw1101cus.exe).
2. Configurar el rollo como `DK 62mm Continuous` / `62mm x Continuous`.
3. Instalar Node.js 22 LTS con npm. Descarga oficial: [`node-v22.22.3-x64.msi`](https://nodejs.org/download/release/v22.22.3/node-v22.22.3-x64.msi). Tambien puedes usar la pagina general de descargas de Node.js: <https://nodejs.org/en/download>.
4. Ejecutar este agente en la PC donde está conectada la impresora.

## Instalación

```bash
npm install
copy .env.example .env
npm run list-printers
```

`npm install` instala las dependencias del proyecto, incluyendo PM2. No es necesario instalar PM2 globalmente con `npm install -g pm2`; los comandos `npm run pm2:*` usan el PM2 local de este proyecto.

### Instalación automática en Windows

Desde PowerShell o CMD como Administrador, ejecuta:

```bat
scripts\install-node-and-copy.cmd
```

Ese script instala Node.js LTS con npm si no existen, copia el proyecto a `C:\securlife-printer-agent` sin copiar `node_modules`, `.git` ni `tmp`, y ejecuta `npm ci --omit=dev` en la carpeta final. PM2 se instala como dependencia local del proyecto.

Para usar otra ruta:

```bat
scripts\install-node-and-copy.cmd -TargetPath "C:\otra-carpeta"
```

Después activa el inicio automático:

```bat
C:\securlife-printer-agent\scripts\setup-auto-start.cmd
```

Por defecto se crea una tarea programada que levanta el proceso con PM2 cuando inicia sesión el usuario de Windows. Esto suele ser lo más confiable para impresoras instaladas en el perfil del usuario. Si necesitas que la tarea también se dispare al arranque del sistema, usa:

```bat
C:\securlife-printer-agent\scripts\setup-auto-start.cmd -Trigger AtStartup
```

Con `-Trigger AtStartup` se registran ambos triggers: al iniciar Windows y al iniciar sesión. El trigger de inicio de sesión evita que el agente quede apagado cuando Windows no permite usar impresoras de usuario antes de abrir la sesión.

Los logs del arranque automático quedan en:

```txt
C:\securlife-printer-agent\tmp
```

El script `start-printer-agent.ps1` normalmente lo ejecuta la tarea programada. Si necesitas correrlo manualmente desde CMD:

```bat
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "C:\securlife-printer-agent\scripts\start-printer-agent.ps1" -ProjectPath "C:\securlife-printer-agent"
```

### Arranque automatico usando solo CMD

Si prefieres no usar PowerShell, el proyecto tambien incluye scripts `.cmd` para registrar el arranque automatico con el Programador de tareas de Windows.

Desde CMD normal, ejecuta:

```bat
C:\securlife-printer-agent\scripts\setup-auto-start-cmd.cmd
```

Si el proyecto esta en otra ruta:

```bat
C:\ruta\al\proyecto\scripts\setup-auto-start-cmd.cmd "C:\ruta\al\proyecto"
```

Ese script registra una tarea llamada `SecurLife Printer Agent` que ejecuta:

```bat
scripts\start-printer-agent.cmd
```

La tarea se dispara al iniciar sesion el usuario de Windows despues de reiniciar la computadora. Esto es intencional: normalmente las impresoras instaladas en Windows estan disponibles correctamente hasta que el usuario inicia sesion.

El script tambien inicia el agente en ese momento y guarda el estado de PM2 con `npm run pm2:save`.

Si PM2 muestra `connect EPERM //./pipe/rpc.sock` o `connect EPERM //./pipe/interactor.sock`, normalmente hay un daemon PM2 levantado como Administrador y otro como usuario normal. Limpialo una sola vez desde CMD como Administrador:

```bat
C:\securlife-printer-agent\scripts\reset-pm2-eperm.cmd
```

Despues cierra ese CMD de Administrador y vuelve a iniciar el agente desde CMD normal o con `Impresora.bat`.

## PM2

El proyecto incluye PM2 como dependencia local en `package.json` y tambien incluye `ecosystem.config.cjs` para ejecutar el agente:

```bash
npm run pm2:start
```

Comandos utiles:

```bash
npm run pm2:status
npm run pm2:logs
npm run pm2:restart
npm run pm2:stop
npm run pm2:delete
```

Los logs principales de PM2 quedan en:

```txt
C:\securlife-printer-agent\tmp\pm2-out.log
C:\securlife-printer-agent\tmp\pm2-error.log
```

## Menu rapido en Windows

Para arrancar y revisar el microservicio de la impresora de forma mas sencilla, puedes usar el archivo:

```bat
Impresora.bat
```

Este menu se ejecuta desde la carpeta del proyecto y permite:

- Iniciar el agente con PM2 y guardar el proceso.
- Ver el estado del proceso en PM2.
- Ver los logs del agente.
- Reiniciar o detener el agente.
- Listar las impresoras instaladas en Windows.
- Imprimir una etiqueta de prueba.

La opcion `1) Iniciar agente con PM2` deja levantado el microservicio local de impresion. Despues de iniciarlo, el sistema web puede llamar al agente en:

```txt
http://localhost:3500
```

Edita `.env` y coloca el nombre exacto de la impresora:

```env
PRINTER_NAME=Brother QL-800
# Puedes usar * para aceptar cualquier dominio, o separar varios con coma.
ALLOWED_ORIGIN=*
BODY_LIMIT=5mb
LABEL_WIDTH_MM=62
LABEL_HEIGHT_MM=80
PRINT_SCALE=noscale
PRINTER_PAPER_SIZE=
```

Para producción es más seguro usar solo los dominios de tu sistema:

```env
ALLOWED_ORIGIN=https://tu-dominio.com,https://otro-dominio.com
```

Si salen varias etiquetas en blanco por cada impresión, revisa el tamaño de papel que Windows reporta:

```bash
npm run list-printers
```

La Brother debe mostrar un tamaño de `62mm` / `2.4"` o `DK 62mm Continuous`. Si solo aparecen tamaños chicos como `0.9" x 0.9"`, el driver está usando otro rollo y partirá una etiqueta larga en varias etiquetas físicas. Corrige esto en las preferencias de impresión de Windows/Brother y vuelve a ejecutar `npm run list-printers`.

Si el tamaño correcto aparece con un nombre exacto, puedes fijarlo en `.env`:

```env
PRINTER_PAPER_SIZE=Nombre exacto mostrado por list-printers
```

## Probar impresión

```bash
npm run test-label
```

Cuando se manda una foto de visitante en `fotoVisitante`, `foto`, `photoBase64` o `visitorPhotoBase64`, el agente la convierte a blanco y negro antes de colocarla en el PDF. Esto ayuda a que la impresión salga mejor en impresoras Brother QL monocromáticas.

## Iniciar agente

La forma mas sencilla en Windows es abrir `Impresora.bat` y seleccionar:

```txt
1) Iniciar agente con PM2
```

Tambien puedes iniciarlo manualmente con Node:

```bash
npm start
```

O con PM2:

```bash
npm run pm2:start
```

Debe quedar activo en:

```txt
http://localhost:3500
```

## Llamada desde React

```js
await fetch('http://localhost:3500/print-visit-label', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    visitante: 'Juan Perez',
    empresa: 'SecurLife',
    motivo: 'Visita',
    anfitrion: 'Enrique',
    fecha: new Date().toLocaleDateString('es-MX'),
    folio: 'VIS-0001',
    qr: 'VIS-0001',
    fotoVisitante: 'data:image/jpeg;base64,...'
  })
});
```

## Probar impresora

```js
await fetch('http://localhost:3500/test-print', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    printerName: 'Brother QL-800'
  })
});
```

## Importante

Si tu React está en HTTPS y llama a `http://localhost`, puede funcionar en muchos navegadores, pero si el navegador bloquea la llamada por contenido mixto, empaqueta este agente como app Electron o agrega HTTPS local con certificado.

Para producción, se recomienda instalar este agente como servicio o app de inicio automático.
