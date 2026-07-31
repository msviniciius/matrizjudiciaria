import { createRoot } from "react-dom/client"
import { ClientShowApp } from "../client_show/ClientShowApp"

const rootElement = document.getElementById("react-client-show-root")

if (rootElement) {
  createRoot(rootElement).render(<ClientShowApp />)
}
