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
