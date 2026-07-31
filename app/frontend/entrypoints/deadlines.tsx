import { createRoot } from "react-dom/client"
import { DeadlinesApp } from "../deadlines/DeadlinesApp"

const rootElement = document.getElementById("react-deadlines-root")

if (rootElement) {
  createRoot(rootElement).render(<DeadlinesApp />)
}
