import axios from "axios"

// Base URL lay tu bien moi truong (CRA nhung vao bundle luc build).
// - Local:  http://localhost:8000/api
// - Docker/VPS: /api  (nginx cua frontend proxy sang backend)
const instance = axios.create({
    baseURL: process.env.REACT_APP_API_URL || "/api"
})

export default instance
