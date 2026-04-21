(() => {
  const openModal = (modal) => {
    if (!modal) return;
    modal.hidden = false;

    if (typeof modal.showModal === "function") {
      if (!modal.open) modal.showModal();
      return;
    }

    modal.setAttribute("open", "open");
  };

  const closeModal = (modal) => {
    if (!modal) return;

    if (typeof modal.close === "function" && modal.open) {
      modal.close();
    }

    modal.removeAttribute("open");
    if (typeof modal.showModal !== "function") modal.hidden = true;
  };

  const initClientProcessesModals = () => {
    document.querySelectorAll("[data-open-client-processes-modal]").forEach((button) => {
      if (button.dataset.clientProcessesModalBound === "true") return;
      button.dataset.clientProcessesModalBound = "true";

      button.addEventListener("click", () => {
        const modalId = button.dataset.openClientProcessesModal;
        if (!modalId) return;
        openModal(document.getElementById(modalId));
      });
    });

    document.querySelectorAll("[data-close-client-processes-modal]").forEach((button) => {
      if (button.dataset.clientProcessesModalCloseBound === "true") return;
      button.dataset.clientProcessesModalCloseBound = "true";

      button.addEventListener("click", () => {
        closeModal(button.closest("dialog"));
      });
    });
  };

  document.addEventListener("turbo:load", initClientProcessesModals);
  document.addEventListener("DOMContentLoaded", initClientProcessesModals);
})();

(() => {
  const initDeadlineExtendToggles = () => {
    document.querySelectorAll("[data-extend-toggle]").forEach((button) => {
      if (button.dataset.extendBound === "true") return;

      button.dataset.extendBound = "true";
      button.addEventListener("click", () => {
        const targetId = button.dataset.extendTarget;
        if (!targetId) return;

        const target = document.getElementById(targetId);
        if (!target) return;

        target.hidden = !target.hidden;
      });
    });
  };

  document.addEventListener("turbo:load", initDeadlineExtendToggles);
  document.addEventListener("DOMContentLoaded", initDeadlineExtendToggles);
})();

(() => {
  const togglePasswordVisibility = (button) => {
    const targetId = button.dataset.passwordTarget;
    if (!targetId) return;

    const input = document.getElementById(targetId);
    if (!(input instanceof HTMLInputElement)) return;

    const icon = button.querySelector("[data-password-icon]");
    const isHidden = input.type === "password";

    input.type = isHidden ? "text" : "password";
    button.setAttribute("aria-label", isHidden ? "Ocultar senha" : "Mostrar senha");
    button.title = isHidden ? "Ocultar senha" : "Mostrar senha";

    if (icon) {
      icon.innerHTML = isHidden ? "&#128584;" : "&#128065;";
    }
  };

  const initPasswordToggles = () => {
    document.querySelectorAll("[data-password-toggle]").forEach((button) => {
      if (button.dataset.passwordToggleBound === "true") return;

      button.dataset.passwordToggleBound = "true";
      button.addEventListener("click", () => togglePasswordVisibility(button));
    });
  };

  document.addEventListener("turbo:load", initPasswordToggles);
  document.addEventListener("DOMContentLoaded", initPasswordToggles);
})();

(() => {
  const applyMask = (digits, pattern) => {
    let result = "";
    let i = 0;

    for (const ch of pattern) {
      if (ch === "#") {
        if (i >= digits.length) break;
        result += digits[i];
        i += 1;
      } else if (i < digits.length) {
        result += ch;
      }
    }

    return result;
  };

  const formatCpfCnpj = (value) => {
    const digits = value.replace(/\D/g, "").slice(0, 14);
    if (digits.length <= 11) {
      return applyMask(digits, "###.###.###-##");
    }
    return applyMask(digits, "##.###.###/####-##");
  };

  const formatPhone = (value) => {
    const digits = value.replace(/\D/g, "").slice(0, 11);
    const pattern = digits.length <= 10 ? "(##) ####-####" : "(##) #####-####";
    return applyMask(digits, pattern);
  };

  const formatRg = (value) => {
    const digits = value.replace(/\D/g, "").slice(0, 9);
    return applyMask(digits, "##.###.###-#");
  };

  const formatCep = (value) => {
    const digits = value.replace(/\D/g, "").slice(0, 8);
    return applyMask(digits, "#####-###");
  };

  const formatCurrencyBr = (value) => {
    let digits = value.replace(/\D/g, "").replace(/^0+/, "");
    if (digits.length === 0) return "";

    if (digits.length === 1) digits = `0${digits}`;
    if (digits.length === 2) digits = `0${digits}`;

    const cents = digits.slice(-2);
    let whole = digits.slice(0, -2);
    if (whole === "") whole = "0";
    whole = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ".");
    return `${whole},${cents}`;
  };

  const formatByMask = (element) => {
    const mask = element.dataset.mask;
    if (!mask) return;

    switch (mask) {
      case "cpf_cnpj":
        element.value = formatCpfCnpj(element.value);
        break;
      case "phone":
        element.value = formatPhone(element.value);
        break;
      case "rg":
        element.value = formatRg(element.value);
        break;
      case "currency-br":
        element.value = formatCurrencyBr(element.value);
        break;
      case "cep":
        element.value = formatCep(element.value);
        break;
      default:
        break;
    }
  };

  const handleInput = (event) => {
    const element = event.target;
    if (!(element instanceof HTMLInputElement || element instanceof HTMLTextAreaElement)) return;
    if (!element.dataset.mask) return;

    const cursor = element.selectionStart;
    const before = element.value.length;
    formatByMask(element);
    const after = element.value.length;

    if (cursor !== null) {
      const next = cursor + (after - before);
      element.setSelectionRange(next, next);
    }
  };

  document.addEventListener("input", handleInput);
  document.addEventListener("turbo:load", () => {
    document.querySelectorAll("[data-mask]").forEach((el) => formatByMask(el));
  });
})();

(() => {
  const fetchAddressByCep = async (cepInput) => {
    const form = cepInput.closest("form");
    if (!form) return;

    const streetInput = form.querySelector("[data-cep-lookup-street]");
    const cityInput = form.querySelector("[data-cep-lookup-city]");
    const stateInput = form.querySelector("[data-cep-lookup-state]");
    if (!streetInput || !cityInput || !stateInput) return;

    const cepDigits = cepInput.value.replace(/\D/g, "");
    if (cepDigits.length !== 8) return;
    if (cepInput.dataset.lastLookupCep === cepDigits) return;

    cepInput.dataset.lastLookupCep = cepDigits;

    try {
      const response = await fetch(`https://viacep.com.br/ws/${cepDigits}/json/`, {
        headers: { Accept: "application/json" }
      });
      if (!response.ok) return;

      const data = await response.json();
      if (data.erro) return;

      streetInput.value = data.logradouro || streetInput.value;
      cityInput.value = data.localidade || cityInput.value;
      stateInput.value = data.uf || stateInput.value;
    } catch (_error) {
      // no-op: user can still fill manually
    }
  };

  const initCepLookup = () => {
    document.querySelectorAll("[data-cep-lookup]").forEach((cepInput) => {
      if (cepInput.dataset.cepBound === "true") return;

      cepInput.dataset.cepBound = "true";
      cepInput.addEventListener("blur", () => fetchAddressByCep(cepInput));
      cepInput.addEventListener("input", () => fetchAddressByCep(cepInput));
    });
  };

  document.addEventListener("turbo:load", initCepLookup);
  document.addEventListener("DOMContentLoaded", initCepLookup);
})();

(() => {
  const buildOption = (value, label, selected) => {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = label;
    if (selected) option.selected = true;
    return option;
  };

  const updateProcessTypes = async (areaSelect) => {
    const processSelect = areaSelect.closest(".form-grid")?.querySelector("[data-process-type-select]");
    if (!processSelect) return;

    const areaId = areaSelect.value;
    const currentValue = processSelect.dataset.currentProcessType || "";

    processSelect.innerHTML = "";
    processSelect.appendChild(buildOption("", "Selecione o tipo", true));

    if (!areaId) {
      processSelect.disabled = true;
      return;
    }

    try {
      const response = await fetch(`/legal_areas/${areaId}/process_types.json`, { headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error("Falha ao carregar tipos");
      const items = await response.json();

      items.forEach((item) => {
        processSelect.appendChild(buildOption(item.id, item.name, String(item.id) === String(currentValue)));
      });
    } catch (_err) {
      processSelect.appendChild(buildOption(currentValue, currentValue, true));
    } finally {
      processSelect.disabled = false;
    }
  };

  const updateCourts = async (districtSelect) => {
    const courtSelect = districtSelect.closest(".form-grid")?.querySelector("[data-court-select]");
    if (!courtSelect) return;

    const districtId = districtSelect.value;
    const currentValue = courtSelect.dataset.currentCourt || "";

    courtSelect.innerHTML = "";
    courtSelect.appendChild(buildOption("", "Selecione o órgão/vara/tribunal", true));

    if (!districtId) {
      courtSelect.disabled = true;
      return;
    }

    try {
      const response = await fetch(`/districts/${districtId}/courts_lookup.json`, { headers: { Accept: "application/json" } });
      if (!response.ok) throw new Error("Falha ao carregar órgãos");
      const items = await response.json();

      items.forEach((item) => {
        courtSelect.appendChild(buildOption(item.id, item.name, String(item.id) === String(currentValue)));
      });
    } catch (_err) {
      courtSelect.appendChild(buildOption(currentValue, currentValue, true));
    } finally {
      courtSelect.disabled = false;
    }
  };

  const initDependentSelects = () => {
    document.querySelectorAll("[data-legal-area-select]").forEach((select) => {
      updateProcessTypes(select);
      select.addEventListener("change", () => {
        const processSelect = select.closest(".form-grid")?.querySelector("[data-process-type-select]");
        if (processSelect) processSelect.dataset.currentProcessType = "";
        updateProcessTypes(select);
      });
    });

    document.querySelectorAll("[data-district-select]").forEach((select) => {
      updateCourts(select);
      select.addEventListener("change", () => {
        const courtSelect = select.closest(".form-grid")?.querySelector("[data-court-select]");
        if (courtSelect) courtSelect.dataset.currentCourt = "";
        updateCourts(select);
      });
    });
  };

  document.addEventListener("turbo:load", initDependentSelects);
  document.addEventListener("DOMContentLoaded", initDependentSelects);
})();


(() => {
  const toggleMovementTypeField = (entryKindSelect) => {
    const form = entryKindSelect.closest("form");
    const movementField = form?.querySelector("[data-movement-type-field]");
    const movementSelect = form?.querySelector("[data-movement-type-select]");
    if (!movementField || !movementSelect) return;

    const isAndamento = entryKindSelect.value === "andamento";
    movementField.hidden = !isAndamento;
    movementSelect.disabled = !isAndamento;

    if (!isAndamento) movementSelect.value = "";
  };

  const initCaseEventEntryKind = () => {
    document.querySelectorAll("[data-entry-kind-select]").forEach((select) => {
      if (select.dataset.toggleBound === "true") {
        toggleMovementTypeField(select);
        return;
      }

      select.dataset.toggleBound = "true";
      toggleMovementTypeField(select);
      select.addEventListener("change", () => toggleMovementTypeField(select));
    });
  };

  document.addEventListener("turbo:load", initCaseEventEntryKind);
  document.addEventListener("DOMContentLoaded", initCaseEventEntryKind);
})();


(() => {
  const toggleProcessExamField = (checkbox) => {
    const form = checkbox.closest("form");
    const examField = form?.querySelector("[data-process-exam-field]");
    const examSelect = form?.querySelector("[data-process-exam-select]");
    if (!examField || !examSelect) return;

    examField.hidden = !checkbox.checked;
    examSelect.disabled = !checkbox.checked;

    if (!checkbox.checked) examSelect.value = "";
  };

  const initProcessExamToggle = () => {
    document.querySelectorAll("[data-process-exam-toggle]").forEach((checkbox) => {
      if (checkbox.dataset.examToggleBound === "true") {
        toggleProcessExamField(checkbox);
        return;
      }

      checkbox.dataset.examToggleBound = "true";
      toggleProcessExamField(checkbox);
      checkbox.addEventListener("change", () => toggleProcessExamField(checkbox));
    });
  };

  document.addEventListener("turbo:load", initProcessExamToggle);
  document.addEventListener("DOMContentLoaded", initProcessExamToggle);
})();


(() => {
  const togglePericiaSection = (checkbox) => {
    const form = checkbox.closest("form");
    const section = form?.querySelector("[data-pericia-section]");
    if (!section) return;

    section.style.display = checkbox.checked ? "block" : "none";

    section.querySelectorAll("input, textarea, select, button").forEach((field) => {
      if (field === checkbox) return;
      field.disabled = !checkbox.checked;
    });
  };

  const initPericiaToggle = () => {
    document.querySelectorAll("[data-pericia-toggle]").forEach((checkbox) => {
      if (checkbox.dataset.periciaBound === "true") {
        togglePericiaSection(checkbox);
        return;
      }

      checkbox.dataset.periciaBound = "true";
      togglePericiaSection(checkbox);
      checkbox.addEventListener("change", () => togglePericiaSection(checkbox));
    });
  };

  document.addEventListener("turbo:load", initPericiaToggle);
  document.addEventListener("DOMContentLoaded", initPericiaToggle);
})();

(() => {
  if (window.__quickClientModalBound) return;
  window.__quickClientModalBound = true;

  const getPendingSet = (select) => {
    const raw = select?.dataset.pendingClientIds || "";
    return new Set(raw.split(",").map((v) => v.trim()).filter(Boolean));
  };

  const savePendingSet = (select, set) => {
    if (!select) return;
    select.dataset.pendingClientIds = Array.from(set).join(",");
  };

  const togglePendingHint = (select, hint, pendingSet) => {
    if (!select || !hint) return;
    hint.hidden = !pendingSet.has(String(select.value));
  };

  const clearQuickClientFields = (modal) => {
    if (!modal) return;

    modal.querySelectorAll("[data-quick-client-field]").forEach((field) => {
      field.value = "";
    });
  };

  const renderQuickClientErrors = (box, errors) => {
    if (!box) return;

    if (!errors || errors.length === 0) {
      box.hidden = true;
      box.innerHTML = "";
      return;
    }

    box.hidden = false;
    box.innerHTML = `<ul>${errors.map((error) => `<li>${error}</li>`).join("")}</ul>`;
  };

  const openModal = (modal) => {
    if (!modal) return;

    modal.hidden = false;

    if (typeof modal.showModal === "function") {
      if (!modal.open) modal.showModal();
      return;
    }

    modal.setAttribute("open", "open");
  };

  const closeModal = (modal) => {
    if (!modal) return;

    if (typeof modal.close === "function" && modal.open) {
      modal.close();
    }

    modal.removeAttribute("open");
    if (typeof modal.showModal !== "function") modal.hidden = true;
  };

  const syncPendingHint = () => {
    const select = document.querySelector("[data-client-select]");
    const pendingHint = document.querySelector("[data-client-pending-hint]");
    const pendingSet = getPendingSet(select);
    togglePendingHint(select, pendingHint, pendingSet);
  };

  const saveQuickClient = async () => {
    const modal = document.querySelector("[data-quick-client-modal]");
    const select = document.querySelector("[data-client-select]");
    const pendingHint = document.querySelector("[data-client-pending-hint]");
    const errorsBox = modal?.querySelector("[data-quick-client-errors]");
    if (!modal || !select) return;

    const endpoint = modal.dataset.endpoint;
    const token = document.querySelector('meta[name="csrf-token"]')?.content;

    const payload = {
      client: {
        full_name: modal.querySelector('[data-quick-client-field="full_name"]')?.value || "",
        cpf_cnpj: modal.querySelector('[data-quick-client-field="cpf_cnpj"]')?.value || "",
        phone: modal.querySelector('[data-quick-client-field="phone"]')?.value || "",
        whatsapp: modal.querySelector('[data-quick-client-field="whatsapp"]')?.value || "",
        email: modal.querySelector('[data-quick-client-field="email"]')?.value || "",
        dados_gov: modal.querySelector('[data-quick-client-field="dados_gov"]')?.value || ""
      }
    };

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": token || ""
        },
        body: JSON.stringify(payload)
      });

      const data = await response.json();

      if (!response.ok) {
        renderQuickClientErrors(errorsBox, data.errors || ["Não foi possível cadastrar cliente."]);
        return;
      }

      const option = new Option(data.display_name, data.id, true, true);
      select.add(option);
      const pendingSet = getPendingSet(select);
      pendingSet.add(String(data.id));
      savePendingSet(select, pendingSet);
      togglePendingHint(select, pendingHint, pendingSet);
      renderQuickClientErrors(errorsBox, []);
      closeModal(modal);
    } catch (_error) {
      renderQuickClientErrors(errorsBox, ["Falha de conexão ao cadastrar cliente."]);
    }
  };

  document.addEventListener("click", (event) => {
    const openButton = event.target.closest("[data-open-quick-client-modal]");
    if (openButton) {
      const modal = document.querySelector("[data-quick-client-modal]");
      const errorsBox = modal?.querySelector("[data-quick-client-errors]");
      renderQuickClientErrors(errorsBox, []);
      clearQuickClientFields(modal);
      openModal(modal);
      return;
    }

    const closeButton = event.target.closest("[data-close-quick-client-modal]");
    if (closeButton) {
      closeModal(document.querySelector("[data-quick-client-modal]"));
      return;
    }

    const saveButton = event.target.closest("[data-save-quick-client]");
    if (saveButton) {
      event.preventDefault();
      saveQuickClient();
    }
  });

  document.addEventListener("change", (event) => {
    if (event.target.matches("[data-client-select]")) {
      syncPendingHint();
    }
  });

  const initQuickClientModal = () => {
    const modal = document.querySelector("[data-quick-client-modal]");
    if (!modal) return;

    if (typeof modal.showModal !== "function") {
      modal.hidden = true;
    }

    syncPendingHint();
  };

  document.addEventListener("turbo:load", initQuickClientModal);
  document.addEventListener("DOMContentLoaded", initQuickClientModal);
})();

(() => {
  const STORAGE_KEY = "matrizjuridica.sidebar.collapsed";

  const applySidebarState = (collapsed) => {
    const layout = document.querySelector("[data-sidebar-layout]");
    const toggle = document.querySelector("[data-sidebar-toggle]");
    const toggleIcon = document.querySelector("[data-sidebar-toggle-icon]");
    const body = document.body;
    if (!layout || !toggle) return;

    layout.classList.toggle("is-sidebar-collapsed", collapsed);
    body?.classList.toggle("is-sidebar-collapsed", collapsed);
    toggle.setAttribute("aria-expanded", String(!collapsed));
    const nextLabel = collapsed ? "Expandir menu lateral" : "Minimizar menu lateral";
    toggle.setAttribute("aria-label", nextLabel);
    toggle.title = nextLabel;

    if (toggleIcon) {
      toggleIcon.textContent = "☰";
    }

    if (collapsed) {
      const sections = Array.from(document.querySelectorAll("[data-sidebar-section]"));
      const openSections = sections.filter((section) => section.classList.contains("is-open"));

      if (openSections.length === 0 && sections.length > 0) {
        const firstSection = sections[0];
        const firstToggle = firstSection.querySelector("[data-sidebar-section-toggle]");
        firstSection.classList.add("is-open");
        if (firstToggle) firstToggle.setAttribute("aria-expanded", "true");
      } else if (openSections.length > 1) {
        const [firstOpen, ...others] = openSections;
        others.forEach((section) => {
          section.classList.remove("is-open");
          const toggleButton = section.querySelector("[data-sidebar-section-toggle]");
          if (toggleButton) toggleButton.setAttribute("aria-expanded", "false");
        });

        const firstToggle = firstOpen.querySelector("[data-sidebar-section-toggle]");
        if (firstToggle) firstToggle.setAttribute("aria-expanded", "true");
      }
    }
  };

  const initSidebarToggle = () => {
    const layout = document.querySelector("[data-sidebar-layout]");
    const toggle = document.querySelector("[data-sidebar-toggle]");
    if (!layout || !toggle) return;

    const savedState = window.localStorage.getItem(STORAGE_KEY) === "true";
    applySidebarState(savedState);

    if (toggle.dataset.sidebarBound === "true") return;
    toggle.dataset.sidebarBound = "true";

    toggle.addEventListener("click", () => {
      const nextState = !layout.classList.contains("is-sidebar-collapsed");
      applySidebarState(nextState);
      window.localStorage.setItem(STORAGE_KEY, String(nextState));
    });
  };

  document.addEventListener("turbo:load", initSidebarToggle);
  document.addEventListener("DOMContentLoaded", initSidebarToggle);
})();

(() => {
  const STORAGE_KEY = "matrizjuridica.sidebar.sections";

  const setSectionState = (section, open) => {
    const toggle = section.querySelector("[data-sidebar-section-toggle]");
    section.classList.toggle("is-open", open);
    if (toggle) toggle.setAttribute("aria-expanded", String(open));
  };

  const loadSavedState = () => {
    try {
      return JSON.parse(window.localStorage.getItem(STORAGE_KEY) || "{}");
    } catch (_error) {
      return {};
    }
  };

  const saveState = (sections) => {
    const state = {};
    sections.forEach((section) => {
      const key = section.dataset.sidebarSection;
      if (!key) return;
      state[key] = section.classList.contains("is-open");
    });
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  };

  const initSidebarSections = () => {
    const container = document.querySelector("[data-sidebar-sections]");
    if (!container) return;

    const sections = Array.from(container.querySelectorAll("[data-sidebar-section]"));
    const saved = loadSavedState();

    sections.forEach((section) => {
      const key = section.dataset.sidebarSection;
      const hasActiveLink = section.querySelector(".nav-link.is-active");
      const open = Object.prototype.hasOwnProperty.call(saved, key) ? !!saved[key] : !!hasActiveLink;
      setSectionState(section, open);
    });

    sections.forEach((section) => {
      const toggle = section.querySelector("[data-sidebar-section-toggle]");
      if (!toggle || toggle.dataset.bound === "true") return;

      toggle.dataset.bound = "true";
      toggle.addEventListener("click", () => {
        const next = !section.classList.contains("is-open");
        setSectionState(section, next);
        saveState(sections);
      });
    });
  };

  document.addEventListener("turbo:load", initSidebarSections);
  document.addEventListener("DOMContentLoaded", initSidebarSections);
})();
