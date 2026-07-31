import { createRoot } from "react-dom/client"
import { ProcessMovementShowApp } from "../process_movement_show/ProcessMovementShowApp"

const rootElement = document.getElementById("react-process-movement-show-root")

if (rootElement) {
  createRoot(rootElement).render(<ProcessMovementShowApp />)
}
