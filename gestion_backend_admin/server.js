// server.js
import express from "express";
import cors from "cors";
import helmet from "helmet";
import dotenv from "dotenv";
import rateLimit from "express-rate-limit";
import { createClient } from "@supabase/supabase-js";
import crypto from "crypto";

dotenv.config();

// ===============================
// 🔧 CONFIGURACIÓN BASE
// ===============================
const app = express();

// ✅ Seguridad HTTP OWASP
app.use(
  helmet({
    contentSecurityPolicy: false,
    crossOriginEmbedderPolicy: false,
  })
);

// ✅ CORS restringido — ajusta FRONTEND_URL si ya tienes uno desplegado
app.use(
  cors({
    origin: process.env.FRONTEND_URL || "*",
    methods: ["POST"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// ✅ Límite de peticiones
app.use(
  rateLimit({
    windowMs: 60 * 1000, // 1 min
    max: 60, // 60 req/min
    message: "Demasiadas solicitudes. Intente nuevamente más tarde.",
  })
);

app.use(express.json({ limit: "10kb" }));

// ===============================
// 🧩 SUPABASE CLIENTE
// ===============================
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY,
  {
    global: {
      headers: {
        apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
    },
  }
);

console.log("✅ Supabase conectado:", process.env.SUPABASE_URL);

// ===============================
// 🔐 MIDDLEWARE DE AUTORIZACIÓN
// ===============================
app.use((req, res, next) => {
  const authHeader = req.headers.authorization;
  if (authHeader !== `Bearer ${process.env.ADMIN_API_KEY}`) {
    console.warn("❌ Acceso no autorizado desde IP:", req.ip);
    return res.status(403).json({ error: "Acceso denegado" });
  }
  next();
});

// ===============================
// 🧼 Sanitización de entradas
// ===============================
function sanitize(value = "") {
  return String(value).replace(/[<>;'"/\\]/g, "").trim();
}

// ===============================
// ⚙️ GENERADOR DE CONTRASEÑAS FUERTES
// ===============================
function generarPasswordFuerte() {
  return crypto.randomBytes(12).toString("base64url"); // 16+ chars seguros
}

// ===============================
// 🔹 ENDPOINT: CREAR USUARIO
// ===============================
app.post("/create-user", async (req, res) => {
  try {
    const name = sanitize(req.body.name);
    const password = sanitize(req.body.password);
    const role = sanitize(req.body.role || "doctor");
    const email = `${name}@local.app`;

    if (!name || !password) throw new Error("Campos vacíos");

    // 1️⃣ Crear usuario en Supabase Auth
    const { data: created, error: authError } = await supabase.auth.admin.createUser({
      email,
      password,
      email_confirm: true, // omite confirmación por correo
    });
    if (authError) throw authError;

    // 2️⃣ Insertar metadatos en tabla pública `users`
    const { error: insertError } = await supabase.from("users").upsert(
      {
        name,
        role,
        specialty: role === "doctor" ? "General" : null,
        area: role === "encargado" ? "Farmacia Central" : null,
        updated_at: new Date().toISOString(),
      },
      { onConflict: "name" }
    );
    if (insertError) throw insertError;

    console.log(`✅ Usuario ${name} (${role}) creado correctamente.`);
    res.json({
      message: "Usuario creado correctamente",
      email,
      password,
      role,
    });
  } catch (e) {
    console.error("❌ Error en /create-user:", e.message);
    res.status(400).json({ error: "No se pudo crear el usuario" });
  }
});

// ===============================
// 🔹 ENDPOINT: RESETEAR CONTRASEÑA
// ===============================
app.post("/reset-password", async (req, res) => {
  try {
    const email = sanitize(req.body.email);
    const tempPassword = generarPasswordFuerte();

    const { data, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) throw listError;

    const target = data.users.find((u) => u.email === email);
    if (!target) throw new Error(`Usuario ${email} no encontrado`);

    const { error: updateError } = await supabase.auth.admin.updateUserById(target.id, {
      password: tempPassword,
    });
    if (updateError) throw updateError;

    console.log(`🔄 Contraseña restablecida para ${email}`);
    res.json({
      message: `Contraseña restablecida`,
      email,
      newPassword: tempPassword,
    });
  } catch (e) {
    console.error("❌ Error en reset-password:", e.message);
    res.status(400).json({ error: "No se pudo restablecer la contraseña" });
  }
});

// ===============================
// 🔹 ENDPOINT: ELIMINAR USUARIO
// ===============================
app.post("/delete-user", async (req, res) => {
  try {
    const email = sanitize(req.body.email);
    const { data, error: listError } = await supabase.auth.admin.listUsers();
    if (listError) throw listError;

    const target = data.users.find((u) => u.email === email);
    if (!target) throw new Error(`Usuario ${email} no encontrado`);

    const { error: deleteError } = await supabase.auth.admin.deleteUser(target.id);
    if (deleteError) throw deleteError;

    console.log(`🗑️ Usuario eliminado: ${email}`);
    res.json({ message: `Usuario ${email} eliminado` });
  } catch (e) {
    console.error("❌ Error en delete-user:", e.message);
    res.status(400).json({ error: "No se pudo eliminar el usuario" });
  }
});

// ===============================
// 🔹 ENDPOINT: ACTIVAR MFA
// ===============================
app.post("/enable-mfa", async (req, res) => {
  try {
    const email = sanitize(req.body.email);
    res.json({
      message: `El usuario ${email} debe activar MFA desde su aplicación (limitación actual de Supabase).`,
    });
  } catch {
    res.status(400).json({ error: "Error procesando MFA" });
  }
});

// ===============================
// 🚀 Iniciar servidor
// ===============================
const PORT = process.env.PORT || 4000;
app.listen(PORT, () => {
  console.log(`🚀 Backend Admin corriendo en http://localhost:${PORT}`);
});


// npm start para iniciar el servidor





// import express from "express";
// import cors from "cors";
// import helmet from "helmet";
// import dotenv from "dotenv";
// import rateLimit from "express-rate-limit";
// import { createClient } from "@supabase/supabase-js";
// import crypto from "crypto";

// dotenv.config();

// // ===============================
// // 🔧 CONFIGURACIÓN BASE
// // ===============================
// const app = express();

// // ✅ Seguridad básica de cabeceras (OWASP)
// app.use(helmet({
//   contentSecurityPolicy: false,
//   crossOriginEmbedderPolicy: false,
// }));

// // ✅ CORS restringido (ajusta según tu frontend)
// app.use(cors({
//   origin: process.env.FRONTEND_URL || "*",
//   methods: ["POST"],
//   allowedHeaders: ["Content-Type", "Authorization"],
// }));

// // ✅ Rate limiting para evitar ataques de fuerza bruta
// app.use(rateLimit({
//   windowMs: 1 * 60 * 1000, // 1 minuto
//   max: 60, // 60 req/min
//   message: "Demasiadas solicitudes, intenta de nuevo en un minuto.",
// }));

// app.use(express.json({ limit: "10kb" })); // evita payloads enormes

// // ===============================
// // 🧩 SUPABASE CLIENTE
// // ===============================
// const supabase = createClient(
//   process.env.SUPABASE_URL,
//   process.env.SUPABASE_SERVICE_ROLE_KEY,
//   {
//     global: {
//       headers: {
//         apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
//         Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
//       },
//     },
//   }
// );

// console.log("✅ Supabase conectado con URL:", process.env.SUPABASE_URL);
// console.log("🔑 Longitud de Service Role Key:", process.env.SUPABASE_SERVICE_ROLE_KEY?.length);

// // ===============================
// // 🔐 Middleware de autenticación
// // ===============================
// app.use((req, res, next) => {
//   const authHeader = req.headers.authorization;
//   if (authHeader !== `Bearer ${process.env.ADMIN_API_KEY}`) {
//     console.warn("❌ Acceso denegado desde IP:", req.ip);
//     return res.status(403).json({ error: "Acceso denegado" });
//   }
//   next();
// });

// // ===============================
// // 🧼 Sanitización básica de entrada
// // ===============================
// function sanitize(value = "") {
//   return String(value).replace(/[<>;'"/\\]/g, "").trim();
// }

// // ===============================
// // 🔐 ENDPOINT: Resetear contraseña
// // ===============================
// app.post("/reset-password", async (req, res) => {
//   try {
//     const email = sanitize(req.body.email);
//     if (!email.includes("@")) throw new Error("Correo inválido");

//     const tempPassword = generarPasswordFuerte();

//     const { data, error: listError } = await supabase.auth.admin.listUsers();
//     if (listError) throw listError;

//     const target = data.users.find((u) => u.email === email);
//     if (!target) throw new Error(`Usuario ${email} no encontrado`);

//     const { error: updateError } = await supabase.auth.admin.updateUserById(target.id, {
//       password: tempPassword,
//     });
//     if (updateError) throw updateError;

//     console.log(`🔄 Contraseña restablecida para ${email}`);
//     res.json({
//       message: `Contraseña restablecida correctamente`,
//       email,
//       newPassword: tempPassword,
//     });
//   } catch (e) {
//     console.error("❌ Error en reset-password:", e);
//     res.status(400).json({ error: "No se pudo restablecer la contraseña" });
//   }
// });

// // ===============================
// // 🔐 ENDPOINT: Eliminar usuario
// // ===============================
// app.post("/delete-user", async (req, res) => {
//   try {
//     const email = sanitize(req.body.email);
//     if (!email.includes("@")) throw new Error("Correo inválido");

//     const { data, error: listError } = await supabase.auth.admin.listUsers();
//     if (listError) throw listError;

//     const target = data.users.find((u) => u.email === email);
//     if (!target) throw new Error(`Usuario ${email} no encontrado`);

//     const { error: deleteError } = await supabase.auth.admin.deleteUser(target.id);
//     if (deleteError) throw deleteError;

//     console.log(`🗑️ Usuario eliminado: ${email}`);
//     res.json({ message: `Usuario ${email} eliminado` });
//   } catch (e) {
//     console.error("❌ Error en delete-user:", e);
//     res.status(400).json({ error: "No se pudo eliminar el usuario" });
//   }
// });

// // ===============================
// // 🔐 ENDPOINT: Activar MFA
// // ===============================
// app.post("/enable-mfa", async (req, res) => {
//   try {
//     const email = sanitize(req.body.email);
//     res.json({
//       message: `El usuario ${email} debe activar MFA desde su aplicación (limitación actual de Supabase).`,
//     });
//   } catch (e) {
//     res.status(400).json({ error: "Error procesando MFA" });
//   }
// });

// // ===============================
// // 🔐 Función auxiliar: password fuerte
// // ===============================
// function generarPasswordFuerte() {
//   return crypto.randomBytes(12).toString("base64url"); // 16+ chars, seguro
// }

// // ===============================
// // 🚀 Iniciar servidor
// // ===============================
// const PORT = process.env.PORT || 4000;
// app.listen(PORT, () => {
//   console.log(`🚀 Backend Admin corriendo en http://localhost:${PORT}`);
// });
