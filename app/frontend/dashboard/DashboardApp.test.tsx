import "@testing-library/jest-dom/vitest"
import { render, screen } from "@testing-library/react"
import { DashboardApp } from "./DashboardApp"

test("shows an accessible loading state before the dashboard snapshot arrives", () => {
  render(<DashboardApp />)

  expect(screen.getByRole("status")).toHaveTextContent("Carregando painel")
})
