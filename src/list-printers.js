const printer = require('pdf-to-printer');

(async () => {
  const printers = await printer.getPrinters();
  console.log(JSON.stringify(printers, null, 2));
})();
