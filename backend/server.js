import express from "express"
import mongoose from "mongoose"
import cors from "cors"
import dotenv from "dotenv"
import client from "prom-client"
import { readFileSync } from "fs"

import userRouter from "./routes/userRoute.js"
import taskRouter from "./routes/taskRoute.js"
import forgotPasswordRouter from "./routes/forgotPassword.js"

//app config
dotenv.config()
const app = express()

// Doc version tu package.json de /health bao duoc phien ban dang chay.
// Huu ich khi kiem tra xem CI/CD da deploy ban moi len VPS chua.
const pkg = JSON.parse(readFileSync(new URL("./package.json", import.meta.url)))
const port = process.env.PORT || 8000
mongoose.set('strictQuery', true);

//middlewares
app.use(express.json())
app.use(cors({ origin: (process.env.CORS_ORIGIN || "*").split(",") }))

//prometheus metrics
const register = new client.Registry()
register.setDefaultLabels({ app: "todo-backend" })
client.collectDefaultMetrics({ register })

const httpRequestDuration = new client.Histogram({
    name: "http_request_duration_seconds",
    help: "Thoi gian xu ly request theo method/route/status",
    labelNames: ["method", "route", "status_code"],
    buckets: [0.05, 0.1, 0.3, 0.5, 1, 2, 5],
    registers: [register],
})

const mongoUp = new client.Gauge({
    name: "todo_mongodb_up",
    help: "1 = backend dang ket noi duoc MongoDB, 0 = mat ket noi",
    registers: [register],
})

app.use((req, res, next) => {
    const end = httpRequestDuration.startTimer()
    res.on("finish", () => {
        end({
            method: req.method,
            route: req.route?.path || req.baseUrl || req.path,
            status_code: res.statusCode,
        })
    })
    next()
})

//db config - retry de container doi MongoDB khoi dong xong
const connectDB = async (retries = 10, delayMs = 5000) => {
    for (let i = 1; i <= retries; i++) {
        try {
            await mongoose.connect(process.env.MONGO_URI, {
                useNewUrlParser: true,
                serverSelectionTimeoutMS: 5000,
            })
            console.log("DB Connected")
            return
        } catch (err) {
            console.error(`DB connect that bai (lan ${i}/${retries}): ${err.message}`)
            if (i === retries) throw err
            await new Promise((r) => setTimeout(r, delayMs))
        }
    }
}

mongoose.connection.on("connected", () => mongoUp.set(1))
mongoose.connection.on("disconnected", () => mongoUp.set(0))
mongoose.connection.on("error", () => mongoUp.set(0))

//health & metrics endpoints
app.get("/health", (req, res) => {
    const dbState = mongoose.connection.readyState // 1 = connected
    res.status(dbState === 1 ? 200 : 503).json({
        status: dbState === 1 ? "ok" : "degraded",
        version: pkg.version,
        db: ["disconnected", "connected", "connecting", "disconnecting"][dbState],
        uptime: process.uptime(),
    })
})

app.get("/metrics", async (req, res) => {
    res.set("Content-Type", register.contentType)
    res.end(await register.metrics())
})

//api endpoints
app.use("/api/user", userRouter)
app.use("/api/task", taskRouter)
app.use("/api/forgotPassword", forgotPasswordRouter)

//listen
const server = app.listen(port, () => console.log(`Listening on port ${port}`))
connectDB().catch((err) => {
    console.error("Khong the ket noi MongoDB, thoat:", err.message)
    server.close(() => process.exit(1))
})

//graceful shutdown cho docker stop
const shutdown = async (signal) => {
    console.log(`${signal} received, dang tat server...`)
    server.close(async () => {
        await mongoose.connection.close()
        process.exit(0)
    })
}
process.on("SIGTERM", () => shutdown("SIGTERM"))
process.on("SIGINT", () => shutdown("SIGINT"))
