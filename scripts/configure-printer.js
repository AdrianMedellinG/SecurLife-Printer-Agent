const fs = require("fs");
const path = require("path");
const readline = require("readline");
const printer = require("pdf-to-printer");

const envPath = path.resolve(__dirname, "..", ".env");

function setEnvValue(content, key, value) {
  const escaped = value.replace(/\r?\n/g, " ").trim();
  const line = `${key}=${escaped}`;
  const regex = new RegExp(`^${key}=.*$`, "m");

  if (regex.test(content)) {
    return content.replace(regex, line);
  }

  const suffix = content.endsWith("\n") ? "" : "\n";
  return `${content}${suffix}${line}\n`;
}

function ask(question) {
  const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
  });

  return new Promise((resolve) => {
    rl.question(question, (answer) => {
      rl.close();
      resolve(answer.trim());
    });
  });
}

(async () => {
  const printers = await printer.getPrinters();

  if (!printers.length) {
    console.error("No se encontraron impresoras instaladas en Windows.");
    process.exit(1);
  }

  console.log("");
  console.log("Impresoras detectadas:");
  printers.forEach((item, index) => {
    const marker = item.isDefault ? " (predeterminada)" : "";
    console.log(`${index + 1}) ${item.name}${marker}`);

    if (Array.isArray(item.paperSizes) && item.paperSizes.length) {
      console.log(`   Papel: ${item.paperSizes.join(", ")}`);
    }
  });
  console.log("");

  const answer = await ask("Selecciona el numero de la impresora para PRINTER_NAME: ");
  const selectedIndex = Number(answer) - 1;

  if (!Number.isInteger(selectedIndex) || selectedIndex < 0 || selectedIndex >= printers.length) {
    console.error("Seleccion invalida.");
    process.exit(1);
  }

  const selectedPrinter = printers[selectedIndex].name;

  if (!fs.existsSync(envPath)) {
    const examplePath = path.resolve(__dirname, "..", ".env.example");
    if (!fs.existsSync(examplePath)) {
      console.error("No existe .env ni .env.example.");
      process.exit(1);
    }

    fs.copyFileSync(examplePath, envPath);
  }

  const currentEnv = fs.readFileSync(envPath, "utf8");
  const nextEnv = setEnvValue(currentEnv, "PRINTER_NAME", selectedPrinter);
  fs.writeFileSync(envPath, nextEnv);

  console.log("");
  console.log(`PRINTER_NAME actualizado en .env: ${selectedPrinter}`);
})().catch((error) => {
  console.error(error);
  process.exit(1);
});
