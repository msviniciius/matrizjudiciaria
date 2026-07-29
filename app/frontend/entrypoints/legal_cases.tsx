import { createRoot } from "react-dom/client"
import { LegalCasesApp } from "../legal_cases/LegalCasesApp"

const rootElement = document.getElementById("react-legal-cases-root")

if (rootElement) {
  createRoot(rootElement).render(<LegalCasesApp />)
}
