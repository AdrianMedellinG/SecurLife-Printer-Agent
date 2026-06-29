require('dotenv').config();

const fs = require('fs');  
const path = require('path');
const express = require('express');
const cors = require('cors');
const printer = require('pdf-to-printer');
const { createVisitLabelPdf } = require('./label');

const app = express();
const port = Number(process.env.PORT || 3500);
const bodyLimit = process.env.BODY_LIMIT || '5mb';
const allowedOrigin = process.env.ALLOWED_ORIGIN || '*';
const allowedOrigins = allowedOrigin
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.use(express.json({ limit: bodyLimit }));
app.use(cors({
  origin(origin, callback) {
    if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }

    try {
      const { hostname } = new URL(origin);
      if (allowedOrigins.includes(hostname)) return callback(null, true);
    } catch (_error) {
      // Keep the generic CORS error below.
    }

    return callback(new Error('Origen no permitido por el agente de impresion'));
  }
}));

app.get('/health', (req, res) => {
  res.json({ ok: true, service: 'securlife-printer-agent' });
});

app.get('/printers', async (req, res) => {
  const printers = await printer.getPrinters();
  res.json({ printers });
});

async function printVisitLabel(payload, res) {
  if (!payload.visitante && !payload.nombre) {
    return res.status(400).json({
      ok: false,
      error: 'Falta visitante o nombre'
    });
  }

  const filename = `visit-label-${Date.now()}.pdf`;
  const pdfPath = path.join(__dirname, '..', 'tmp', filename);

  try {
    await createVisitLabelPdf(payload, pdfPath);

    const options = {
      pages: '1',
      copies: 1,
      scale: 'noscale'
    };

    if (payload.printerName || process.env.PRINTER_NAME)
      options.printer = payload.printerName || process.env.PRINTER_NAME;

    if (process.env.PRINTER_PAPER_SIZE)
      options.paperSize = process.env.PRINTER_PAPER_SIZE;

    await printer.print(pdfPath, options);

    res.json({
      ok: true,
      printed: true
    });

  } catch (error) {
    res.status(500).json({
      ok: false,
      error: error.message
    });

  } finally {
    try {
      await fs.promises.unlink(pdfPath);
      console.log(`PDF temporal eliminado: ${pdfPath}`);
    } catch (_) {
      // Ignorar si no existe
    }
  }
}

app.post('/print-visit-label', async (req, res) => {
  await printVisitLabel(req.body || {}, res);
});

app.post('/test-print', async (req, res) => {
  await printVisitLabel({
    visitante: 'PRUEBA DE IMPRESORA',
    nombre: 'PRUEBA DE IMPRESORA',
    gafete: 'TEST',
    folio: 'TEST',
    empresa: 'SECURELIFE',
    motivo: 'CONFIGURACION LOCAL',
    anfitrion: 'SISTEMA',
    departamento: 'VISITAS',
    fecha: new Date().toLocaleString('es-MX', {
      dateStyle: 'short',
      timeStyle: 'short'
    }),
    ubicacion: 'PRUEBA',
    qr: `securelife-printer-test-${Date.now()}`,
    printerName: req.body?.printerName
  }, res);
});

app.listen(port, () => {
  console.log(`SecurLife Printer Agent en http://localhost:${port}`);
});
