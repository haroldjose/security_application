/**
 * Script seguro para rotar ADMIN_API_KEY automáticamente
 * Autor: Harold + ChatGPT Security Script (2025)
 */

import fs from "fs";
import crypto from "crypto";
import path from "path";
import { fileURLToPath } from "url";

// ====== CONFIGURACIÓN ======
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const envPath = path.join(__dirname, ".env");
const backupDir = path.join(__dirname, "backups");

// Crear clave aleatoria de 64 caracteres (256 bits)
const generateKey = () => crypto.randomBytes(32).toString("hex");

// Fecha ISO segura
const timestamp = new Date().toISOString().replace(/[:.]/g, "-");

// ====== 1️⃣ Validar existencia de .env ======
if (!fs.existsSync(envPath)) {
  console.error("❌ No se encontró el archivo .env. Asegúrate de estar en la carpeta correcta.");
  process.exit(1);
}

// ====== 2️⃣ Cargar contenido .env ======
const envData = fs.readFileSync(envPath, "utf-8");

// ====== 3️⃣ Extraer clave actual ======
const currentKeyMatch = envData.match(/ADMIN_API_KEY=(.*)/);
const currentKey = currentKeyMatch ? currentKeyMatch[1].trim() : null;

// ====== 4️⃣ Generar nueva clave segura ======
const newKey = generateKey();

// ====== 5️⃣ Crear carpeta de respaldo ======
if (!fs.existsSync(backupDir)) {
  fs.mkdirSync(backupDir);
}

// ====== 6️⃣ Guardar respaldo ======
const backupFile = path.join(backupDir, `env-backup-${timestamp}.txt`);
fs.writeFileSync(
  backupFile,
  `# Backup automático del archivo .env\n# Fecha: ${new Date().toISOString()}\n\n${envData}`,
  "utf-8"
);

// ====== 7️⃣ Reemplazar ADMIN_API_KEY ======
const updatedEnv = envData.replace(/ADMIN_API_KEY=.*/, `ADMIN_API_KEY=${newKey}`);
fs.writeFileSync(envPath, updatedEnv, "utf-8");

// ====== 8️⃣ Registrar log ======
const logEntry = `[${new Date().toISOString()}] ✅ ADMIN_API_KEY rotada correctamente.
Anterior: ${currentKey ? currentKey.slice(0, 6) + "..." : "(no definida)"}
Nueva: ${newKey.slice(0, 6)}...
Backup: ${backupFile}
---------------------------------------\n`;

fs.appendFileSync(path.join(__dirname, "rotation.log"), logEntry, "utf-8");

console.log("✅ ADMIN_API_KEY rotada correctamente.");
console.log("🆕 Nueva clave (oculta en logs por seguridad):", newKey.slice(0, 6) + "...");
console.log("📁 Backup guardado en:", backupFile);
