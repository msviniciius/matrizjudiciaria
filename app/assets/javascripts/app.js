(() => {
  const initOfficeSettingsInteractions = () => {
    const form = document.querySelector("[data-office-settings-form]");
    if (!form) return;

    const navButtons = Array.from(form.querySelectorAll("[data-office-tab]"));
    const panels = Array.from(form.querySelectorAll("[data-office-panel]"));
    const cleanBadge = form.querySelector("[data-office-settings-clean]");
    const dirtyBadge = form.querySelector("[data-office-settings-dirty]");
    const previewName = form.querySelector("[data-office-preview-name]");
    const previewPrimary = form.querySelector("[data-office-preview-primary]");
    const previewSecondary = form.querySelector("[data-office-preview-secondary]");
    const integrationsCount = form.querySelector("[data-office-integrations-count]");
    const integrationChecks = Array.from(form.querySelectorAll("[data-office-integrations-group] input[type='checkbox']"));

    const activateTab = (tabKey) => {
      navButtons.forEach((button) => {
        const active = button.dataset.officeTab === tabKey;
        button.classList.toggle("is-active", active);
        button.setAttribute("aria-selected", String(active));
      });

      panels.forEach((panel) => {
        const active = panel.dataset.officePanel === tabKey;
        panel.classList.toggle("is-active", active);
        panel.hidden = !active;
      });
    };

    navButtons.forEach((button) => {
      if (button.dataset.officeTabBound === "true") return;
      button.dataset.officeTabBound = "true";
      button.addEventListener("click", () => activateTab(button.dataset.officeTab));
    });

    const initialState = new FormData(form);
    const normalize = (formData) => {
      const map = {};
      for (const [ key, value ] of formData.entries()) {
        if (!map[key]) map[key] = [];
        map[key].push(value instanceof File ? value.name : String(value));
      }
      Object.keys(map).forEach((key) => map[key].sort());
      return JSON.stringify(map);
    };
    const initialSerialized = normalize(initialState);

    const updateDirtyState = () => {
      const currentSerialized = normalize(new FormData(form));
      const dirty = currentSerialized !== initialSerialized;
      if (cleanBadge) cleanBadge.hidden = dirty;
      if (dirtyBadge) dirtyBadge.hidden = !dirty;
    };

    const updatePreview = () => {
      const nameField = form.querySelector("[data-office-preview-name='true']");
      const primaryField = form.querySelector("[data-office-preview-primary='true']");
      const secondaryField = form.querySelector("[data-office-preview-secondary='true']");
      if (previewName && nameField) previewName.textContent = nameField.value.trim() || "Nome do escritório";
      if (previewPrimary && primaryField) previewPrimary.style.background = primaryField.value || "#112f4e";
      if (previewSecondary && secondaryField) previewSecondary.style.background = secondaryField.value || "#b08a45";
    };

    const updateIntegrationsCount = () => {
      if (!integrationsCount) return;
      const total = integrationChecks.filter((checkbox) => checkbox.checked).length;
      integrationsCount.textContent = String(total);
    };

    form.addEventListener("input", () => {
      updateDirtyState();
      updatePreview();
      updateIntegrationsCount();
    });
    form.addEventListener("change", () => {
      updateDirtyState();
      updatePreview();
      updateIntegrationsCount();
    });

    updateDirtyState();
    updatePreview();
    updateIntegrationsCount();
  };

  document.addEventListener("turbo:load", initOfficeSettingsInteractions);
  document.addEventListener("DOMContentLoaded", initOfficeSettingsInteractions);
})();

(() => {
  const initMainFiltersToggle = () => {
    document.querySelectorAll("[data-main-filters]").forEach((container) => {
      const toggle = container.querySelector("[data-main-filters-toggle]");
      const advanced = container.querySelector("[data-main-filters-advanced]");
      if (!toggle || !advanced) return;
      if (toggle.dataset.mainFiltersBound === "true") return;
      toggle.dataset.mainFiltersBound = "true";

      const initiallyOpen = container.dataset.filtersOpen === "true";
      advanced.classList.toggle("is-open", initiallyOpen);
      toggle.setAttribute("aria-expanded", String(initiallyOpen));

      const icon = toggle.querySelector("span[aria-hidden='true']");
      if (icon) icon.textContent = initiallyOpen ? "▾" : "▸";

      toggle.addEventListener("click", () => {
        const isOpen = !advanced.classList.contains("is-open");
        advanced.classList.toggle("is-open", isOpen);
        toggle.setAttribute("aria-expanded", String(isOpen));
        if (icon) icon.textContent = isOpen ? "▾" : "▸";
      });
    });
  };

  document.addEventListener("turbo:load", initMainFiltersToggle);
  document.addEventListener("DOMContentLoaded", initMainFiltersToggle);
})();

(() => {
  const initRequiredFieldsPattern = () => {
    document.querySelectorAll("form.app-form").forEach((form) => {
      form.querySelectorAll("[data-required-field]").forEach((field) => {
        field.required = true;
        field.setAttribute("aria-required", "true");
      });
    });
  };

  document.addEventListener("turbo:load", initRequiredFieldsPattern);
  document.addEventListener("DOMContentLoaded", initRequiredFieldsPattern);
})();

(() => {
  const initInlineValidationForms = () => {
    document.querySelectorAll("[data-inline-validation-form]").forEach((form) => {
      if (form.dataset.inlineValidationBound === "true") return;
      form.dataset.inlineValidationBound = "true";

      const requiredFields = Array.from(form.querySelectorAll("[data-required-field]"));
      if (!requiredFields.length) return;

      const validateField = (field) => {
        const value = String(field.value || "").trim();
        const isInvalid = value.length === 0;
        const warning = form.querySelector(`[data-field-error-for='${field.id}']`);

        field.classList.toggle("field-error", isInvalid);
        if (warning) warning.hidden = !isInvalid;
      };

      const validateAll = () => requiredFields.forEach((field) => validateField(field));

      requiredFields.forEach((field) => {
        field.addEventListener("change", () => validateField(field));
        field.addEventListener("blur", () => validateField(field));
      });

      form.addEventListener("submit", validateAll);
    });
  };

  document.addEventListener("turbo:load", initInlineValidationForms);
  document.addEventListener("DOMContentLoaded", initInlineValidationForms);
})();

(() => {
  const initProcessMovementForm = () => {
    document.querySelectorAll("[data-movement-form]").forEach((form) => {
      if (form.dataset.movementFormBound === "true") return;
      form.dataset.movementFormBound = "true";

      const updatesPhase = form.querySelector("[data-movement-updates-phase]");
      const createsTask = form.querySelector("[data-movement-creates-task]");
      const createsDeadline = form.querySelector("[data-movement-creates-deadline]");
      const nextPhase = form.querySelector("[data-movement-next-phase]");
      const movementTemplate = form.querySelector("#process_movement_movement_template_id");
      const eventDate = form.querySelector("[data-movement-event-date]");
      const nextPhaseWarning = form.querySelector("[data-next-phase-warning]");
      const createsDeadlineWarning = form.querySelector("[data-creates-deadline-warning]");
      const previewList = form.querySelector("[data-movement-preview-list]");
      const requiredFields = Array.from(form.querySelectorAll("[data-required-field]"));

      if (!updatesPhase || !nextPhase || !previewList) return;

      const validateField = (field) => {
        const isEmpty = String(field.value || "").trim().length === 0;
        const warning = form.querySelector(`[data-field-error-for='${field.id}']`);

        field.classList.toggle("field-error", isEmpty);
        if (warning) warning.hidden = !isEmpty;
      };

      const validateRequiredFields = () => {
        requiredFields.forEach((field) => validateField(field));
      };

      const updateState = () => {
        const warnings = [];
        const actions = [];

        const willUpdatePhase = updatesPhase.checked;
        const hasNextPhase = String(nextPhase.value || "").trim().length > 0;

        if (willUpdatePhase) {
          if (hasNextPhase) {
            const selected = nextPhase.options[nextPhase.selectedIndex];
            actions.push(`Atualizar fase para: ${selected ? selected.text : "fase selecionada"}.`);
            nextPhase.classList.remove("field-error");
            if (nextPhaseWarning) nextPhaseWarning.hidden = true;
          } else {
            warnings.push("Atualizar fase está marcado, mas falta selecionar a próxima fase.");
            nextPhase.classList.add("field-error");
            if (nextPhaseWarning) nextPhaseWarning.hidden = false;
          }
        } else {
          nextPhase.classList.remove("field-error");
          if (nextPhaseWarning) nextPhaseWarning.hidden = true;
        }

        if (createsTask?.checked) actions.push("Criar tarefa automática.");
        if (createsDeadline?.checked) {
          const hasDateBase = String(eventDate?.value || "").trim().length > 0;
          const hasTemplate = String(movementTemplate?.value || "").trim().length > 0;
          if (hasDateBase || hasTemplate) {
            actions.push("Criar prazo automático.");
            if (createsDeadlineWarning) createsDeadlineWarning.hidden = true;
          } else {
            warnings.push("Criar prazo está marcado, mas falta data base ou modelo de andamento.");
            if (createsDeadlineWarning) createsDeadlineWarning.hidden = false;
          }
        } else if (createsDeadlineWarning) {
          createsDeadlineWarning.hidden = true;
        }

        const lines = [ ...warnings, ...actions ];
        previewList.innerHTML = "";
        if (lines.length === 0) {
          const li = document.createElement("li");
          li.textContent = "Nenhuma automação selecionada.";
          previewList.appendChild(li);
          return;
        }

        lines.forEach((line) => {
          const li = document.createElement("li");
          li.textContent = line;
          previewList.appendChild(li);
        });

        validateRequiredFields();
      };

      [ updatesPhase, createsTask, createsDeadline, nextPhase, eventDate, movementTemplate ].forEach((field) => {
        if (!field) return;
        field.addEventListener("change", updateState);
      });

      requiredFields.forEach((field) => {
        field.addEventListener("change", () => validateField(field));
        field.addEventListener("blur", () => validateField(field));
      });

      form.addEventListener("submit", () => {
        validateRequiredFields();
      });

      updateState();
    });
  };

  document.addEventListener("turbo:load", initProcessMovementForm);
  document.addEventListener("DOMContentLoaded", initProcessMovementForm);
})();

(() => {
  const normalizeValue = (value) => value
    .toString()
    .trim()
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");

  const parseComparable = (value) => {
    const normalized = normalizeValue(value);
    const numberCandidate = normalized.replace(/\./g, "").replace(",", ".");
    if (/^-?\d+(\.\d+)?$/.test(numberCandidate)) return Number(numberCandidate);
    return normalized;
  };

  const initSortableTables = () => {
    document.querySelectorAll(".table-wrap table").forEach((table) => {
      if (table.dataset.sortableBound === "true") return;

      const headRow = table.querySelector("thead tr");
      const body = table.querySelector("tbody");
      if (!headRow || !body) return;

      const headers = Array.from(headRow.querySelectorAll("th"));
      if (!headers.length) return;

      table.dataset.sortableBound = "true";
      table.dataset.sortDirection = "asc";
      table.dataset.sortColumn = "";

      headers.forEach((header, index) => {
        if (header.classList.contains("actions-col")) return;
        if (header.dataset.sortable === "false") return;

        header.classList.add("is-sortable");
        header.setAttribute("role", "button");
        header.setAttribute("tabindex", "0");

        const applySort = () => {
          const rows = Array.from(body.querySelectorAll("tr"));
          if (!rows.length) return;

          const isSameColumn = table.dataset.sortColumn === String(index);
          const direction = isSameColumn && table.dataset.sortDirection === "asc" ? "desc" : "asc";
          const factor = direction === "asc" ? 1 : -1;

          rows.sort((rowA, rowB) => {
            const cellA = rowA.children[index];
            const cellB = rowB.children[index];
            const valueA = parseComparable(cellA ? cellA.textContent : "");
            const valueB = parseComparable(cellB ? cellB.textContent : "");

            if (valueA < valueB) return -1 * factor;
            if (valueA > valueB) return 1 * factor;
            return 0;
          });

          rows.forEach((row) => body.appendChild(row));
          table.dataset.sortColumn = String(index);
          table.dataset.sortDirection = direction;

          headers.forEach((th) => th.removeAttribute("data-sort-direction"));
          header.setAttribute("data-sort-direction", direction);
        };

        header.addEventListener("click", applySort);
        header.addEventListener("keydown", (event) => {
          if (event.key !== "Enter" && event.key !== " ") return;
          event.preventDefault();
          applySort();
        });
      });
    });
  };

  document.addEventListener("turbo:load", initSortableTables);
  document.addEventListener("DOMContentLoaded", initSortableTables);
})();

(() => {
  const PALETTE = [ "#1f4e79", "#4472c4", "#2f7d5b", "#9a6b2f", "#8b3a3a", "#6b5ca5", "#5d6775", "#264653", "#7f8c8d" ];
  const CHART_HIT_MAP = new Map();

  const getOrCreateTooltip = () => {
    let tooltip = document.getElementById("dashboard-chart-tooltip");
    if (tooltip) return tooltip;

    tooltip = document.createElement("div");
    tooltip.id = "dashboard-chart-tooltip";
    tooltip.style.position = "fixed";
    tooltip.style.zIndex = "9999";
    tooltip.style.pointerEvents = "none";
    tooltip.style.padding = "6px 8px";
    tooltip.style.borderRadius = "8px";
    tooltip.style.font = "600 12px Manrope, sans-serif";
    tooltip.style.background = "rgba(17, 33, 53, 0.92)";
    tooltip.style.color = "#fff";
    tooltip.style.boxShadow = "0 8px 24px rgba(0, 0, 0, 0.25)";
    tooltip.style.transform = "translate(-50%, -110%)";
    tooltip.style.whiteSpace = "nowrap";
    tooltip.style.display = "none";
    document.body.appendChild(tooltip);
    return tooltip;
  };

  const bindChartHover = (canvas, hitAreas) => {
    if (!canvas) return;
    CHART_HIT_MAP.set(canvas.id, hitAreas);
    if (canvas.dataset.chartHoverBound === "true") return;
    canvas.dataset.chartHoverBound = "true";

    const tooltip = getOrCreateTooltip();

    const findHit = (x, y) => {
      const areas = CHART_HIT_MAP.get(canvas.id) || [];
      return areas.find((area) => area.contains(x, y));
    };

    canvas.addEventListener("mousemove", (event) => {
      const rect = canvas.getBoundingClientRect();
      const x = event.clientX - rect.left;
      const y = event.clientY - rect.top;
      const hit = findHit(x, y);

      if (!hit) {
        tooltip.style.display = "none";
        canvas.style.cursor = "default";
        return;
      }

      canvas.style.cursor = "pointer";
      tooltip.textContent = hit.text;
      tooltip.style.left = `${event.clientX}px`;
      tooltip.style.top = `${event.clientY}px`;
      tooltip.style.display = "block";
    });

    canvas.addEventListener("mouseleave", () => {
      canvas.style.cursor = "default";
      tooltip.style.display = "none";
    });
  };

  const setupCanvas = (canvas) => {
    if (!canvas) return null;

    const dpr = window.devicePixelRatio || 1;
    const cssWidth = Math.max(100, canvas.clientWidth || 300);
    const cssHeight = Math.max(100, canvas.clientHeight || 250);

    canvas.width = Math.floor(cssWidth * dpr);
    canvas.height = Math.floor(cssHeight * dpr);

    const ctx = canvas.getContext("2d");
    if (!ctx) return null;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, cssWidth, cssHeight);
    return { ctx, width: cssWidth, height: cssHeight };
  };

  const drawVerticalBars = (canvasId, labels, values, colors = []) => {
    const canvas = document.getElementById(canvasId);
    const chart = setupCanvas(canvas);
    if (!chart) return;
    const { ctx, width, height } = chart;
    if (!values.length) return;
    const hitAreas = [];

    const maxValue = Math.max(...values, 1);
    const left = 32;
    const right = width - 10;
    const top = 10;
    const bottom = height - 36;
    const chartWidth = right - left;
    const chartHeight = bottom - top;
    const gap = 10;
    const barWidth = Math.max(14, (chartWidth - gap * (values.length - 1)) / values.length);

    ctx.strokeStyle = "#d8cfbe";
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(left, bottom);
    ctx.lineTo(right, bottom);
    ctx.stroke();

    values.forEach((value, index) => {
      const x = left + index * (barWidth + gap);
      const h = (value / maxValue) * chartHeight;
      const y = bottom - h;
      const fullLabel = String(labels[index] || "Item");

      ctx.fillStyle = colors[index] || colors[0] || "#2f5f8f";
      ctx.fillRect(x, y, barWidth, h);

      ctx.fillStyle = "#23364e";
      ctx.font = "12px Manrope, sans-serif";
      ctx.textAlign = "center";
      ctx.fillText(String(value), x + barWidth / 2, y - 4);

      const shortLabel = fullLabel.length > 14 ? `${fullLabel.slice(0, 12)}...` : fullLabel;
      ctx.fillStyle = "#5f6674";
      ctx.font = "11px Manrope, sans-serif";
      ctx.fillText(shortLabel, x + barWidth / 2, bottom + 14);

      hitAreas.push({
        text: `${fullLabel}: ${value}`,
        contains: (mx, my) => mx >= x && mx <= x + barWidth && my >= y && my <= bottom
      });
    });

    bindChartHover(canvas, hitAreas);
  };

  const drawHorizontalBars = (canvasId, labels, values, color = "#0f3b61") => {
    const canvas = document.getElementById(canvasId);
    const chart = setupCanvas(canvas);
    if (!chart) return;
    const { ctx, width, height } = chart;
    if (!values.length) return;
    const hitAreas = [];

    const maxValue = Math.max(...values, 1);
    const left = 110;
    const right = width - 16;
    const top = 8;
    const bottom = height - 8;
    const chartWidth = right - left;
    const rowHeight = (bottom - top) / values.length;

    values.forEach((value, index) => {
      const y = top + index * rowHeight;
      const barY = y + 6;
      const barH = Math.max(14, rowHeight - 12);
      const barW = (value / maxValue) * chartWidth;
      const label = String(labels[index] || "");

      ctx.fillStyle = color;
      ctx.fillRect(left, barY, barW, barH);

      ctx.fillStyle = "#23364e";
      ctx.font = "11px Manrope, sans-serif";
      ctx.textAlign = "right";
      ctx.fillText(label.length > 22 ? `${label.slice(0, 20)}...` : label, left - 8, barY + barH - 2);

      ctx.textAlign = "left";
      ctx.fillText(String(value), left + barW + 6, barY + barH - 2);

      hitAreas.push({
        text: `${label}: ${value}`,
        contains: (mx, my) => mx >= left && mx <= left + barW && my >= barY && my <= barY + barH
      });
    });

    bindChartHover(canvas, hitAreas);
  };

  const drawDonut = (canvasId, labels, values) => {
    const canvas = document.getElementById(canvasId);
    const chart = setupCanvas(canvas);
    if (!chart) return;
    const { ctx, width, height } = chart;
    if (!values.length) return;
    const hitAreas = [];

    const total = values.reduce((sum, value) => sum + value, 0);
    if (total <= 0) return;

    const cx = Math.min(width * 0.35, width - 120);
    const cy = height * 0.5;
    const radius = Math.min(72, Math.min(width, height) * 0.28);
    const lineWidth = 30;
    let angle = -Math.PI / 2;

    values.forEach((value, index) => {
      const slice = (value / total) * Math.PI * 2;
      const startAngle = angle;
      const endAngle = angle + slice;
      ctx.beginPath();
      ctx.strokeStyle = PALETTE[index % PALETTE.length];
      ctx.lineWidth = lineWidth;
      ctx.arc(cx, cy, radius, startAngle, endAngle);
      ctx.stroke();
      angle = endAngle;

      const label = String(labels[index] || "Item");
      const innerRadius = radius - lineWidth / 2;
      const outerRadius = radius + lineWidth / 2;
      hitAreas.push({
        text: `${label}: ${value}`,
        contains: (mx, my) => {
          const dx = mx - cx;
          const dy = my - cy;
          const dist = Math.sqrt((dx ** 2) + (dy ** 2));
          if (dist < innerRadius || dist > outerRadius) return false;
          let pointAngle = Math.atan2(dy, dx);
          if (pointAngle < -Math.PI / 2) pointAngle += Math.PI * 2;
          let normalizedStart = startAngle;
          let normalizedEnd = endAngle;
          if (normalizedStart < -Math.PI / 2) normalizedStart += Math.PI * 2;
          if (normalizedEnd < -Math.PI / 2) normalizedEnd += Math.PI * 2;
          if (normalizedEnd < normalizedStart) normalizedEnd += Math.PI * 2;
          if (pointAngle < normalizedStart) pointAngle += Math.PI * 2;
          return pointAngle >= normalizedStart && pointAngle <= normalizedEnd;
        }
      });
    });

    ctx.fillStyle = "#23364e";
    ctx.font = "700 14px Manrope, sans-serif";
    ctx.textAlign = "center";
    ctx.fillText(String(total), cx, cy + 4);

    let legendY = 18;
    labels.forEach((label, index) => {
      const x = Math.max(cx + radius + 28, width * 0.55);
      ctx.fillStyle = PALETTE[index % PALETTE.length];
      ctx.fillRect(x, legendY - 8, 10, 10);
      ctx.fillStyle = "#23364e";
      ctx.font = "11px Manrope, sans-serif";
      const itemLabel = `${label} (${values[index] || 0})`;
      ctx.fillText(itemLabel.length > 28 ? `${itemLabel.slice(0, 26)}...` : itemLabel, x + 16, legendY);
      legendY += 16;
    });

    bindChartHover(canvas, hitAreas);
  };

  const initDashboardCharts = () => {
    const root = document.getElementById("dashboard-charts-root");
    const dataNode = document.getElementById("dashboard-charts-data");
    if (!root || !dataNode) return;

    let data;
    try {
      data = JSON.parse(dataNode.textContent || "{}");
    } catch (_error) {
      return;
    }

    drawVerticalBars("dashboard-chart-phase", data.phase?.labels || [], data.phase?.values || [], [ "#2f5f8f" ]);
    drawDonut("dashboard-chart-status", data.status?.labels || [], data.status?.values || []);
    drawVerticalBars("dashboard-chart-deadlines", data.deadlines?.labels || [], data.deadlines?.values || [], [ "#8b3a3a", "#b08a45", "#2f5f8f", "#4e7f59" ]);
    drawHorizontalBars("dashboard-chart-responsible", data.responsible?.labels || [], data.responsible?.values || [], "#0f3b61");
  };

  document.addEventListener("turbo:load", initDashboardCharts);
  document.addEventListener("DOMContentLoaded", initDashboardCharts);
  window.addEventListener("resize", initDashboardCharts);
})();

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
  let pendingConfirmAction = null;

  const getConfirmElements = () => {
    const modal = document.getElementById("app-confirm-modal");
    if (!modal) return null;

    return {
      modal,
      message: document.getElementById("app-confirm-modal-message"),
      accept: modal.querySelector("[data-confirm-accept]"),
      cancel: modal.querySelector("[data-confirm-cancel]")
    };
  };

  const closeConfirmModal = (elements) => {
    if (!elements?.modal) return;

    if (typeof elements.modal.close === "function" && elements.modal.open) {
      elements.modal.close();
    }

    elements.modal.removeAttribute("open");
    if (typeof elements.modal.showModal !== "function") elements.modal.hidden = true;
  };

  const openConfirmModal = (message, onAccept) => {
    const elements = getConfirmElements();
    if (!elements) return;

    pendingConfirmAction = onAccept;
    if (elements.message) elements.message.textContent = message || "Tem certeza que deseja continuar?";

    elements.modal.hidden = false;
    if (typeof elements.modal.showModal === "function") {
      if (!elements.modal.open) elements.modal.showModal();
    } else {
      elements.modal.setAttribute("open", "open");
    }
  };

  const initConfirmModal = () => {
    const elements = getConfirmElements();
    if (!elements || elements.modal.dataset.confirmBound === "true") return;
    elements.modal.dataset.confirmBound = "true";

    const confirmAndClose = () => {
      const action = pendingConfirmAction;
      pendingConfirmAction = null;
      closeConfirmModal(elements);
      if (typeof action === "function") action();
    };

    const cancelAndClose = () => {
      pendingConfirmAction = null;
      closeConfirmModal(elements);
    };

    elements.accept?.addEventListener("click", confirmAndClose);
    elements.cancel?.addEventListener("click", cancelAndClose);
    elements.modal.addEventListener("cancel", (event) => {
      event.preventDefault();
      cancelAndClose();
    });

    document.addEventListener("submit", (event) => {
      const form = event.target;
      if (!(form instanceof HTMLFormElement)) return;
      if (form.dataset.confirmBypassed === "true") return;

      const message = form.dataset.turboConfirm || event.submitter?.dataset?.turboConfirm;
      if (!message) return;

      event.preventDefault();
      openConfirmModal(message, () => {
        form.dataset.confirmBypassed = "true";
        if (event.submitter) {
          form.requestSubmit(event.submitter);
        } else {
          form.requestSubmit();
        }
        window.setTimeout(() => { delete form.dataset.confirmBypassed; }, 0);
      });
    }, true);

    document.addEventListener("click", (event) => {
      const link = event.target.closest("a[data-turbo-confirm]");
      if (!link) return;
      if (link.dataset.confirmBypassed === "true") return;

      const message = link.dataset.turboConfirm;
      if (!message) return;

      event.preventDefault();
      openConfirmModal(message, () => {
        link.dataset.confirmBypassed = "true";
        const original = link.getAttribute("data-turbo-confirm");
        link.removeAttribute("data-turbo-confirm");
        link.click();
        window.setTimeout(() => {
          if (original) link.setAttribute("data-turbo-confirm", original);
          delete link.dataset.confirmBypassed;
        }, 0);
      });
    }, true);
  };

  document.addEventListener("turbo:load", initConfirmModal);
  document.addEventListener("DOMContentLoaded", initConfirmModal);
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

  const formatCpf = (value) => {
    const digits = value.replace(/\D/g, "").slice(0, 11);
    return applyMask(digits, "###.###.###-##");
  };

  const formatCnpj = (value) => {
    const digits = value.replace(/\D/g, "").slice(0, 14);
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

  const formatUf = (value) => value.replace(/[^a-zA-Z]/g, "").toUpperCase().slice(0, 2);

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
      case "cpf":
        element.value = formatCpf(element.value);
        break;
      case "cnpj":
        element.value = formatCnpj(element.value);
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
      case "uf":
        element.value = formatUf(element.value);
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
  const openDialog = (dialog) => {
    if (!dialog) return;

    dialog.hidden = false;
    if (typeof dialog.showModal === "function") {
      if (!dialog.open) dialog.showModal();
      return;
    }

    dialog.setAttribute("open", "open");
  };

  const closeDialog = (dialog) => {
    if (!dialog) return;

    if (typeof dialog.close === "function" && dialog.open) dialog.close();
    dialog.removeAttribute("open");
    if (typeof dialog.showModal !== "function") dialog.hidden = true;
  };

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
      checkbox.dataset.periciaPrevChecked = checkbox.checked ? "true" : "false";
      togglePericiaSection(checkbox);
      checkbox.addEventListener("change", () => {
        togglePericiaSection(checkbox);

        const form = checkbox.closest("form");
        const modal = form?.querySelector("[data-pericia-modal]");
        const wasChecked = checkbox.dataset.periciaPrevChecked === "true";
        const isChecked = checkbox.checked;
        checkbox.dataset.periciaPrevChecked = isChecked ? "true" : "false";

        if (!wasChecked && isChecked && checkbox.dataset.periciaOpenModalOnCheck === "true") {
          openDialog(modal);
        }
      });
    });

    document.querySelectorAll("[data-pericia-modal]").forEach((modal) => {
      if (modal.dataset.periciaModalBound === "true") return;

      modal.dataset.periciaModalBound = "true";

      if (typeof modal.showModal !== "function") modal.hidden = true;

      modal.addEventListener("click", (event) => {
        if (event.target.closest("[data-close-pericia-modal]")) {
          closeDialog(modal);
          return;
        }

        if (event.target.closest("[data-save-pericia-modal]")) {
          const form = modal.closest("form");
          closeDialog(modal);
          if (form) form.requestSubmit();
          return;
        }

        if (event.target === modal) {
          closeDialog(modal);
        }
      });
    });
  };

  document.addEventListener("click", (event) => {
    const editButton = event.target.closest("[data-edit-pericia-modal]");
    if (editButton) {
      const form = editButton.closest("form");
      const modal = form?.querySelector("[data-pericia-modal]");
      if (!form || !modal) return;

      const setValue = (selector, value) => {
        const field = form.querySelector(selector);
        if (!field) return;
        field.value = value ?? "";
      };

      setValue("[name='legal_case[process_exams_attributes][0][id]']", editButton.dataset.examId || "");
      setValue("[name='legal_case[process_exams_attributes][0][exam_nature]']", editButton.dataset.examNature || "");
      setValue("[name='legal_case[process_exams_attributes][0][exam_scope]']", editButton.dataset.examScope || "");
      setValue("[name='legal_case[process_exams_attributes][0][status]']", editButton.dataset.examStatus || "");
      setValue("[name='legal_case[process_exams_attributes][0][scheduled_at]']", editButton.dataset.examScheduledAt || "");
      setValue("[name='legal_case[process_exams_attributes][0][location]']", editButton.dataset.examLocation || "");
      setValue("[name='legal_case[process_exams_attributes][0][expert_name]']", editButton.dataset.examExpertName || "");
      setValue("[name='legal_case[process_exams_attributes][0][notes]']", editButton.dataset.examNotes || "");

      const activeField = form.querySelector("[name='legal_case[process_exams_attributes][0][active]']");
      if (activeField) activeField.checked = editButton.dataset.examActive === "true";

      openDialog(modal);
      return;
    }

    const openButton = event.target.closest("[data-open-pericia-modal]");
    if (!openButton) return;

    const form = openButton.closest("form");
    const modal = form?.querySelector("[data-pericia-modal]");
    if (form) {
      const clearValue = (selector) => {
        const field = form.querySelector(selector);
        if (!field) return;
        field.value = "";
      };

      clearValue("[name='legal_case[process_exams_attributes][0][id]']");
      clearValue("[name='legal_case[process_exams_attributes][0][exam_nature]']");
      clearValue("[name='legal_case[process_exams_attributes][0][exam_scope]']");
      clearValue("[name='legal_case[process_exams_attributes][0][status]']");
      clearValue("[name='legal_case[process_exams_attributes][0][scheduled_at]']");
      clearValue("[name='legal_case[process_exams_attributes][0][location]']");
      clearValue("[name='legal_case[process_exams_attributes][0][expert_name]']");
      clearValue("[name='legal_case[process_exams_attributes][0][notes]']");
      const activeField = form.querySelector("[name='legal_case[process_exams_attributes][0][active]']");
      if (activeField) activeField.checked = true;
    }
    openDialog(modal);
  });

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

    const requiredFields = Array.from(modal.querySelectorAll("[data-quick-client-field][required]"));
    const firstInvalid = requiredFields.find((field) => !field.checkValidity());
    if (firstInvalid) {
      firstInvalid.reportValidity();
      firstInvalid.focus();
      return;
    }

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
  const MOBILE_BREAKPOINT = "(max-width: 980px)";
  let sidebarCollapsedMemory = false;

  const safeGetCollapsedState = () => {
    try {
      return window.localStorage.getItem(STORAGE_KEY) === "true";
    } catch (_error) {
      return sidebarCollapsedMemory;
    }
  };

  const safeSetCollapsedState = (value) => {
    sidebarCollapsedMemory = !!value;
    try {
      window.localStorage.setItem(STORAGE_KEY, String(!!value));
    } catch (_error) {
      // no-op
    }
  };

  const isMobileViewport = () => window.matchMedia(MOBILE_BREAKPOINT).matches;

  const updateToggleState = ({ toggle, collapsed, mobileOpen }) => {
    const mobile = isMobileViewport();
    if (mobile) {
      toggle.setAttribute("aria-expanded", String(!!mobileOpen));
      const nextLabel = mobileOpen ? "Fechar menu lateral" : "Abrir menu lateral";
      toggle.setAttribute("aria-label", nextLabel);
      toggle.title = nextLabel;
      return;
    }

    toggle.setAttribute("aria-expanded", String(!collapsed));
    const nextLabel = collapsed ? "Expandir menu lateral" : "Minimizar menu lateral";
    toggle.setAttribute("aria-label", nextLabel);
    toggle.title = nextLabel;
  };

  const applySidebarState = (collapsed) => {
    const layout = document.querySelector("[data-sidebar-layout]");
    const toggle = document.querySelector("[data-sidebar-toggle]");
    const toggleIcon = document.querySelector("[data-sidebar-toggle-icon]");
    const body = document.body;
    if (!layout || !toggle) return;

    const mobile = isMobileViewport();
    const effectiveCollapsed = mobile ? false : collapsed;
    layout.classList.toggle("is-sidebar-collapsed", effectiveCollapsed);
    if (!mobile) {
      layout.classList.remove("is-sidebar-mobile-open");
      body?.classList.remove("is-sidebar-mobile-open");
    }
    body?.classList.toggle("is-sidebar-collapsed", effectiveCollapsed);
    updateToggleState({ toggle, collapsed: effectiveCollapsed, mobileOpen: layout.classList.contains("is-sidebar-mobile-open") });

    if (toggleIcon) {
      toggleIcon.textContent = "☰";
    }

    if (effectiveCollapsed && !mobile) {
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

  const setMobileSidebarOpen = (open) => {
    const layout = document.querySelector("[data-sidebar-layout]");
    const toggle = document.querySelector("[data-sidebar-toggle]");
    const body = document.body;
    if (!layout || !toggle) return;

    layout.classList.toggle("is-sidebar-mobile-open", open);
    body?.classList.toggle("is-sidebar-mobile-open", open);
    updateToggleState({
      toggle,
      collapsed: layout.classList.contains("is-sidebar-collapsed"),
      mobileOpen: open
    });
  };

  const initSidebarToggle = () => {
    const layout = document.querySelector("[data-sidebar-layout]");
    const toggle = document.querySelector("[data-sidebar-toggle]");
    const overlay = document.querySelector("[data-sidebar-overlay]");
    if (!layout || !toggle) return;

    const savedState = safeGetCollapsedState();
    applySidebarState(savedState);
    if (isMobileViewport()) setMobileSidebarOpen(false);

    if (overlay && overlay.dataset.sidebarOverlayBound !== "true") {
      overlay.dataset.sidebarOverlayBound = "true";
      overlay.addEventListener("click", () => setMobileSidebarOpen(false));
    }

    if (toggle.dataset.sidebarBound === "true") return;
    toggle.dataset.sidebarBound = "true";

    toggle.addEventListener("click", () => {
      if (isMobileViewport()) {
        const nextMobileOpen = !layout.classList.contains("is-sidebar-mobile-open");
        setMobileSidebarOpen(nextMobileOpen);
        return;
      }

      const nextState = !layout.classList.contains("is-sidebar-collapsed");
      applySidebarState(nextState);
      safeSetCollapsedState(nextState);
    });

    window.addEventListener("resize", () => {
      if (!isMobileViewport()) {
        setMobileSidebarOpen(false);
      } else {
        updateToggleState({
          toggle,
          collapsed: layout.classList.contains("is-sidebar-collapsed"),
          mobileOpen: layout.classList.contains("is-sidebar-mobile-open")
        });
      }
    });

    document.addEventListener("click", (event) => {
      if (!isMobileViewport()) return;
      if (!layout.classList.contains("is-sidebar-mobile-open")) return;
      if (event.target.closest(".app-sidebar")) return;
      if (event.target.closest("[data-sidebar-toggle]")) return;
      setMobileSidebarOpen(false);
    });
  };

  document.addEventListener("turbo:load", initSidebarToggle);
  document.addEventListener("DOMContentLoaded", initSidebarToggle);
})();

(() => {
  const STORAGE_KEY = "matrizjuridica.sidebar.sections";
  let sidebarSectionsMemory = {};

  const setSectionState = (section, open) => {
    const toggle = section.querySelector("[data-sidebar-section-toggle]");
    section.classList.toggle("is-open", open);
    if (toggle) toggle.setAttribute("aria-expanded", String(open));
  };

  const loadSavedState = () => {
    try {
      return JSON.parse(window.localStorage.getItem(STORAGE_KEY) || "{}");
    } catch (_error) {
      return sidebarSectionsMemory;
    }
  };

  const saveState = (sections) => {
    const state = {};
    sections.forEach((section) => {
      const key = section.dataset.sidebarSection;
      if (!key) return;
      state[key] = section.classList.contains("is-open");
    });
    sidebarSectionsMemory = state;
    try {
      window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
    } catch (_error) {
      // no-op
    }
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

(() => {
  if (window.__mobileInstallBannerBound) return;
  window.__mobileInstallBannerBound = true;

  const STORAGE_KEY = "matrizjuridica.mobile_install_banner.dismissed";
  let deferredPrompt = null;

  const isStandalone = () => window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;
  const isMobileViewport = () => window.matchMedia("(max-width: 980px)").matches;
  const isIosDevice = () => /iphone|ipad|ipod/i.test(window.navigator.userAgent || "");

  const isDismissed = () => {
    try {
      return window.localStorage.getItem(STORAGE_KEY) === "true";
    } catch (_error) {
      return false;
    }
  };

  const setDismissed = (value) => {
    try {
      window.localStorage.setItem(STORAGE_KEY, String(!!value));
    } catch (_error) {
      // no-op
    }
  };

  const registerServiceWorker = () => {
    if (!("serviceWorker" in window.navigator)) return;
    window.navigator.serviceWorker.register("/service-worker").catch(() => {
      // no-op: app funciona sem service worker
    });
  };

  const setupBanner = () => {
    const banner = document.querySelector("[data-mobile-install-banner]");
    if (!banner) return;

    const installButton = banner.querySelector("[data-mobile-install-action='install']");
    const iosButton = banner.querySelector("[data-mobile-install-action='ios-help']");
    const iosHelp = banner.querySelector("[data-mobile-install-ios-help]");
    const dismissButton = banner.querySelector("[data-mobile-install-dismiss]");

    const showBanner = () => {
      if (isStandalone() || isDismissed() || !isMobileViewport()) {
        banner.hidden = true;
        return;
      }
      banner.hidden = false;
    };

    if (isIosDevice()) {
      iosButton?.removeAttribute("hidden");
      installButton?.setAttribute("hidden", "hidden");
    } else if (deferredPrompt) {
      installButton?.removeAttribute("hidden");
      iosButton?.setAttribute("hidden", "hidden");
    } else {
      installButton?.setAttribute("hidden", "hidden");
      iosButton?.setAttribute("hidden", "hidden");
    }

    if (iosButton && iosButton.dataset.installBound !== "true") {
      iosButton.dataset.installBound = "true";
      iosButton.addEventListener("click", () => {
        if (!iosHelp) return;
        iosHelp.hidden = !iosHelp.hidden;
      });
    }

    if (installButton && installButton.dataset.installBound !== "true") {
      installButton.dataset.installBound = "true";
      installButton.addEventListener("click", async () => {
        if (!deferredPrompt) return;
        deferredPrompt.prompt();
        try {
          const choice = await deferredPrompt.userChoice;
          if (choice.outcome === "accepted") {
            banner.hidden = true;
          }
        } catch (_error) {
          // no-op
        } finally {
          deferredPrompt = null;
          installButton.setAttribute("hidden", "hidden");
        }
      });
    }

    if (dismissButton && dismissButton.dataset.installBound !== "true") {
      dismissButton.dataset.installBound = "true";
      dismissButton.addEventListener("click", () => {
        setDismissed(true);
        banner.hidden = true;
      });
    }

    showBanner();
    window.addEventListener("resize", showBanner);
  };

  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredPrompt = event;
    setupBanner();
  });

  window.addEventListener("appinstalled", () => {
    setDismissed(true);
    const banner = document.querySelector("[data-mobile-install-banner]");
    if (banner) banner.hidden = true;
  });

  document.addEventListener("turbo:load", () => {
    registerServiceWorker();
    setupBanner();
  });

  document.addEventListener("DOMContentLoaded", () => {
    registerServiceWorker();
    setupBanner();
  });
})();
