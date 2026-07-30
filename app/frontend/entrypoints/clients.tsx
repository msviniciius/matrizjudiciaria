import { createRoot } from "react-dom/client"
import { ClientsApp } from "../clients/ClientsApp"

const rootElement = document.getElementById("react-clients-root")

if (rootElement) {
  createRoot(rootElement).render(<ClientsApp />)
}
