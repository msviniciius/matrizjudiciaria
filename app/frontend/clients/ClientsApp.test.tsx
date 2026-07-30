import "@testing-library/jest-dom/vitest"
import { act, fireEvent, render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { afterEach, vi } from "vitest"
import { ClientsApp } from "./ClientsApp"

type Client = {
  id: number
  path: string
  edit_path: string
  delete_path: string
  full_name: string
  cpf_cnpj: string
  phone: string
  email: string
  city: string
  cadastro_pendente: boolean
  status_label: string
  legal_cases_count: number
  processes_path: string
}

const clientWith = (name: string, overrides: Partial<Client> = {}): Client => ({
  id: 1,
  path: "/clients/1",
  edit_path: "/clients/1/edit",
  delete_path: "/clients/1",
  full_name: name,
  cpf_cnpj: "123.456.789-00",
  phone: "(11) 99999-0000",
  email: "contato@aurora.test",
  city: "São Paulo",
  cadastro_pendente: true,
  status_label: "Cadastro pendente",
  legal_cases_count: 3,
  processes_path: "/clients/1",
  ...overrides
})

const snapshotWith = (clients: Client[] = [clientWith("Cliente Aurora")]) => ({
  meta: { office_name: "Aurora Advocacia", unit_name: "Contencioso", total_count: clients.length },
  filters: { q: "", cadastro_pendente: "", city: "" },
  clients,
  actions: { index: "/clients", new: "/clients/new" }
})

const okResponse = (body: unknown) => ({ ok: true, json: async () => body })

afterEach(() => {
  vi.unstubAllGlobals()
  sessionStorage.clear()
  window.history.replaceState({}, "", "/clients")
})

test("uses the containing Rails main landmark without nesting another main", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  const { container } = render(<main><ClientsApp /></main>)

  await screen.findByRole("link", { name: "Cliente Aurora" })
  expect(container.querySelectorAll("main")).toHaveLength(1)
  expect(container.querySelector(".react-clients")?.tagName).toBe("DIV")
})

test("loads client cards with status, process count and Rails actions", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))

  render(<ClientsApp />)

  const card = await screen.findByRole("article", { name: /Cliente Aurora/ })
  expect(card).toHaveTextContent("Cadastro pendente")
  expect(card).toHaveTextContent("3 processos")
  expect(screen.getByRole("link", { name: "Ver cliente Cliente Aurora" })).toHaveAttribute("href", "/clients/1")
  expect(screen.getByRole("link", { name: "Editar cliente Cliente Aurora" })).toHaveAttribute("href", "/clients/1/edit")
  expect(screen.getByRole("link", { name: "Ver processos de Cliente Aurora" })).toHaveAttribute("href", "/clients/1")
  expect(screen.getByRole("button", { name: "Excluir cliente Cliente Aurora" })).toBeVisible()
})

test("switches to a table and restores that preference", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))
  render(<ClientsApp />)

  await userEvent.setup().click(await screen.findByRole("button", { name: "Tabela" }))

  expect(screen.getByRole("table", { name: "Listagem de clientes" })).toBeVisible()
  expect(sessionStorage.getItem("clients-view")).toBe("table")
})

test("submits an async search and replaces the URL", async () => {
  const searched = snapshotWith([clientWith("Cliente pesquisado")])
  searched.filters.q = "pesquisado"
  const fetchMock = vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockResolvedValueOnce(okResponse(searched))
  vi.stubGlobal("fetch", fetchMock)

  render(<ClientsApp />)
  const user = userEvent.setup()
  await screen.findByRole("link", { name: "Cliente Aurora" })
  await user.type(screen.getByLabelText("Busca"), "pesquisado")

  expect(fetchMock).toHaveBeenCalledTimes(1)
  await user.click(screen.getByRole("button", { name: "Buscar" }))

  expect(await screen.findByRole("link", { name: "Cliente pesquisado" })).toBeVisible()
  expect(new URLSearchParams(window.location.search).get("q")).toBe("pesquisado")
})

test("shows a loading skeleton before the first snapshot arrives", () => {
  vi.stubGlobal("fetch", vi.fn().mockReturnValue(new Promise(() => {})))

  render(<ClientsApp />)

  expect(screen.getByRole("status")).toHaveTextContent("Carregando clientes")
  expect(document.querySelector(".react-clients__skeleton")).toBeInTheDocument()
})

test("keeps results visible and offers retry after a failed filter update", async () => {
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockRejectedValueOnce(new Error("offline"))
    .mockResolvedValueOnce(okResponse(snapshotWith([clientWith("Cliente recuperado")])))
  )

  render(<ClientsApp />)
  const user = userEvent.setup()
  await screen.findByRole("link", { name: "Cliente Aurora" })
  await user.click(screen.getByRole("button", { name: "Filtros avançados" }))
  await user.selectOptions(screen.getByLabelText("Status do cadastro"), "true")

  expect(await screen.findByRole("alert")).toHaveTextContent("Não foi possível atualizar")
  expect(screen.getByRole("link", { name: "Cliente Aurora" })).toBeVisible()
  await user.click(screen.getByRole("button", { name: "Tentar novamente" }))
  expect(await screen.findByRole("link", { name: "Cliente recuperado" })).toBeVisible()
})

test("shows the empty state and keeps filter reset available", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith([]))))

  render(<ClientsApp />)

  expect(await screen.findByText("Nenhum cliente encontrado para estes filtros.")).toBeVisible()
  expect(screen.getByRole("status")).toHaveTextContent("0 cliente(s)")
  expect(screen.getByRole("button", { name: "Limpar filtros" })).toBeVisible()
})

test("uses CSRF confirmation semantics before submitting client deletion", async () => {
  vi.stubGlobal("fetch", vi.fn().mockResolvedValue(okResponse(snapshotWith())))
  const csrf = document.createElement("meta")
  csrf.name = "csrf-token"
  csrf.content = "csrf-clients-token"
  document.head.append(csrf)
  const confirmMock = vi.spyOn(window, "confirm").mockReturnValue(false)

  render(<ClientsApp />)
  await userEvent.setup().click(await screen.findByRole("button", { name: "Excluir cliente Cliente Aurora" }))

  expect(confirmMock).toHaveBeenCalledWith("Excluir este cliente?")
  expect(screen.getByRole("button", { name: "Excluir cliente Cliente Aurora" }).closest("form")).toHaveAttribute("action", "/clients/1")
  csrf.remove()
})

test("ignores an older response after a newer filter result", async () => {
  type Deferred = { promise: Promise<unknown>; resolve: (value: unknown) => void }
  const deferred = (): Deferred => {
    let resolve!: (value: unknown) => void
    const promise = new Promise<unknown>((next) => { resolve = next })
    return { promise, resolve }
  }
  const older = deferred()
  const latest = deferred()
  vi.stubGlobal("fetch", vi.fn()
    .mockResolvedValueOnce(okResponse(snapshotWith()))
    .mockReturnValueOnce(older.promise)
    .mockReturnValueOnce(latest.promise)
  )

  render(<ClientsApp />)
  const user = userEvent.setup()
  await screen.findByRole("link", { name: "Cliente Aurora" })
  await user.click(screen.getByRole("button", { name: "Filtros avançados" }))
  await user.selectOptions(screen.getByLabelText("Status do cadastro"), "true")
  fireEvent.change(screen.getByLabelText("Cidade"), { target: { value: "São Paulo" } })

  await act(async () => { latest.resolve(okResponse(snapshotWith([clientWith("Cliente atual")])) ) })
  expect(await screen.findByRole("link", { name: "Cliente atual" })).toBeVisible()
  await act(async () => { older.resolve(okResponse(snapshotWith([clientWith("Cliente antigo")])) ) })
  expect(screen.queryByRole("link", { name: "Cliente antigo" })).not.toBeInTheDocument()
})
