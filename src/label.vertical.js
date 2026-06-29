const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const { mmToPt } = require('./mm');
const { getBlackAndWhiteVisitorPhotoBuffer } = require('./image');

async function createVisitLabelPdf(data, outputPath) {
  const widthMm = Number(process.env.LABEL_WIDTH_MM || 62);
  const heightMm = Number(process.env.LABEL_HEIGHT_MM || 80);
  const doc = new PDFDocument({
    size: [mmToPt(widthMm), mmToPt(heightMm)],
    margin: mmToPt(3)
  });

  await fs.promises.mkdir(path.dirname(outputPath), { recursive: true });
  const stream = fs.createWriteStream(outputPath);
  doc.pipe(stream);

  const pageWidth = mmToPt(widthMm);
  const pageHeight = mmToPt(heightMm);
  const margin = mmToPt(3);
  const contentWidth = pageWidth - margin * 2;
  const visitante = `${data.visitante || data.nombre || 'Visitante'}`.toUpperCase();
  const empresa = `${data.empresa || ''}`.toUpperCase();
  const motivo = `${data.motivo || 'Visita'}`.toUpperCase();
  const anfitrion = `${data.anfitrion || ''}`.toUpperCase();
  const departamento = `${data.departamento || data.depto || ''}`.toUpperCase();
  const gafete = `${data.gafete || data.folio || ''}`.toUpperCase();
  const fecha = `${data.fecha || new Date().toLocaleDateString('es-MX')}`.toUpperCase();
  const footer = `${data.ubicacion || ''}`.toUpperCase();

  const fitText = (text, x, y, options = {}) => {
    const {
      width = contentWidth,
      maxSize = 16,
      minSize = 8,
      align = 'left',
      font = 'Helvetica-Bold',
      height
    } = options;
    let fontSize = maxSize;

    doc.font(font).fontSize(fontSize);
    while (fontSize > minSize && doc.widthOfString(text) > width) {
      fontSize -= 0.5;
      doc.fontSize(fontSize);
    }

    doc.text(text, x, y, {
      width,
      align,
      height,
      ellipsis: true
    });

    return fontSize;
  };

  fitText(visitante, margin, mmToPt(4), {
    maxSize: 17,
    minSize: 10,
    align: 'center'
  });

  fitText(gafete || 'S/G', margin, mmToPt(16), {
    width: contentWidth * 0.35,
    maxSize: 15,
    minSize: 10
  });

  fitText(fecha, margin + contentWidth * 0.35, mmToPt(16), {
    width: contentWidth * 0.65,
    maxSize: 15,
    minSize: 9,
    align: 'right'
  });

  doc.moveTo(margin, mmToPt(25)).lineTo(pageWidth - margin, mmToPt(25)).stroke();

  const drawLine = (label, value, y) => {
    doc.font('Helvetica-Bold').fontSize(8).text(`${label}:`, margin, y, {
      width: mmToPt(12)
    });
    fitText(value || '-', margin + mmToPt(13), y, {
      width: contentWidth - mmToPt(13),
      maxSize: 8,
      minSize: 6,
      font: 'Helvetica-Bold'
    });
  };

  drawLine('Emp.', empresa || 'SIN EMPRESA', mmToPt(29));
  drawLine('Con', anfitrion || '-', mmToPt(35));
  drawLine('Depto.', departamento || '-', mmToPt(41));
  drawLine('Motivo', motivo || '-', mmToPt(47));

  const photoBuffer = await getBlackAndWhiteVisitorPhotoBuffer(data);
  if (photoBuffer) {
    try {
      doc.image(photoBuffer, pageWidth - margin - mmToPt(18), mmToPt(55), {
        fit: [mmToPt(18), mmToPt(18)],
        align: 'center',
        valign: 'center'
      });
    } catch (error) {
      console.warn(`No se pudo colocar foto de visitante en etiqueta: ${error.message}`);
    }
  } else if (data.qr) {
    const qrBuffer = await QRCode.toBuffer(data.qr, { margin: 0, width: 72 });
    doc.image(qrBuffer, pageWidth - margin - mmToPt(13), pageHeight - margin - mmToPt(13), {
      width: mmToPt(13),
      height: mmToPt(13)
    });
  }

  if (footer) {
    fitText(footer, margin, pageHeight - margin - mmToPt(4), {
      width: contentWidth - (photoBuffer || data.qr ? mmToPt(16) : 0),
      maxSize: 7,
      minSize: 5,
      font: 'Helvetica-Bold'
    });
  }

  doc.end();

  return new Promise((resolve, reject) => {
    stream.on('finish', () => resolve(outputPath));
    stream.on('error', reject);
  });
}

module.exports = { createVisitLabelPdf };
