import { createRoot } from "react-dom/client"
import { LegalCaseShowApp } from "../legal_case_show/LegalCaseShowApp"

const rootElement = document.getElementById("react-legal-case-show-root")

if (rootElement) {
  createRoot(rootElement).render(<LegalCaseShowApp />)
}
