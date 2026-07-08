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

### Instalación completa desde cero en Windows

Para instalar todo desde cero en una computadora nueva, ejecuta como Administrador:

```bat
Instalar-SecurLife-Printer-Agent.bat
```

Ese instalador hace el flujo completo desde CMD:

- Descarga el repositorio `AdrianMedellinG/SecurLife-Printer-Agent` desde GitHub.
- Guarda el proyecto en `C:\securlife-printer-agent`.
- Instala Node.js `22.22.3` LTS con npm desde el MSI oficial si no existe una version compatible. Si ya existe Node.js 22, 23 o 24, omite la instalacion de Node y continua.
- Instala `node_modules`, incluyendo PM2 local del proyecto.
- Copia `.env.example` a `.env` si todavia no existe.
- Ejecuta `npm run list-printers` para detectar impresoras.
- Permite seleccionar la impresora que quedara guardada como `PRINTER_NAME` en `.env`.
- Inicia el microservicio con PM2.
- Pregunta si quieres activar el auto inicio oculto al iniciar sesion en Windows.

### Fin de la instalacion completa

El instalador puede registrar automaticamente el autoarranque cuando pregunta:

```txt
Quieres activar el auto inicio con CMD al iniciar sesion? (S/N):
```

Si respondes `S`, con eso queda instalado todo: el proyecto en `C:\securlife-printer-agent`, las dependencias, la impresora configurada en `.env`, el microservicio iniciado con PM2 y el autoarranque registrado en Windows.

Despues de eso puedes cerrar la ventana del instalador. Para validar que el agente esta activo, abre:

```txt
http://localhost:3500/health
```

### Autoarranque en Windows si no se activo en la instalacion

Si respondiste `N`, cerraste el instalador antes de activar el autoarranque, o necesitas configurarlo despues, ejecuta desde CMD:

```bat
C:\securlife-printer-agent\scripts\setup-auto-start-cmd.cmd
```

Si el proyecto esta en otra ruta:

```bat
C:\ruta\al\proyecto\scripts\setup-auto-start-cmd.cmd "C:\ruta\al\proyecto"
```

Ese script registra una tarea llamada `SecurLife Printer Agent` que ejecuta:

```bat
wscript.exe "C:\securlife-printer-agent\scripts\start-printer-agent-hidden.vbs"
```

La tarea se dispara al iniciar sesion el usuario de Windows despues de reiniciar la computadora. Esto es intencional: normalmente las impresoras instaladas en Windows estan disponibles correctamente hasta que el usuario inicia sesion. El VBS ejecuta `scripts\start-printer-agent.cmd` oculto para no mostrar una ventana negra de CMD.

El runner de arranque limpia daemons PM2 previos, libera el puerto `3500`, usa el PM2 local de `node_modules` e inicia el agente con:

```bat
node_modules\.bin\pm2.cmd startOrReload ecosystem.config.cjs --env production
```

Los logs del arranque automatico quedan en:

```txt
C:\securlife-printer-agent\tmp
```

Para quitar el autoarranque y detener el agente PM2, ejecuta desde CMD como Administrador:

```bat
C:\securlife-printer-agent\scripts\uninstall-auto-start-cmd.cmd
```

Tambien puedes usar:

```bat
C:\securlife-printer-agent\Desinstalar-Autoarranque.bat
```

Si PM2 muestra `connect EPERM //./pipe/rpc.sock` o `connect EPERM //./pipe/interactor.sock`, normalmente hay un daemon PM2 levantado como Administrador y otro como usuario normal. El arranque automatico ya intenta limpiarlo, pero tambien puedes ejecutar manualmente:

```bat
C:\securlife-printer-agent\scripts\reset-pm2-eperm.cmd
```

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
