const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const QRCode = require('qrcode');
const { mmToPt } = require('./mm');
const { getBlackAndWhiteVisitorPhotoBuffer } = require('./image');

async function createVisitLabelPdf(data, outputPath) {
  const widthMm = Number(process.env.LABEL_WIDTH_MM || 100);
  const heightMm = Number(process.env.LABEL_HEIGHT_MM || 62);

  const doc = new PDFDocument({
    size: [mmToPt(widthMm), mmToPt(heightMm)],
    margin: 0
  });

  await fs.promises.mkdir(path.dirname(outputPath), { recursive: true });
  const stream = fs.createWriteStream(outputPath);
  doc.pipe(stream);

  const pageWidth = mmToPt(widthMm);
  const pageHeight = mmToPt(heightMm);

  const visitante = `${data.visitante || data.nombre || 'Visitante'}`.toUpperCase();
  const empresa = `${data.empresa || ''}`.toUpperCase();
  const motivo = `${data.motivo || 'Visita'}`.toUpperCase();
  const anfitrion = `${data.anfitrion || ''}`.toUpperCase();
  const departamento = `${data.departamento || data.depto || ''}`.toUpperCase();
  const gafete = `${data.gafete || data.folio || ''}`.toUpperCase();
  const fecha = `${data.fecha || new Date().toLocaleDateString('es-MX')}`.toUpperCase();
  const ubicacion = `${data.ubicacion || ''}`.toUpperCase();

  const fitText = (text, x, y, options = {}) => {
    const {
      width,
      maxSize = 16,
      minSize = 6,
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

  const margin = mmToPt(2);

  // Nombre principal centrado arriba
  fitText(visitante, margin, mmToPt(3.5), {
    width: pageWidth - margin * 2,
    maxSize: 15,
    minSize: 8,
    align: 'center'
  });

  // Empresa más arriba y centrada
  fitText(empresa, margin, mmToPt(8), {
    width: pageWidth - margin * 2,
    maxSize: 8,
    minSize: 5,
    align: 'center'
  });

  // Foto más abajo
  const photoX = mmToPt(4);
  const photoY = mmToPt(24);
  const photoW = mmToPt(31);
  const photoH = mmToPt(33);

  const rightX = mmToPt(39);
  const rightW = pageWidth - rightX - mmToPt(4);

  const photoBuffer = await getBlackAndWhiteVisitorPhotoBuffer(data);

  if (photoBuffer) {
    try {
      doc.image(photoBuffer, photoX, photoY, {
        fit: [photoW, photoH],
        align: 'center',
        valign: 'center'
      });
    } catch (error) {
      console.warn(`No se pudo colocar foto de visitante: ${error.message}`);
    }
  } else {
    doc.rect(photoX, photoY, photoW, photoH).stroke();
    fitText('SIN FOTO', photoX, photoY + mmToPt(15), {
      width: photoW,
      maxSize: 8,
      align: 'center'
    });
  }

  // Gafete y fecha más arriba
  fitText(gafete || 'S/G', rightX, mmToPt(13), {
    width: mmToPt(28),
    maxSize: 15,
    minSize: 9
  });

  fitText(fecha, rightX + mmToPt(35), mmToPt(13), {
    width: rightW - mmToPt(35),
    maxSize: 13,
    minSize: 8,
    align: 'right'
  });

  // Línea divisoria más arriba
  doc
.moveTo(rightX, mmToPt(24))
.lineTo(pageWidth - mmToPt(4), mmToPt(24))
    .lineWidth(1)
    .stroke();

  // QR fijo abajo
  const qrSize = mmToPt(16);
  const qrX = pageWidth - mmToPt(20);
  const qrY = pageHeight - mmToPt(19);

  const labelW = mmToPt(17);
  const valueX = rightX + labelW;
  const valueW = qrX - valueX - mmToPt(3);

  const drawLine = (label, value, y) => {
    doc.font('Helvetica-Bold').fontSize(6.5).text(`${label}:`, rightX, y, {
      width: labelW
    });

    fitText(value || '-', valueX, y, {
      width: valueW,
      maxSize: 6.5,
      minSize: 4.5,
      font: 'Helvetica-Bold'
    });
  };

  // Datos más arriba
drawLine('Con', anfitrion, mmToPt(28));
drawLine('Dep.', departamento, mmToPt(34));
drawLine('Motivo', motivo, mmToPt(40));

  // Ubicación se queda abajo
  fitText(ubicacion, rightX, mmToPt(55), {
    width: qrX - rightX - mmToPt(3),
    maxSize: 9,
    minSize: 6,
    font: 'Helvetica-Bold'
  });

  if (data.qr) {
    const qrBuffer = await QRCode.toBuffer(data.qr, {
      errorCorrectionLevel: 'H',
      margin: 0,
      width: 140
    });

    doc.image(qrBuffer, qrX, qrY, {
      width: qrSize,
      height: qrSize
    });

    const qrLogoPath = path.join(__dirname, 'logo.png');
    if (fs.existsSync(qrLogoPath)) {
      try {
        const logoSize = qrSize * 0.28;
        const logoPadding = mmToPt(0.55);
        const logoBoxSize = logoSize + logoPadding * 2;
        const logoBoxX = qrX + (qrSize - logoBoxSize) / 2;
        const logoBoxY = qrY + (qrSize - logoBoxSize) / 2;
        const logoX = qrX + (qrSize - logoSize) / 2;
        const logoY = qrY + (qrSize - logoSize) / 2;

        doc
          .roundedRect(logoBoxX, logoBoxY, logoBoxSize, logoBoxSize, mmToPt(0.8))
          .fill('#FFFFFF');

        doc.image(qrLogoPath, logoX, logoY, {
          fit: [logoSize, logoSize],
          align: 'center',
          valign: 'center'
        });
      } catch (error) {
        console.warn(`No se pudo colocar logo en QR: ${error.message}`);
      }
    }
  }

  doc.end();

  return new Promise((resolve, reject) => {
    stream.on('finish', () => resolve(outputPath));
    stream.on('error', reject);
  });
}

module.exports = { createVisitLabelPdf };
