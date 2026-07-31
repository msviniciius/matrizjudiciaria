import { createRoot } from "react-dom/client"
import { InternalCalendarApp } from "../internal_calendar/InternalCalendarApp"

const rootElement = document.getElementById("react-internal-calendar-root")

if (rootElement) {
  createRoot(rootElement).render(<InternalCalendarApp />)
}
