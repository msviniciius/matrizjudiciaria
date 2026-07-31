import { createRoot } from "react-dom/client"
import { DashboardApp } from "../dashboard/DashboardApp"

const rootElement = document.getElementById("react-dashboard-root")

if (rootElement) {
  createRoot(rootElement).render(<DashboardApp />)
}
