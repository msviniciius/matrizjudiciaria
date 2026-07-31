import { createRoot } from "react-dom/client"
import { TasksApp } from "../tasks/TasksApp"

const rootElement = document.getElementById("react-tasks-root")
if (rootElement) createRoot(rootElement).render(<TasksApp />)
