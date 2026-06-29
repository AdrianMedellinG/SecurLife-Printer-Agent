const sharp = require('sharp');

function getVisitorPhotoInput(data) {
  const imageValue = data.fotoVisitante || data.foto || data.photoBase64 || data.visitorPhotoBase64;
  if (!imageValue || typeof imageValue !== 'string') return null;

  const dataUrlMatch = imageValue.match(/^data:([^;]+);base64,(.+)$/);
  const base64 = dataUrlMatch ? dataUrlMatch[2] : imageValue;

  try {
    return Buffer.from(base64, 'base64');
  } catch (_error) {
    return null;
  }
}

async function getBlackAndWhiteVisitorPhotoBuffer(data) {
  const photoBuffer = getVisitorPhotoInput(data);
  if (!photoBuffer) return null;

  try {
    return await sharp(photoBuffer)
      .rotate()
      .grayscale()
      .jpeg({ quality: 90 })
      .toBuffer();
  } catch (error) {
    console.warn(`No se pudo convertir foto de visitante a blanco y negro: ${error.message}`);
    return photoBuffer;
  }
}

module.exports = { getBlackAndWhiteVisitorPhotoBuffer };
