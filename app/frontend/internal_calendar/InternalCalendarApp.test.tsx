import "@testing-library/jest-dom/vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { InternalCalendarApp } from "./InternalCalendarApp"

const eventWith = (title: string, overrides = {}) => ({
  type: "deadline",
  type_label: "Prazo",
  date: "2026-07-31",
  date_label: "31/07/2026",
  time: null,
  time_label: "-",
  title,
  process_label: "PROC-001",
  detail: "Judicial",
  url: "/deadlines/1",
  display_title: `${title} - PROC-001`,
  ...overrides
})

const snapshotWith = (overrides = {}) => {
  const event = eventWith("Prazo de teste")
  return {
    meta: {
      view_mode: "month",
      reference_month: "2026-07",
      month_label: "Julho de 2026",
      today_month: "2026-07",
      total_count: 1
    },
    weekdays: ["Seg", "Ter", "Qua", "Qui", "Sex", "Sáb", "Dom"],
    weeks: [[
      { date: "2026-07-27", day_number: 27, outside_month: false, today: false, events: [] },
      { date: "2026-07-28", day_number: 28, outside_month: false, today: false, events: [] },
      { date: "2026-07-29", day_number: 29, outside_month: false, today: false, events: [] },
      { date: "2026-07-30", day_number: 30, outside_month: false, today: true, events: [] },
      { date: "2026-07-31", day_number: 31, outside_month: false, today: false, events: [event] },
      { date: "2026-08-01", day_number: 1, outside_month: true, today: false, events: [] },
      { date: "2026-08-02", day_number: 2, outside_month: true, today: false, events: [] }
    ]],
    events: [event],
    actions: {
      index: "/calendario_interno",
      month: "/calendario_interno?month=2026-07&view=month",
      list: "/calendario_interno?month=2026-07&view=list",
      previous_month: "/calendario_interno?month=2026-06&view=month",
      next_month: "/calendario_interno?month=2026-08&view=month",
      today: "/calendario_interno?month=2026-07&view=month",
      google_calendar: "https://calendar.google.com/calendar/r?cid=webcal%3A%2F%2Fexample.test%2Ffeed.ics"
    },
    ...overrides
  }
}

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  window.history.replaceState({}, "", "/calendario_interno")
})

test("renders the internal calendar month view", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<InternalCalendarApp />)

  expect(await screen.findByRole("heading", { name: "Calendário interno" })).toBeVisible()
  expect(screen.getByRole("status")).toHaveTextContent("Julho de 2026")
  expect(screen.getByRole("link", { name: "Prazo de teste - PROC-001" })).toHaveAttribute("href", "/deadlines/1")
  expect(screen.getByRole("link", { name: "Assinar no Google Calendar" })).toHaveAttribute("href", expect.stringContaining("calendar.google.com"))
})

test("switches to list view and updates the URL", async () => {
  const listSnapshot = snapshotWith({ meta: { ...snapshotWith().meta, view_mode: "list" } })
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockResolvedValueOnce(okResponse(listSnapshot))
  )

  render(<InternalCalendarApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Lista" }))

  expect(await screen.findByRole("table", { name: "Lista do calendário interno" })).toBeVisible()
  expect(new URLSearchParams(window.location.search).get("view")).toBe("list")
})

test("navigates between months using the snapshot actions", async () => {
  const nextSnapshot = snapshotWith({
    meta: { ...snapshotWith().meta, reference_month: "2026-08", month_label: "Agosto de 2026" },
    events: [],
    weeks: [],
    actions: { ...snapshotWith().actions, previous_month: "/calendario_interno?month=2026-07&view=month", next_month: "/calendario_interno?month=2026-09&view=month" }
  })
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockResolvedValueOnce(okResponse(nextSnapshot))
  )

  render(<InternalCalendarApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Próximo mês" }))

  expect(await screen.findByRole("status")).toHaveTextContent("Agosto de 2026")
  expect(new URLSearchParams(window.location.search).get("month")).toBe("2026-08")
})

test("shows error retry and empty list state", async () => {
  const emptyList = snapshotWith({ meta: { ...snapshotWith().meta, view_mode: "list", total_count: 0 }, events: [] })
  vi.stubGlobal("fetch", vi.fn()
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(emptyList))
  )

  render(<InternalCalendarApp />)

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível atualizar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByText("Nenhum item no período selecionado.")).toBeVisible()
})
