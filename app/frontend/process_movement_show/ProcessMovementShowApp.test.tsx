import "@testing-library/jest-dom/vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { ProcessMovementShowApp } from "./ProcessMovementShowApp"

const snapshotWith = (overrides = {}) => ({
  movement: {
    id: 1,
    display_title: "Petição juntada",
    event_date: "2026-07-30T10:00:00-03:00",
    event_date_label: "30/07/2026 10:00",
    phase_name: "Análise jurídica",
    movement_type_name: "Petição",
    movement_template_name: "Modelo inicial",
    nature_label: "Fato processual",
    impact_label: "Sem impacto de fase",
    origin_label: "Manual",
    administrative_situation_label: "Em análise",
    active: true
  },
  legal_case: {
    id: 10,
    internal_number: "PROC-001",
    external_number: "0000001-00.2026.8.10.0001",
    client_name: "Cliente Aurora",
    status_label: "Em análise",
    phase_label: "Análise jurídica",
    responsible_name: "Marina",
    path: "/legal_cases/10",
    client_path: "/clients/5"
  },
  details: [{ label: "Processo", value: "PROC-001" }, { label: "Cliente", value: "Cliente Aurora" }],
  automation: {
    updates_phase: true,
    next_phase_name: "Recurso",
    creates_task: false,
    creates_deadline: true
  },
  description: "Descrição do andamento",
  audits: [{
    id: 100,
    action: "create",
    action_label: "Create",
    created_at: "2026-07-30T10:01:00-03:00",
    created_at_label: "30/07/2026 10:01",
    justification: "-",
    changed_fields_count: 2,
    changed_fields: ["display_title", "event_date"]
  }],
  actions: {
    index: "/process_movements",
    edit: "/process_movements/1/edit",
    delete: "/process_movements/1",
    legal_case: "/legal_cases/10"
  },
  ...overrides
})

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  document.querySelector('meta[name="csrf-token"]')?.remove()
  window.history.replaceState({}, "", "/process_movements/1")
})

test("renders the process movement detail command surface", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<ProcessMovementShowApp />)

  expect(await screen.findByRole("heading", { name: "Petição juntada" })).toBeVisible()
  expect(screen.getByRole("region", { name: "Detalhe do andamento" })).toBeVisible()
  expect(screen.getByRole("link", { name: "Cliente Aurora" })).toHaveAttribute("href", "/clients/5")
  expect(screen.getByRole("link", { name: "PROC-001" })).toHaveAttribute("href", "/legal_cases/10")
  expect(screen.getByRole("heading", { name: "Auditoria" })).toBeVisible()
  expect(screen.getByText("Campos alterados: display_title, event_date")).toBeVisible()
})

test("shows empty description, empty audits and retry state", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(snapshotWith({ description: "", audits: [] })))
  )

  render(<ProcessMovementShowApp />)

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível carregar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByText("Sem descrição complementar cadastrada.")).toBeVisible()
  expect(screen.getByText("Sem registros de auditoria.")).toBeVisible()
})

test("submits deletion with CSRF and confirmation", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))
  const csrf = document.createElement("meta")
  csrf.name = "csrf-token"
  csrf.content = "csrf-process-movement-token"
  document.head.append(csrf)
  const confirmMock = vi.spyOn(window, "confirm").mockReturnValue(false)

  render(<ProcessMovementShowApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Excluir andamento" }))

  expect(confirmMock).toHaveBeenCalledWith("Confirma a exclusão deste andamento?")
  expect(screen.getByRole("button", { name: "Excluir andamento" }).closest("form")).toHaveAttribute("action", "/process_movements/1")
})
