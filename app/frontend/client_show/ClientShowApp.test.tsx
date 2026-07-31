import "@testing-library/jest-dom/vitest"
import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { ClientShowApp } from "./ClientShowApp"

const snapshotWith = (overrides = {}) => ({
  client: {
    id: 1,
    full_name: "Cliente Aurora",
    cpf_cnpj: "123.456.789-00",
    phone: "(98) 99999-1111",
    email: "cliente@aurora.test",
    cadastro_pendente: true,
    status_label: "Cadastro pendente",
    legal_cases_count: 1,
    unit_name: "Contencioso"
  },
  identification: [{ label: "Nome completo", value: "Cliente Aurora" }],
  contact: [{ label: "Telefone", value: "(98) 99999-1111" }],
  address: [{ label: "Cidade", value: "São Luís" }],
  family: [{ label: "Nome da mãe", value: "Não informado" }],
  notes: "Observação estratégica",
  gov: { present: true, masked: "Email: gov@test\nSenha: ********", raw: "Email: gov@test\nSenha: segredo" },
  legal_cases: [{
    id: 10,
    internal_number: "PROC-001",
    phase_label: "Análise jurídica",
    status_label: "Em análise",
    priority_label: "Alta",
    next_deadline_label: "31/07/2026",
    responsible_name: "Marina",
    path: "/legal_cases/10"
  }],
  actions: {
    index: "/clients",
    edit: "/clients/1/edit",
    delete: "/clients/1",
    new_legal_case: "/legal_cases/new?client_id=1"
  },
  ...overrides
})

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  document.querySelector('meta[name="csrf-token"]')?.remove()
  window.history.replaceState({}, "", "/clients/1")
})

test("renders a client dossier without nesting a main landmark", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  const { container } = render(<main><ClientShowApp /></main>)

  expect(await screen.findByRole("heading", { name: "Cliente Aurora" })).toBeVisible()
  expect(screen.getByRole("region", { name: "Dossiê do cliente" })).toBeVisible()
  expect(container.querySelectorAll("main")).toHaveLength(1)
  expect(screen.getByText("Cadastro pendente")).toBeVisible()
  expect(screen.getByRole("link", { name: "PROC-001" })).toHaveAttribute("href", "/legal_cases/10")
})

test("shows empty states and retry when needed", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(snapshotWith({
      client: { ...snapshotWith().client, legal_cases_count: 0 },
      legal_cases: [],
      notes: "",
      gov: { present: false, masked: "", raw: "" }
    })))
  )

  render(<ClientShowApp />)

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível carregar")
  await userEvent.setup().click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByText("Este cliente ainda não possui processos cadastrados.")).toBeVisible()
  expect(screen.getByText("Sem observações cadastradas.")).toBeVisible()
})

test("submits deletion with CSRF and linked-process confirmation", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))
  const csrf = document.createElement("meta")
  csrf.name = "csrf-token"
  csrf.content = "csrf-client-show-token"
  document.head.append(csrf)
  const confirmMock = vi.spyOn(window, "confirm").mockReturnValue(false)

  render(<ClientShowApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Excluir cliente" }))

  expect(confirmMock).toHaveBeenCalledWith("Este cliente possui 1 processo vinculado. Deseja continuar com a exclusão?")
  expect(screen.getByRole("button", { name: "Excluir cliente" }).closest("form")).toHaveAttribute("action", "/clients/1")
})
