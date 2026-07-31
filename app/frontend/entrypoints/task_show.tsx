import React from "react"
import { createRoot } from "react-dom/client"
import { TaskShowApp } from "../task_show/TaskShowApp"

const rootElement = document.getElementById("react-task-show-root")
if (rootElement) createRoot(rootElement).render(<TaskShowApp />)
