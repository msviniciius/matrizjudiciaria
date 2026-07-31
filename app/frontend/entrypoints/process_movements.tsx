import { createRoot } from "react-dom/client"
import { ProcessMovementsApp } from "../process_movements/ProcessMovementsApp"

const rootElement = document.getElementById("react-process-movements-root")

if (rootElement) {
  createRoot(rootElement).render(<ProcessMovementsApp />)
}
