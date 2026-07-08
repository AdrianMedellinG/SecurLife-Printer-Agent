const { execFile } = require('child_process');
const { promisify } = require('util');

const execFileAsync = promisify(execFile);

function normalizeList(value) {
  if (!value) return [];
  return Array.isArray(value) ? value : [value];
}

(async () => {
  const command = [
    'Get-CimInstance Win32_Printer -Property DeviceID,Name,PrinterPaperNames',
    'Select-Object DeviceID,Name,PrinterPaperNames',
    'ConvertTo-Json -Depth 4'
  ].join(' | ');

  const { stdout } = await execFileAsync(
    'powershell.exe',
    ['-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', command],
    { windowsHide: true, maxBuffer: 1024 * 1024 }
  );

  const parsed = stdout.trim() ? JSON.parse(stdout) : [];
  const printers = normalizeList(parsed).map((availablePrinter) => ({
    deviceId: availablePrinter.DeviceID || '',
    name: availablePrinter.Name || '',
    paperSizes: normalizeList(availablePrinter.PrinterPaperNames)
  }));

  console.log(JSON.stringify(printers, null, 2));
})();
