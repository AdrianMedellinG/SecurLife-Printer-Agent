# Koders Printer Agent - Brother QL-800 / QL-810W

Agente local para imprimir etiquetas de visitas desde un sistema React web en Internet.

## Requisitos en Windows 11

1. Instalar el driver oficial Brother QL-800 / QL-810W.
2. Configurar el rollo como `DK 62mm Continuous` / `62mm x Continuous`.
3. Instalar Node.js LTS.
4. Ejecutar este agente en la PC donde está conectada la impresora.

## Instalación

```bash
npm install
copy .env.example .env
npm run list-printers
```

### Instalación automática en Windows

Desde PowerShell o CMD como Administrador, ejecuta:

```bat
scripts\install-node-and-copy.cmd
```

Ese script instala Node.js LTS con npm si no existen, copia el proyecto a `C:\koders-printer-agent` sin copiar `node_modules`, `.git` ni `tmp`, y ejecuta `npm ci --omit=dev` en la carpeta final. PM2 se instala como dependencia local del proyecto.

Para usar otra ruta:

```bat
scripts\install-node-and-copy.cmd -TargetPath "C:\otra-carpeta"
```

Después activa el inicio automático:

```bat
C:\koders-printer-agent\scripts\setup-auto-start.cmd
```

Por defecto se crea una tarea programada que levanta el proceso con PM2 cuando inicia sesión el usuario de Windows. Esto suele ser lo más confiable para impresoras instaladas en el perfil del usuario. Si necesitas que la tarea se dispare al arranque del sistema, usa:

```bat
C:\koders-printer-agent\scripts\setup-auto-start.cmd -Trigger AtStartup
```

Los logs del arranque automático quedan en:

```txt
C:\koders-printer-agent\tmp
```

## PM2

El proyecto incluye `ecosystem.config.cjs` para ejecutar el agente con PM2:

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
C:\koders-printer-agent\tmp\pm2-out.log
C:\koders-printer-agent\tmp\pm2-error.log
```

Edita `.env` y coloca el nombre exacto de la impresora:

```env
PRINTER_NAME=Brother QL-800
ALLOWED_ORIGIN=https://tu-dominio.com
BODY_LIMIT=5mb
LABEL_WIDTH_MM=62
LABEL_HEIGHT_MM=80
PRINT_SCALE=noscale
PRINTER_PAPER_SIZE=
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
    empresa: 'Koders',
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
